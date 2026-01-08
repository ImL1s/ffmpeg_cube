import 'dart:io';
import 'dart:typed_data';

import 'base_job.dart';
import '../video_filters.dart';

/// Position of the watermark on the video
enum WatermarkPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center;

  String get ffmpegPosition {
    switch (this) {
      case WatermarkPosition.topLeft:
        return '10:10';
      case WatermarkPosition.topRight:
        return 'main_w-overlay_w-10:10';
      case WatermarkPosition.bottomLeft:
        return '10:main_h-overlay_h-10';
      case WatermarkPosition.bottomRight:
        return 'main_w-overlay_w-10:main_h-overlay_h-10';
      case WatermarkPosition.center:
        return '(main_w-overlay_w)/2:(main_h-overlay_h)/2';
    }
  }
}

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

  /// FFmpeg preset (e.g., ultrafast, medium)
  final String? preset;

  /// Video filters (rotation, brightness, etc.)
  final VideoFilters? filters;

  /// Path to watermark image
  final String? watermarkPath;

  /// Position of the watermark
  final WatermarkPosition watermarkPosition;

  /// Input data bytes (Web specific)
  final Uint8List? inputData;

  TranscodeJob({
    required this.inputPath,
    required this.outputPath,
    this.inputData,
    this.videoCodec,
    this.audioCodec,
    this.resolution,
    this.customResolution,
    this.videoBitrate,
    this.audioBitrate,
    this.frameRate,
    this.containerFormat,
    this.useHardwareAcceleration = false,
    this.preset,
    this.filters,
    this.watermarkPath,
    this.watermarkPosition = WatermarkPosition.bottomRight,
    super.id,
    super.description,
    super.additionalArgs,
  });

  @override
  List<String> toFFmpegArgs() {
    final args = <String>[];

    // Web Optimization: -movflags +faststart for MP4
    bool isMP4 = outputPath.toLowerCase().endsWith('.mp4') ||
        containerFormat?.ffmpegName == 'mp4';

    // Input(s)
    args.addAll(['-i', inputPath]);
    if (watermarkPath != null) {
      args.addAll(['-i', watermarkPath!]);
    }

    // Video filters / Overlays
    if (watermarkPath != null) {
      // Complex filter for watermark + optional filters
      String vf = filters != null && !filters!.isEmpty
          ? '[0:v]${filters!.toFFmpegString()}[v0];[v0][1:v]overlay=${watermarkPosition.ffmpegPosition}'
          : 'overlay=${watermarkPosition.ffmpegPosition}';

      args.addAll(['-filter_complex', vf]);
    } else if (filters != null && !filters!.isEmpty) {
      // Simple video filter
      args.addAll(['-vf', filters!.toFFmpegString()]);
    }

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

    // Preset
    if (preset != null) {
      args.addAll(['-preset', preset!]);
    }

    // Hardware acceleration (Best effort)
    if (useHardwareAcceleration && videoCodec != null) {
      // Basic heuristic for common platforms
      // In a real app, you might check Platform.isAndroid etc.
      // Since this is a pure Dart package, checking Platform requires dart:io.
      // We will assume "auto" behavior or explicit overrides if we can import dart:io.
      // For now, let's just use the commonly known codec names if the user requested acceleration.
      // PROPOSAL: If hardware acceleration is requested, we try to APPEND the suffix or change the codec.
      // But purely changing arguments might break if the codec isn't available.
      // SAFEST OPTION: Just pass -hwaccel auto before inputs?
      // Actually, -hwaccel is an input option. We are inside toFFmpegArgs which handles output options mostly.
      // Let's modify the way args are built to allow input options if needed, OR just swap the codec.

      // Let's try swapping libx264 -> h264_mediacodec (Android) / h264_videotoolbox (iOS/macOS)
      // We can't easily validly detect OS here without dart:io.
      // Let's assume the user knows what they are doing or the client logic handles it.
      // But wait! We CAN import dart:io in a general Dart package.
      bool isAndroid = false;
      bool isIOS = false;
      bool isMacOS = false;
      try {
        if (Platform.isAndroid) isAndroid = true;
        if (Platform.isIOS) isIOS = true;
        if (Platform.isMacOS) isMacOS = true;
      } catch (e) {
        // web or other
      }

      if (videoCodec!.ffmpegName == 'libx264') {
        int index = args.indexOf('libx264');
        if (index != -1) {
          if (isAndroid) {
            args[index] = 'h264_mediacodec';
          } else if (isIOS || isMacOS) {
            args[index] = 'h264_videotoolbox';
          }
        }
      }
    }

    // Additional args
    if (additionalArgs != null) {
      args.addAll(additionalArgs!);
    }

    // Overwrite output
    args.addAll(['-y']);

    // Add faststart for MP4
    if (isMP4) {
      args.addAll(['-movflags', '+faststart']);
    }

    args.add(outputPath);

    return args;
  }

  @override
  bool validate() {
    return inputPath.isNotEmpty && outputPath.isNotEmpty;
  }
}
