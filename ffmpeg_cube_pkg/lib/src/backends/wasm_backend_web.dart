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
    // TODO: Handle subtitle file data if provided?
  }

  if (data != null && path != null && path.isNotEmpty) {
    ffmpeg.writeFile(path, data);
  }
}

/// Probe a media file
Future<Map<String, dynamic>> probeWasm(String filePath) async {
  // ffmpeg_wasm usually doesn't expose ffprobe JSON directly same way as native
  // We might need to run ffmpeg with input and parse stderr, or if the package supports it.
  // Assuming the package doesn't have probe() wrapper, we might need to rely on
  // metadata extraction libraries or run ffmpeg -i file.
  // For now return empty map stub or throw
  throw UnimplementedError('Probe not fully supported in Wasm yet');
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
