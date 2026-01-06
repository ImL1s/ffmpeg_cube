// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:typed_data';
import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import '../models/jobs/base_job.dart';
import '../models/jobs/transcode_job.dart';
import '../models/jobs/trim_job.dart';
import '../models/jobs/thumbnail_job.dart';
import '../models/jobs/subtitle_job.dart';

FFmpeg? _ffmpeg;

/// Get or create FFmpeg instance
Future<FFmpeg> _getFFmpeg() async {
  if (_ffmpeg != null) {
    // Instance exists, just return it (load is idempotent in most wasm libs)
    return _ffmpeg!;
  }

  // Create FFmpeg instance with logging enabled
  // Note: corePath is optional, if not provided it loads from CDN
  _ffmpeg = createFFmpeg(CreateFFmpegParam(
    log: true,
  ));

  // Load the core
  await _ffmpeg!.load();
  return _ffmpeg!;
}

/// Check if ffmpeg.wasm is available
Future<bool> isWasmAvailable() async {
  // ffmpeg_wasm package usually handles checks, but for COOP/COEP
  // we might want to verify shared memory support if possible.
  // For now, assume true if we can import the package.
  try {
    // Try to create instance (lightweight)
    createFFmpeg(CreateFFmpegParam(log: false));
    return true;
  } catch (e) {
    return false;
  }
}

/// Execute ffmpeg command
Future<void> executeWasm(
  BaseJob job, {
  void Function(double)? onProgress,
  bool Function()? isCancelled,
}) async {
  final ffmpeg = await _getFFmpeg();

  // Set progress handler
  if (onProgress != null) {
    ffmpeg.setProgress((p) {
      // ffmpeg_wasm progress is typically 0.0 to 1.0 (sometimes ratio)
      // Check documentation: usually { ratio: 0.1, time: 10 }
      // The wrapper might simplify this.
      // Based on common bindings, it might be a double ratio.
      onProgress(p.ratio);
    });
  }

  // Handle Input Data writing
  await _writeInputData(ffmpeg, job);

  // Execute
  final args = job.toFFmpegArgs();
  try {
    await ffmpeg.run(args);
  } catch (e) {
    throw Exception('FFmpeg execution failed: $e');
  }

  // Cleanup: In a real app we might want to clean up inputs
  // But output files should remain for reading.
}

Future<void> _writeInputData(FFmpeg ffmpeg, BaseJob job) async {
  Uint8List? data;
  String? path;

  if (job is TranscodeJob) {
    data = job.inputData;
    path = job.inputPath;
  } else if (job is TrimJob) {
    data = job.inputData;
    path = job.inputPath;
  } else if (job is ThumbnailJob) {
    data = job.inputData;
    path = job.videoPath;
  } else if (job is SubtitleJob) {
    data = job.inputData;
    path = job.videoPath;
    // Write subtitle file data to virtual filesystem if provided
    if (job.subtitleData != null && job.subtitlePath.isNotEmpty) {
      ffmpeg.writeFile(job.subtitlePath, job.subtitleData!);
    }
  }

  if (data != null && path != null && path.isNotEmpty) {
    ffmpeg.writeFile(path, data);
  }
}

/// Probe a media file using ffmpeg -i and parsing the output
///
/// Since ffmpeg.wasm doesn't expose ffprobe directly, we use ffmpeg -i
/// and parse the stderr output to extract media information.
Future<Map<String, dynamic>> probeWasm(String filePath) async {
  final ffmpeg = await _getFFmpeg();

  // Collect log messages
  final logs = <String>[];
  ffmpeg.setLogger((LoggerParam param) {
    logs.add(param.message);
  });

  try {
    // Run ffmpeg -i which will fail but output media info
    // We intentionally don't specify output to trigger info dump
    await ffmpeg.run(['-i', filePath, '-f', 'null', '-']);
  } catch (e) {
    // Expected - ffmpeg -i without output spec will fail
    // The logs still contain media info
  }

  // Reset logger with no-op to avoid memory leaks
  // Note: setLogger doesn't accept null, use empty callback
  ffmpeg.setLogger((LoggerParam _) {});

  // Parse the collected logs
  final logOutput = logs.join('\n');
  return _parseMediaInfo(logOutput);
}

/// Parse media information from ffmpeg log output
Map<String, dynamic> _parseMediaInfo(String logOutput) {
  final result = <String, dynamic>{
    'format': <String, dynamic>{},
    'streams': <Map<String, dynamic>>[],
  };

  // Parse Duration: HH:MM:SS.ms
  final durationRegex = RegExp(r'Duration:\s*(\d{2}):(\d{2}):(\d{2})\.(\d+)');
  final durationMatch = durationRegex.firstMatch(logOutput);
  if (durationMatch != null) {
    final hours = int.parse(durationMatch.group(1)!);
    final minutes = int.parse(durationMatch.group(2)!);
    final seconds = int.parse(durationMatch.group(3)!);
    final fraction = durationMatch.group(4)!;

    final totalSeconds =
        hours * 3600 + minutes * 60 + seconds + double.parse('0.$fraction');

    (result['format'] as Map<String, dynamic>)['duration'] =
        totalSeconds.toString();
    (result['format'] as Map<String, dynamic>)['duration_formatted'] =
        '${durationMatch.group(1)}:${durationMatch.group(2)}:${durationMatch.group(3)}';
  }

  // Parse bitrate
  final bitrateRegex = RegExp(r'bitrate:\s*(\d+)\s*kb/s');
  final bitrateMatch = bitrateRegex.firstMatch(logOutput);
  if (bitrateMatch != null) {
    (result['format'] as Map<String, dynamic>)['bit_rate'] =
        (int.parse(bitrateMatch.group(1)!) * 1000).toString();
  }

  // Parse streams: Stream #0:0(und): Video: h264 ...
  final streamRegex = RegExp(
    r'Stream\s+#(\d+):(\d+)(?:\([^)]*\))?:\s*(Video|Audio|Subtitle):\s*([^\n]+)',
    multiLine: true,
  );

  for (final match in streamRegex.allMatches(logOutput)) {
    final streamType = match.group(3)!.toLowerCase();
    final streamInfo = match.group(4)!;
    final streamData = <String, dynamic>{
      'index': int.parse(match.group(2)!),
      'codec_type': streamType,
    };

    if (streamType == 'video') {
      // Parse video codec
      final codecMatch = RegExp(r'^(\w+)').firstMatch(streamInfo);
      if (codecMatch != null) {
        streamData['codec_name'] = codecMatch.group(1);
      }

      // Parse resolution: 1920x1080, 1280x720, etc.
      final resolutionRegex = RegExp(r'(\d{2,5})x(\d{2,5})');
      final resolutionMatch = resolutionRegex.firstMatch(streamInfo);
      if (resolutionMatch != null) {
        streamData['width'] = int.parse(resolutionMatch.group(1)!);
        streamData['height'] = int.parse(resolutionMatch.group(2)!);
      }

      // Parse frame rate: 30 fps, 29.97 fps, 24/1, etc.
      final fpsRegex = RegExp(r'(\d+(?:\.\d+)?)\s*fps');
      final fpsMatch = fpsRegex.firstMatch(streamInfo);
      if (fpsMatch != null) {
        streamData['r_frame_rate'] = fpsMatch.group(1);
      }

      // Parse pixel format: yuv420p, yuv444p, etc.
      final pixFmtRegex = RegExp(r'(yuv\d+p\d*|rgb\d+|bgr\d+)');
      final pixFmtMatch = pixFmtRegex.firstMatch(streamInfo);
      if (pixFmtMatch != null) {
        streamData['pix_fmt'] = pixFmtMatch.group(1);
      }
    } else if (streamType == 'audio') {
      // Parse audio codec
      final codecMatch = RegExp(r'^(\w+)').firstMatch(streamInfo);
      if (codecMatch != null) {
        streamData['codec_name'] = codecMatch.group(1);
      }

      // Parse sample rate: 44100 Hz, 48000 Hz
      final sampleRateRegex = RegExp(r'(\d+)\s*Hz');
      final sampleRateMatch = sampleRateRegex.firstMatch(streamInfo);
      if (sampleRateMatch != null) {
        streamData['sample_rate'] = sampleRateMatch.group(1);
      }

      // Parse channels: stereo, mono, 5.1
      if (streamInfo.contains('stereo')) {
        streamData['channels'] = 2;
        streamData['channel_layout'] = 'stereo';
      } else if (streamInfo.contains('mono')) {
        streamData['channels'] = 1;
        streamData['channel_layout'] = 'mono';
      } else if (streamInfo.contains('5.1')) {
        streamData['channels'] = 6;
        streamData['channel_layout'] = '5.1';
      }
    }

    (result['streams'] as List<Map<String, dynamic>>).add(streamData);
  }

  return result;
}

/// Write file to virtual filesystem
Future<void> writeFileWasm(String path, Uint8List data) async {
  final ffmpeg = await _getFFmpeg();
  ffmpeg.writeFile(path, data);
}

/// Read file from virtual filesystem
Future<Uint8List> readFileWasm(String path) async {
  final ffmpeg = await _getFFmpeg();
  return ffmpeg.readFile(path);
}

/// Delete file from virtual filesystem
Future<void> deleteFileWasm(String path) async {
  final ffmpeg = await _getFFmpeg();
  ffmpeg.unlink(path);
}

/// Cancel current operation
Future<void> cancelWasm() async {
  if (_ffmpeg != null) {
    try {
      // Just try to exit, catch any errors
      _ffmpeg!.exit();
    } catch (e) {
      // ignore errors during cancellation
    }
    _ffmpeg = null; // Reset instance
  }
}
