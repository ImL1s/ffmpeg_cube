import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'backend_router.dart';
import '../models/jobs/base_job.dart';
import '../models/job_error.dart';
import '../models/job_progress.dart';
import '../models/probe_result.dart';

/// Backend using system Process for Windows/Linux
class ProcessBackend implements FFmpegBackend {
  /// Path to FFmpeg binary (uses 'ffmpeg' from PATH if null)
  final String? ffmpegPath;

  /// Path to FFprobe binary (uses 'ffprobe' from PATH if null)
  final String? ffprobePath;

  Process? _currentProcess;

  ProcessBackend({
    this.ffmpegPath,
    this.ffprobePath,
  });

  String get _ffmpegCommand => ffmpegPath ?? 'ffmpeg';
  String get _ffprobeCommand => ffprobePath ?? 'ffprobe';

  @override
  BackendType get type => BackendType.process;

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run(_ffmpegCommand, ['-version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<JobResult<void>> execute(
    BaseJob job, {
    void Function(JobProgress)? onProgress,
    Duration? totalDuration,
  }) async {
    final args = job.toFFmpegArgs();
    try {
      _currentProcess = await Process.start(
        _ffmpegCommand,
        args,
        runInShell: Platform.isWindows,
      );

      final outputBuffer = StringBuffer();

      // FFmpeg outputs progress to stderr
      _currentProcess!.stderr.transform(utf8.decoder).listen((data) {
        outputBuffer.write(data);

        // Parse progress from output
        if (onProgress != null) {
          final lines = data.split('\n');
          for (final line in lines) {
            if (line.contains('time=')) {
              final progress = JobProgress.fromFFmpegOutput(
                line,
                totalDuration: totalDuration,
              );
              if (progress != null) {
                onProgress(progress);
              }
            }
          }
        }
      });

      // Also capture stdout
      _currentProcess!.stdout.transform(utf8.decoder).listen((data) {
        outputBuffer.write(data);
      });

      final exitCode = await _currentProcess!.exitCode;
      _currentProcess = null;

      if (exitCode == 0) {
        return JobResult.success();
      } else {
        return JobResult.failure(JobError.ffmpegFailed(
          returnCode: exitCode,
          output: outputBuffer.toString(),
        ));
      }
    } catch (e, st) {
      return JobResult.failure(JobError(
        code: JobErrorCode.ffmpegExecutionFailed,
        message: e.toString(),
        stackTrace: st,
      ));
    }
  }

  @override
  Future<JobResult<ProbeResult>> probe(String filePath) async {
    try {
      final result = await Process.run(
        _ffprobeCommand,
        [
          '-v',
          'quiet',
          '-print_format',
          'json',
          '-show_format',
          '-show_streams',
          filePath,
        ],
        runInShell: Platform.isWindows,
      );

      if (result.exitCode == 0) {
        final json =
            jsonDecode(result.stdout as String) as Map<String, dynamic>;
        return JobResult.success(
          data: ProbeResult.fromJson(filePath, json),
        );
      } else {
        return JobResult.failure(JobError.ffmpegFailed(
          returnCode: result.exitCode,
          output: result.stderr as String,
        ));
      }
    } catch (e, st) {
      return JobResult.failure(JobError(
        code: JobErrorCode.ffmpegExecutionFailed,
        message: e.toString(),
        stackTrace: st,
      ));
    }
  }

  @override
  Future<void> cancel() async {
    _currentProcess?.kill();
    _currentProcess = null;
  }

  @override
  Future<Uint8List?> readFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  @override
  void dispose() {
    cancel();
  }
}
