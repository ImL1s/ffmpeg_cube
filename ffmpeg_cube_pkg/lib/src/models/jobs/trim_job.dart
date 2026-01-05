import 'base_job.dart';

/// Job for trimming/cutting video
class TrimJob extends BaseJob {
  /// Path to input video file
  final String inputPath;
  
  /// Path for output video file
  final String outputPath;
  
  /// Start time in seconds or time string (e.g., '00:01:30')
  final Duration startTime;
  
  /// End time in seconds or time string (e.g., '00:02:30')
  final Duration? endTime;
  
  /// Duration from start time
  final Duration? duration;
  
  /// Use copy codec for faster processing (no re-encoding)
  final bool useCopyCodec;
  
  TrimJob({
    required this.inputPath,
    required this.outputPath,
    required this.startTime,
    this.endTime,
    this.duration,
    this.useCopyCodec = true,
    super.id,
    super.description,
    super.additionalArgs,
  });
  
  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }
  
  @override
  List<String> toFFmpegArgs() {
    final args = <String>[
      '-ss', _formatDuration(startTime),
      '-i', inputPath,
    ];
    
    // Duration or end time
    if (duration != null) {
      args.addAll(['-t', _formatDuration(duration!)]);
    } else if (endTime != null) {
      final dur = endTime! - startTime;
      args.addAll(['-t', _formatDuration(dur)]);
    }
    
    // Copy codec for faster processing
    if (useCopyCodec) {
      args.addAll(['-c', 'copy']);
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
    if (inputPath.isEmpty || outputPath.isEmpty) return false;
    if (startTime.isNegative) return false; // Negative start time invalid
    if (endTime != null && duration != null) return false; // Can't have both
    if (endTime != null && endTime! <= startTime) return false;
    if (duration != null && duration!.isNegative) return false;
    return true;
  }
}
