import 'base_job.dart';

/// Subtitle embed type
enum SubtitleEmbedType {
  /// Hard burn subtitles into video (cannot be turned off)
  hardcode,
  /// Soft embed as separate stream (can be toggled)
  softcode,
}

/// Job for adding subtitles to video
class SubtitleJob extends BaseJob {
  /// Path to input video file
  final String videoPath;
  
  /// Path to subtitle file (SRT, ASS, VTT)
  final String subtitlePath;
  
  /// Path for output video file
  final String outputPath;
  
  /// How to embed the subtitle
  final SubtitleEmbedType embedType;
  
  /// Subtitle font size (only for hardcode)
  final int? fontSize;
  
  /// Subtitle font name (only for hardcode)
  final String? fontName;
  
  /// Subtitle position from bottom in pixels (only for hardcode)
  final int? marginV;
  
  SubtitleJob({
    required this.videoPath,
    required this.subtitlePath,
    required this.outputPath,
    this.embedType = SubtitleEmbedType.softcode,
    this.fontSize,
    this.fontName,
    this.marginV,
    super.id,
    super.description,
    super.additionalArgs,
  });
  
  @override
  List<String> toFFmpegArgs() {
    final args = <String>['-i', videoPath];
    
    if (embedType == SubtitleEmbedType.hardcode) {
      // Build subtitles filter
      var subtitlesFilter = "subtitles='$subtitlePath'";
      
      final styleOptions = <String>[];
      if (fontSize != null) styleOptions.add('FontSize=$fontSize');
      if (fontName != null) styleOptions.add('FontName=$fontName');
      if (marginV != null) styleOptions.add('MarginV=$marginV');
      
      if (styleOptions.isNotEmpty) {
        subtitlesFilter += ":force_style='${styleOptions.join(',')}'";
      }
      
      args.addAll(['-vf', subtitlesFilter]);
      
    } else {
      // Soft embed
      args.addAll([
        '-i', subtitlePath,
        '-c:v', 'copy',
        '-c:a', 'copy',
        '-c:s', 'mov_text', // For MP4 containers
        '-map', '0:v',
        '-map', '0:a',
        '-map', '1:s',
      ]);
    }
    
    // Additional args
    if (additionalArgs != null) {
      args.addAll(additionalArgs!);
    }
    
    args.addAll(['-y', outputPath]);
    
    return args;
  }
  
  @override
  bool validate() {
    return videoPath.isNotEmpty && 
           subtitlePath.isNotEmpty && 
           outputPath.isNotEmpty;
  }
}
