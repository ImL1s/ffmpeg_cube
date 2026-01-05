/// Result of probing a media file with FFprobe
class ProbeResult {
  /// File path that was probed
  final String filePath;

  /// Duration of the media
  final Duration? duration;

  /// Container format (e.g., 'mp4', 'mkv')
  final String? format;

  /// File size in bytes
  final int? fileSize;

  /// Bitrate in bits per second
  final int? bitrate;

  /// Video stream information
  final VideoStreamInfo? videoStream;

  /// Audio stream information
  final AudioStreamInfo? audioStream;

  /// Subtitle streams
  final List<SubtitleStreamInfo> subtitleStreams;

  /// Raw FFprobe output
  final Map<String, dynamic>? rawData;

  ProbeResult({
    required this.filePath,
    this.duration,
    this.format,
    this.fileSize,
    this.bitrate,
    this.videoStream,
    this.audioStream,
    this.subtitleStreams = const [],
    this.rawData,
  });

  /// Create from FFprobe JSON output
  factory ProbeResult.fromJson(String filePath, Map<String, dynamic> json) {
    final format = json['format'] as Map<String, dynamic>?;
    final streams = json['streams'] as List<dynamic>? ?? [];

    VideoStreamInfo? videoStream;
    AudioStreamInfo? audioStream;
    final subtitleStreams = <SubtitleStreamInfo>[];

    for (final stream in streams) {
      final codecType = stream['codec_type'] as String?;
      if (codecType == 'video' && videoStream == null) {
        videoStream = VideoStreamInfo.fromJson(stream as Map<String, dynamic>);
      } else if (codecType == 'audio' && audioStream == null) {
        audioStream = AudioStreamInfo.fromJson(stream as Map<String, dynamic>);
      } else if (codecType == 'subtitle') {
        subtitleStreams
            .add(SubtitleStreamInfo.fromJson(stream as Map<String, dynamic>));
      }
    }

    return ProbeResult(
      filePath: filePath,
      duration: format?['duration'] != null
          ? Duration(
              milliseconds:
                  (double.parse(format!['duration'].toString()) * 1000).round())
          : null,
      format: format?['format_name'] as String?,
      fileSize: format?['size'] != null
          ? int.tryParse(format!['size'].toString())
          : null,
      bitrate: format?['bit_rate'] != null
          ? int.tryParse(format!['bit_rate'].toString())
          : null,
      videoStream: videoStream,
      audioStream: audioStream,
      subtitleStreams: subtitleStreams,
      rawData: json,
    );
  }

  /// Check if this is a video file
  bool get isVideo => videoStream != null;

  /// Check if this is an audio-only file
  bool get isAudioOnly => videoStream == null && audioStream != null;

  /// Check if this file has audio
  bool get hasAudio => audioStream != null;

  /// Check if this file has subtitles
  bool get hasSubtitles => subtitleStreams.isNotEmpty;
}

/// Video stream information
class VideoStreamInfo {
  final String? codec;
  final int? width;
  final int? height;
  final double? frameRate;
  final int? bitrate;
  final String? pixelFormat;

  VideoStreamInfo({
    this.codec,
    this.width,
    this.height,
    this.frameRate,
    this.bitrate,
    this.pixelFormat,
  });

  factory VideoStreamInfo.fromJson(Map<String, dynamic> json) {
    double? fps;
    final fpsStr = json['r_frame_rate'] as String?;
    if (fpsStr != null && fpsStr.contains('/')) {
      final parts = fpsStr.split('/');
      if (parts.length == 2) {
        final num = double.tryParse(parts[0]);
        final den = double.tryParse(parts[1]);
        if (num != null && den != null && den > 0) {
          fps = num / den;
        }
      }
    }

    return VideoStreamInfo(
      codec: json['codec_name'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      frameRate: fps,
      bitrate: json['bit_rate'] != null
          ? int.tryParse(json['bit_rate'].toString())
          : null,
      pixelFormat: json['pix_fmt'] as String?,
    );
  }

  String get resolution => '${width ?? 0}x${height ?? 0}';
}

/// Audio stream information
class AudioStreamInfo {
  final String? codec;
  final int? sampleRate;
  final int? channels;
  final int? bitrate;

  AudioStreamInfo({
    this.codec,
    this.sampleRate,
    this.channels,
    this.bitrate,
  });

  factory AudioStreamInfo.fromJson(Map<String, dynamic> json) {
    return AudioStreamInfo(
      codec: json['codec_name'] as String?,
      sampleRate: json['sample_rate'] != null
          ? int.tryParse(json['sample_rate'].toString())
          : null,
      channels: json['channels'] as int?,
      bitrate: json['bit_rate'] != null
          ? int.tryParse(json['bit_rate'].toString())
          : null,
    );
  }
}

/// Subtitle stream information
class SubtitleStreamInfo {
  final String? codec;
  final String? language;
  final String? title;

  SubtitleStreamInfo({
    this.codec,
    this.language,
    this.title,
  });

  factory SubtitleStreamInfo.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'] as Map<String, dynamic>?;
    return SubtitleStreamInfo(
      codec: json['codec_name'] as String?,
      language: tags?['language'] as String?,
      title: tags?['title'] as String?,
    );
  }
}
