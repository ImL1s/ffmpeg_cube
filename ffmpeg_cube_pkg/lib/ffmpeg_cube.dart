/// FFmpeg Cube - Cross-platform video/audio processing and playback SDK for Flutter
///
/// This library provides a unified API for:
/// - Video transcoding, trimming, and concatenation
/// - Audio extraction and mixing
/// - Thumbnail generation
/// - Subtitle embedding
/// - Media file probing
/// - Cross-platform video playback
///
/// ## Getting Started
///
/// ```dart
/// import 'package:ffmpeg_cube/ffmpeg_cube.dart';
/// import 'package:media_kit/media_kit.dart';
///
/// void main() {
///   // Initialize media_kit for playback
///   MediaKit.ensureInitialized();
///
///   runApp(MyApp());
/// }
/// ```
///
/// ## Usage Examples
///
/// ### Transcode Video
/// ```dart
/// final client = FFmpegCubeClient();
///
/// final result = await client.transcode(TranscodeJob(
///   inputPath: '/path/to/input.mp4',
///   outputPath: '/path/to/output.mp4',
///   videoCodec: VideoCodec.h264,
///   audioCodec: AudioCodec.aac,
///   resolution: VideoResolution.r1080p,
/// ));
///
/// if (result.success) {
///   print('Transcoding completed!');
/// }
/// ```
///
/// ### Get Media Information
/// ```dart
/// final probeResult = await client.probe('/path/to/video.mp4');
/// if (probeResult.success) {
///   print('Duration: ${probeResult.data?.duration}');
///   print('Resolution: ${probeResult.data?.videoStream?.resolution}');
/// }
/// ```
///
/// ### Play Video
/// ```dart
/// final player = UnifiedPlayer();
/// await player.open('/path/to/video.mp4');
///
/// // In your widget tree:
/// UnifiedVideoPlayer(player: player)
/// ```
library;

// Client
export 'src/client/ffmpeg_cube_client.dart';

// Models - Jobs
export 'src/models/jobs/base_job.dart';
export 'src/models/jobs/transcode_job.dart';
export 'src/models/jobs/trim_job.dart';
export 'src/models/jobs/thumbnail_job.dart';
export 'src/models/jobs/concat_job.dart';
export 'src/models/jobs/mix_audio_job.dart';
export 'src/models/jobs/subtitle_job.dart';

// Models - Results
export 'src/models/probe_result.dart';
export 'src/models/job_progress.dart';
export 'src/models/job_error.dart';

// Backends
export 'src/backends/backend_router.dart'
    show BackendRouter, BackendType, TargetPlatform;

// Policy
export 'src/policy/format_policy.dart';

// Player
export 'src/player/unified_player.dart';
