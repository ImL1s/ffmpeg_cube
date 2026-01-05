import 'dart:convert';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';

import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/log.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';

import 'backend_router.dart';
import '../models/job_error.dart';
import '../models/job_progress.dart';
import '../models/probe_result.dart';

/// Backend using FFmpegKit for Android/iOS/macOS
class FFmpegKitBackend implements FFmpegBackend {
  int? _currentSessionId;

  @override
  BackendType get type => BackendType.ffmpegKit;

  @override
  Future<bool> isAvailable() async {
    try {
      // Try to get FFmpeg version to check if available
      final session = await FFprobeKit.execute('-version');
      return ReturnCode.isSuccess(await session.getReturnCode());
    } catch (e) {
      return false;
    }
  }

  @override
  Future<JobResult<void>> execute(
    List<String> args, {
    void Function(JobProgress)? onProgress,
    Duration? totalDuration,
  }) async {
    try {
      final command = args.join(' ');

      final session = await FFmpegKit.executeAsync(
        command,
        (session) async {
          // Completion callback
          _currentSessionId = null;
        },
        (Log log) {
          // Log callback - parse progress from logs
        },
        (Statistics statistics) {
          // Statistics callback - more reliable progress info
          if (onProgress != null) {
            final time = statistics.getTime();
            final currentTime = Duration(milliseconds: time.toInt());

            double progress = 0.0;
            if (totalDuration != null && totalDuration.inMilliseconds > 0) {
              progress =
                  currentTime.inMilliseconds / totalDuration.inMilliseconds;
              progress = progress.clamp(0.0, 1.0);
            }

            onProgress(JobProgress(
              progress: progress,
              currentTime: currentTime,
              totalDuration: totalDuration,
              bitrate: statistics.getBitrate().toInt(),
              currentSize: statistics.getSize().toInt(),
              speed: statistics.getSpeed(),
            ));
          }
        },
      );

      _currentSessionId = session.getSessionId();

      // Wait for completion
      await session.getAllLogs();

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return JobResult.success();
      } else if (ReturnCode.isCancel(returnCode)) {
        return JobResult.failure(JobError.cancelled());
      } else {
        final output = await session.getOutput() ?? '';
        return JobResult.failure(JobError.ffmpegFailed(
          returnCode: returnCode?.getValue() ?? -1,
          output: output,
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
      final session = await FFprobeKit.execute(
          '-v quiet -print_format json -show_format -show_streams "$filePath"');

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final output = await session.getOutput() ?? '{}';
        final json = jsonDecode(output) as Map<String, dynamic>;
        return JobResult.success(
          data: ProbeResult.fromJson(filePath, json),
        );
      } else {
        final output = await session.getOutput() ?? '';
        return JobResult.failure(JobError.ffmpegFailed(
          returnCode: returnCode?.getValue() ?? -1,
          output: output,
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
    if (_currentSessionId != null) {
      await FFmpegKit.cancel(_currentSessionId);
      _currentSessionId = null;
    }
  }

  @override
  void dispose() {
    cancel();
  }
}
