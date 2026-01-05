import '../models/jobs/base_job.dart';
import '../backends/backend_router.dart';

/// Policy for selecting optimal format based on requirements
enum FormatPolicyMode {
  /// Prioritize cross-platform compatibility (H.264/AAC)
  crossPlatform,

  /// Prioritize quality
  quality,

  /// Prioritize small file size
  compression,

  /// Prioritize processing speed
  speed,

  /// Custom - use provided parameters
  custom,
}

/// Format recommendation based on policy
class CodecRecommendation {
  final VideoCodec videoCodec;
  final AudioCodec audioCodec;
  final ContainerFormat container;
  final String? videoBitrate;
  final String? audioBitrate;
  final VideoResolution? resolution;

  const CodecRecommendation({
    required this.videoCodec,
    required this.audioCodec,
    required this.container,
    this.videoBitrate,
    this.audioBitrate,
    this.resolution,
  });

  /// Cross-platform compatible preset
  static const crossPlatform = CodecRecommendation(
    videoCodec: VideoCodec.h264,
    audioCodec: AudioCodec.aac,
    container: ContainerFormat.mp4,
    videoBitrate: '2M',
    audioBitrate: '128k',
  );

  /// High quality preset
  static const highQuality = CodecRecommendation(
    videoCodec: VideoCodec.h265,
    audioCodec: AudioCodec.aac,
    container: ContainerFormat.mp4,
    videoBitrate: '8M',
    audioBitrate: '256k',
  );

  /// High compression preset
  static const highCompression = CodecRecommendation(
    videoCodec: VideoCodec.h265,
    audioCodec: AudioCodec.opus,
    container: ContainerFormat.mkv,
    videoBitrate: '1M',
    audioBitrate: '96k',
  );

  /// Fast processing preset (copy codecs)
  static const fastCopy = CodecRecommendation(
    videoCodec: VideoCodec.copy,
    audioCodec: AudioCodec.copy,
    container: ContainerFormat.mp4,
  );

  /// Web optimized preset
  static const webOptimized = CodecRecommendation(
    videoCodec: VideoCodec.vp9,
    audioCodec: AudioCodec.opus,
    container: ContainerFormat.webm,
    videoBitrate: '2M',
    audioBitrate: '128k',
  );
}

/// Policy engine for making format decisions
class FormatPolicy {
  /// Default policy mode
  final FormatPolicyMode mode;

  /// Custom recommendation (for custom mode)
  final CodecRecommendation? customRecommendation;

  /// Platform-specific overrides
  final Map<TargetPlatform, CodecRecommendation>? platformOverrides;

  FormatPolicy({
    this.mode = FormatPolicyMode.crossPlatform,
    this.customRecommendation,
    this.platformOverrides,
  });

  /// Get recommendation based on policy and platform
  CodecRecommendation getRecommendation({
    TargetPlatform? platform,
    bool isPlaybackRequired = true,
    bool isWebTarget = false,
  }) {
    // Check platform overrides first
    if (platform != null && platformOverrides?.containsKey(platform) == true) {
      return platformOverrides![platform]!;
    }

    // Web target gets special handling
    if (isWebTarget) {
      // VP9/WebM has good browser support, but H.264 is more universal
      return mode == FormatPolicyMode.compression
          ? CodecRecommendation.webOptimized
          : CodecRecommendation.crossPlatform;
    }

    switch (mode) {
      case FormatPolicyMode.crossPlatform:
        return CodecRecommendation.crossPlatform;
      case FormatPolicyMode.quality:
        return CodecRecommendation.highQuality;
      case FormatPolicyMode.compression:
        return CodecRecommendation.highCompression;
      case FormatPolicyMode.speed:
        return CodecRecommendation.fastCopy;
      case FormatPolicyMode.custom:
        return customRecommendation ?? CodecRecommendation.crossPlatform;
    }
  }

  /// Check if a codec is supported on the platform
  static bool isCodecSupported(VideoCodec codec, TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        // Most Android devices support H.264, newer support H.265
        return true;
      case TargetPlatform.ios:
      case TargetPlatform.macos:
        // Apple devices support H.264, H.265 via VideoToolbox
        return codec != VideoCodec.vp8; // VP8 not natively supported
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        // Desktop with software FFmpeg supports all
        return true;
      case TargetPlatform.web:
        // Browser support varies
        return codec == VideoCodec.h264 ||
            codec == VideoCodec.vp8 ||
            codec == VideoCodec.vp9;
    }
  }

  /// Get optimal resolution for platform
  static VideoResolution getOptimalResolution(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.ios:
        return VideoResolution.r1080p;
      case TargetPlatform.macos:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return VideoResolution.r1080p;
      case TargetPlatform.web:
        return VideoResolution.r720p; // Lower for web bandwidth
    }
  }

  /// Suggest output path extension based on container
  static String getExtension(ContainerFormat container) {
    switch (container) {
      case ContainerFormat.mp4:
        return '.mp4';
      case ContainerFormat.webm:
        return '.webm';
      case ContainerFormat.mkv:
        return '.mkv';
      case ContainerFormat.mov:
        return '.mov';
      case ContainerFormat.avi:
        return '.avi';
      case ContainerFormat.m4a:
        return '.m4a';
      case ContainerFormat.mp3:
        return '.mp3';
    }
  }
}
