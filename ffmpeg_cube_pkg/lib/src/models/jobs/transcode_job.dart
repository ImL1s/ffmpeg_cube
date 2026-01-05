import 'base_job.dart';

/// Job for video transcoding operations
class TranscodeJob extends BaseJob {
  /// Path to input video file
  final String inputPath;

  /// Path for output video file
  final String outputPath;

  /// Video codec to use
  final VideoCodec? videoCodec;

  /// Audio codec to use
  final AudioCodec? audioCodec;

  /// Target resolution
  final VideoResolution? resolution;

  /// Custom resolution (width x height)
  final (int, int)? customResolution;

  /// Video bitrate (e.g., '2M', '5000k')
  final String? videoBitrate;

  /// Audio bitrate (e.g., '128k', '256k')
  final String? audioBitrate;

  /// Frame rate
  final int? frameRate;

  /// Container format
  final ContainerFormat? containerFormat;

  /// Enable hardware acceleration if available
  final bool useHardwareAcceleration;

  TranscodeJob({
    required this.inputPath,
    required this.outputPath,
    this.videoCodec,
    this.audioCodec,
    this.resolution,
    this.customResolution,
    this.videoBitrate,
    this.audioBitrate,
    this.frameRate,
    this.containerFormat,
    this.useHardwareAcceleration = false,
    super.id,
    super.description,
    super.additionalArgs,
  });

  @override
  List<String> toFFmpegArgs() {
    final args = <String>['-i', inputPath];

    // Video codec
    if (videoCodec != null) {
      args.addAll(['-c:v', videoCodec!.ffmpegName]);
    }

    // Audio codec
    if (audioCodec != null) {
      args.addAll(['-c:a', audioCodec!.ffmpegName]);
    }

    // Resolution
    if (resolution != null) {
      args.addAll(['-vf', resolution!.ffmpegScale]);
    } else if (customResolution != null) {
      args.addAll(
          ['-vf', 'scale=${customResolution!.$1}:${customResolution!.$2}']);
    }

    // Video bitrate
    if (videoBitrate != null) {
      args.addAll(['-b:v', videoBitrate!]);
    }

    // Audio bitrate
    if (audioBitrate != null) {
      args.addAll(['-b:a', audioBitrate!]);
    }

    // Frame rate
    if (frameRate != null) {
      args.addAll(['-r', frameRate.toString()]);
    }

    // Container format
    if (containerFormat != null) {
      args.addAll(['-f', containerFormat!.ffmpegName]);
    }

    // Additional args
    if (additionalArgs != null) {
      args.addAll(additionalArgs!);
    }

    // Overwrite output
    args.addAll(['-y', outputPath]);

    return args;
  }

  @override
  bool validate() {
    return inputPath.isNotEmpty && outputPath.isNotEmpty;
  }
}
