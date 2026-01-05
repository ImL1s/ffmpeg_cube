import 'base_job.dart';

/// Image format for thumbnail output
enum ImageFormat {
  jpg('mjpeg'),
  png('png'),
  webp('webp');
  
  final String ffmpegName;
  const ImageFormat(this.ffmpegName);
}

/// Job for extracting thumbnail from video
class ThumbnailJob extends BaseJob {
  /// Path to input video file
  final String videoPath;
  
  /// Time position to capture thumbnail
  final Duration timePosition;
  
  /// Path for output image file
  final String outputImagePath;
  
  /// Output image format
  final ImageFormat format;
  
  /// Width of output image (height auto-calculated to maintain aspect ratio)
  final int? width;
  
  /// Quality (1-31 for jpg, 0-100 for png/webp)
  final int? quality;
  
  ThumbnailJob({
    required this.videoPath,
    required this.timePosition,
    required this.outputImagePath,
    this.format = ImageFormat.jpg,
    this.width,
    this.quality,
    super.id,
    super.description,
    super.additionalArgs,
  });
  
  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
  
  @override
  List<String> toFFmpegArgs() {
    final args = <String>[
      '-ss', _formatDuration(timePosition),
      '-i', videoPath,
      '-vframes', '1',
    ];
    
    // Video filter for scaling
    final filters = <String>[];
    if (width != null) {
      filters.add('scale=$width:-1');
    }
    
    if (filters.isNotEmpty) {
      args.addAll(['-vf', filters.join(',')]);
    }
    
    // Quality settings based on format
    if (quality != null) {
      switch (format) {
        case ImageFormat.jpg:
          args.addAll(['-q:v', quality.toString()]);
          break;
        case ImageFormat.png:
        case ImageFormat.webp:
          args.addAll(['-compression_level', quality.toString()]);
          break;
      }
    }
    
    // Additional args
    if (additionalArgs != null) {
      args.addAll(additionalArgs!);
    }
    
    args.addAll(['-y', outputImagePath]);
    
    return args;
  }
  
  @override
  bool validate() {
    return videoPath.isNotEmpty && 
           outputImagePath.isNotEmpty &&
           timePosition >= Duration.zero;
  }
}
