import 'dart:async';
import 'dart:io';

import '../backends/backend_router.dart';
import '../models/jobs/base_job.dart';
import '../models/jobs/transcode_job.dart';
import '../models/jobs/trim_job.dart';
import '../models/jobs/thumbnail_job.dart';
import '../models/jobs/concat_job.dart';
import '../models/jobs/mix_audio_job.dart';
import '../models/jobs/subtitle_job.dart';
import '../models/job_error.dart';
import '../models/job_progress.dart';
import '../models/probe_result.dart';
import '../policy/format_policy.dart';

/// Main entry point for the FFmpeg Cube SDK
///
/// Example usage:
/// ```dart
/// final client = FFmpegCubeClient();
///
/// // Transcode video
/// final result = await client.transcode(TranscodeJob(
///   inputPath: '/path/to/input.mp4',
///   outputPath: '/path/to/output.mp4',
///   videoCodec: VideoCodec.h264,
/// ));
///
/// // Get media info
/// final probe = await client.probe('/path/to/video.mp4');
/// print('Duration: ${probe.duration}');
/// ```
class FFmpegCubeClient {
  /// Backend router for platform-specific execution
  final BackendRouter _router;

  /// Format policy for codec recommendations
  final FormatPolicy _policy;

  /// Create a new FFmpegCubeClient
  FFmpegCubeClient({
    String? remoteEndpoint,
    BackendType? preferredBackend,
    String? ffmpegPath,
    FormatPolicy? policy,
  })  : _router = BackendRouter(
          remoteEndpoint: remoteEndpoint,
          preferredBackend: preferredBackend,
          ffmpegPath: ffmpegPath,
        ),
        _policy = policy ?? FormatPolicy();

  /// Get format policy for recommendations
  FormatPolicy get policy => _policy;

  /// Get the current platform
  TargetPlatform get currentPlatform => _router.currentPlatform;

  // ========== Video Operations ==========

  /// Transcode video with optional progress callback
  ///
  /// [job] - Transcode job with input/output paths and codec settings
  /// [onProgress] - Optional callback for progress updates
  Future<JobResult<void>> transcode(
    TranscodeJob job, {
    void Function(JobProgress)? onProgress,
  }) async {
    if (!job.validate()) {
      return JobResult.failure(
          JobError.validation('Invalid transcode job parameters'));
    }

    // Probe input to get duration for progress calculation
    Duration? totalDuration;
    try {
      final probeResult = await probe(job.inputPath);
      if (probeResult.success) {
        totalDuration = probeResult.data?.duration;
      }
    } catch (e) {
      // Continue without duration
    }

    return _router.execute(job,
        onProgress: onProgress, totalDuration: totalDuration);
  }

  /// Transcode video with progress stream
  Stream<JobProgress> transcodeWithProgress(TranscodeJob job) {
    final controller = StreamController<JobProgress>();

    transcode(job, onProgress: (progress) {
      controller.add(progress);
    }).then((result) {
      if (!result.success) {
        controller.addError(result.error!);
      }
      controller.close();
    });

    return controller.stream;
  }

  /// Trim/cut video
  Future<JobResult<void>> trim(
    TrimJob job, {
    void Function(JobProgress)? onProgress,
  }) async {
    if (!job.validate()) {
      return JobResult.failure(
          JobError.validation('Invalid trim job parameters'));
    }

    // For copy codec, duration is unknown so just execute
    if (job.useCopyCodec) {
      return _router.execute(job);
    }

    // Calculate total duration for progress
    final totalDuration = job.duration ??
        (job.endTime != null ? job.endTime! - job.startTime : null);

    return _router.execute(job,
        onProgress: onProgress, totalDuration: totalDuration);
  }

  /// Extract thumbnail from video
  Future<JobResult<void>> thumbnail(ThumbnailJob job) async {
    if (!job.validate()) {
      return JobResult.failure(
          JobError.validation('Invalid thumbnail job parameters'));
    }

    return _router.execute(job);
  }

  /// Concatenate multiple videos
  ///
  /// For demuxer method, a temp file will be created to list inputs
  Future<JobResult<void>> concat(
    ConcatJob job, {
    void Function(JobProgress)? onProgress,
  }) async {
    if (!job.validate()) {
      return JobResult.failure(
          JobError.validation('Need at least 2 input files'));
    }

    if (job.method == ConcatMethod.demuxer) {
      // Create concat file
      final tempDir = Directory.systemTemp;
      final concatFile =
          File('${tempDir.path}/ffmpeg_cube_concat_${job.id}.txt');

      try {
        await concatFile.writeAsString(job.generateConcatFileContent());

        // Create args with actual file path
        final args = <String>[
          '-f',
          'concat',
          '-safe',
          '0',
          '-i',
          concatFile.path,
          '-c',
          'copy',
          '-y',
          job.outputPath,
        ];

        final backend = await _router.getBackend();
        final result = await backend.execute(args, onProgress: onProgress);

        // Cleanup
        await concatFile.delete();

        return result;
      } catch (e, st) {
        // Cleanup on error
        try {
          await concatFile.delete();
        } catch (_) {}
        return JobResult.failure(JobError(
          code: JobErrorCode.ffmpegExecutionFailed,
          message: e.toString(),
          stackTrace: st,
        ));
      }
    } else {
      return _router.execute(job, onProgress: onProgress);
    }
  }

  /// Add subtitles to video
  Future<JobResult<void>> addSubtitle(
    SubtitleJob job, {
    void Function(JobProgress)? onProgress,
  }) async {
    if (!job.validate()) {
      return JobResult.failure(
          JobError.validation('Invalid subtitle job parameters'));
    }

    // Probe input for duration
    Duration? totalDuration;
    try {
      final probeResult = await probe(job.videoPath);
      if (probeResult.success) {
        totalDuration = probeResult.data?.duration;
      }
    } catch (e) {
      // Continue without duration
    }

    return _router.execute(job,
        onProgress: onProgress, totalDuration: totalDuration);
  }

  // ========== Audio Operations ==========

  /// Mix multiple audio tracks
  Future<JobResult<void>> mixAudio(
    MixAudioJob job, {
    void Function(JobProgress)? onProgress,
  }) async {
    if (!job.validate()) {
      return JobResult.failure(
          JobError.validation('Invalid audio mix job parameters'));
    }

    return _router.execute(job, onProgress: onProgress);
  }

  /// Extract audio from video
  Future<JobResult<void>> extractAudio({
    required String videoPath,
    required String outputPath,
    AudioCodec audioCodec = AudioCodec.aac,
    String? bitrate,
  }) async {
    final args = <String>[
      '-i', videoPath,
      '-vn', // No video
      '-c:a', audioCodec.ffmpegName,
    ];

    if (bitrate != null) {
      args.addAll(['-b:a', bitrate]);
    }

    args.addAll(['-y', outputPath]);

    final backend = await _router.getBackend();
    return backend.execute(args);
  }

  // ========== Media Info ==========

  /// Probe media file to get information
  Future<JobResult<ProbeResult>> probe(String filePath) async {
    return _router.probe(filePath);
  }

  // ========== Utility ==========

  /// Get codec recommendation based on policy
  CodecRecommendation getRecommendation({
    bool isPlaybackRequired = true,
    bool isWebTarget = false,
  }) {
    return _policy.getRecommendation(
      platform: currentPlatform,
      isPlaybackRequired: isPlaybackRequired,
      isWebTarget: isWebTarget,
    );
  }

  /// Cancel any running job
  Future<void> cancel() async {
    final backend = await _router.getBackend();
    await backend.cancel();
  }

  /// Dispose resources
  void dispose() {
    _router.dispose();
  }
}
