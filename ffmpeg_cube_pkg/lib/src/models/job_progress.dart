/// Progress information for a running job
class JobProgress {
  /// Current progress percentage (0.0 to 1.0)
  final double progress;
  
  /// Current frame being processed
  final int? currentFrame;
  
  /// Total frames (if known)
  final int? totalFrames;
  
  /// Current time position being processed
  final Duration? currentTime;
  
  /// Total duration (if known)
  final Duration? totalDuration;
  
  /// Current processing speed (e.g., "2.5x")
  final double? speed;
  
  /// Current bitrate being written
  final int? bitrate;
  
  /// Current file size being written
  final int? currentSize;
  
  /// Estimated time remaining
  final Duration? estimatedTimeRemaining;
  
  /// Raw FFmpeg log line
  final String? rawOutput;
  
  JobProgress({
    required this.progress,
    this.currentFrame,
    this.totalFrames,
    this.currentTime,
    this.totalDuration,
    this.speed,
    this.bitrate,
    this.currentSize,
    this.estimatedTimeRemaining,
    this.rawOutput,
  });
  
  /// Parse progress from FFmpeg output line
  static JobProgress? fromFFmpegOutput(String line, {Duration? totalDuration}) {
    // Example: frame= 1234 fps=30 q=28.0 size=   12345kB time=00:00:41.23 bitrate=2456.7kbits/s speed=1.23x
    
    final timeMatch = RegExp(r'time=(\d+):(\d+):(\d+)\.(\d+)').firstMatch(line);
    if (timeMatch == null) return null;
    
    final hours = int.parse(timeMatch.group(1)!);
    final minutes = int.parse(timeMatch.group(2)!);
    final seconds = int.parse(timeMatch.group(3)!);
    final centiseconds = int.parse(timeMatch.group(4)!);
    
    final currentTime = Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: centiseconds * 10,
    );
    
    double progress = 0.0;
    if (totalDuration != null && totalDuration.inMilliseconds > 0) {
      progress = currentTime.inMilliseconds / totalDuration.inMilliseconds;
      progress = progress.clamp(0.0, 1.0);
    }
    
    // Parse frame
    int? frame;
    final frameMatch = RegExp(r'frame=\s*(\d+)').firstMatch(line);
    if (frameMatch != null) {
      frame = int.tryParse(frameMatch.group(1)!);
    }
    
    // Parse speed
    double? speed;
    final speedMatch = RegExp(r'speed=\s*([0-9.]+)x').firstMatch(line);
    if (speedMatch != null) {
      speed = double.tryParse(speedMatch.group(1)!);
    }
    
    // Parse bitrate
    int? bitrate;
    final bitrateMatch = RegExp(r'bitrate=\s*([0-9.]+)kbits/s').firstMatch(line);
    if (bitrateMatch != null) {
      final kbits = double.tryParse(bitrateMatch.group(1)!);
      if (kbits != null) {
        bitrate = (kbits * 1000).round();
      }
    }
    
    // Parse size
    int? currentSize;
    final sizeMatch = RegExp(r'size=\s*(\d+)kB').firstMatch(line);
    if (sizeMatch != null) {
      final kb = int.tryParse(sizeMatch.group(1)!);
      if (kb != null) {
        currentSize = kb * 1024;
      }
    }
    
    // Estimate remaining time
    Duration? remaining;
    if (speed != null && speed > 0 && totalDuration != null) {
      final remainingMs = (totalDuration.inMilliseconds - currentTime.inMilliseconds) / speed;
      remaining = Duration(milliseconds: remainingMs.round());
    }
    
    return JobProgress(
      progress: progress,
      currentFrame: frame,
      currentTime: currentTime,
      totalDuration: totalDuration,
      speed: speed,
      bitrate: bitrate,
      currentSize: currentSize,
      estimatedTimeRemaining: remaining,
      rawOutput: line,
    );
  }
  
  /// Progress as percentage (0-100)
  int get progressPercent => (progress * 100).round();
  
  /// Human-readable progress string
  String get progressString => '$progressPercent%';
}
