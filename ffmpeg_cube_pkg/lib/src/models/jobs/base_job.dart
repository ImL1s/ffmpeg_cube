/// Base class for all job types
abstract class BaseJob {
  /// Unique identifier for this job
  final String id;
  
  /// Optional description for this job
  final String? description;
  
  /// Additional FFmpeg arguments to pass
  final List<String>? additionalArgs;
  
  BaseJob({
    String? id,
    this.description,
    this.additionalArgs,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  /// Convert job to FFmpeg arguments
  List<String> toFFmpegArgs();
  
  /// Validate the job parameters
  bool validate();
}

/// Video codec options
enum VideoCodec {
  h264('libx264'),
  h265('libx265'),
  vp8('libvpx'),
  vp9('libvpx-vp9'),
  av1('libaom-av1'),
  mpeg4('mpeg4'),
  copy('copy');
  
  final String ffmpegName;
  const VideoCodec(this.ffmpegName);
}

/// Audio codec options
enum AudioCodec {
  aac('aac'),
  mp3('libmp3lame'),
  opus('libopus'),
  vorbis('libvorbis'),
  flac('flac'),
  copy('copy');
  
  final String ffmpegName;
  const AudioCodec(this.ffmpegName);
}

/// Container format options
enum ContainerFormat {
  mp4('mp4'),
  webm('webm'),
  mkv('matroska'),
  mov('mov'),
  avi('avi'),
  m4a('m4a'),
  mp3('mp3');
  
  final String ffmpegName;
  const ContainerFormat(this.ffmpegName);
}

/// Video resolution presets
enum VideoResolution {
  r360p(640, 360),
  r480p(854, 480),
  r720p(1280, 720),
  r1080p(1920, 1080),
  r1440p(2560, 1440),
  r2160p(3840, 2160);
  
  final int width;
  final int height;
  const VideoResolution(this.width, this.height);
  
  String get ffmpegScale => 'scale=$width:$height';
}
