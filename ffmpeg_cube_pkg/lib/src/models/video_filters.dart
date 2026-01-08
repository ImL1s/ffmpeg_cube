/// Enum for video rotation angles
enum VideoRotation {
  none(0),
  rotate90(90),
  rotate180(180),
  rotate270(270);

  final int degrees;
  const VideoRotation(this.degrees);
}

/// Model for structured video filters
class VideoFilters {
  /// Rotation in degrees (90, 180, 270)
  final VideoRotation rotation;

  /// Brightness adjustment (-1.0 to 1.0, 0.0 is default)
  final double brightness;

  /// Contrast adjustment (0.0 to 2.0, 1.0 is default)
  final double contrast;

  /// Saturation adjustment (0.0 to 3.0, 1.0 is default)
  final double saturation;

  const VideoFilters({
    this.rotation = VideoRotation.none,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
  });

  /// Convert to FFmpeg filter string (e.g., eq=brightness=0.1:contrast=1.1)
  String toFFmpegString() {
    final filters = <String>[];

    // Color adjustments via 'eq' filter
    if (brightness != 0.0 || contrast != 1.0 || saturation != 1.0) {
      filters.add(
          'eq=brightness=$brightness:contrast=$contrast:saturation=$saturation');
    }

    // Rotation
    if (rotation != VideoRotation.none) {
      if (rotation == VideoRotation.rotate90) {
        filters.add('transpose=1');
      } else if (rotation == VideoRotation.rotate180) {
        filters.add('transpose=2,transpose=2');
      } else if (rotation == VideoRotation.rotate270) {
        filters.add('transpose=2');
      }
    }

    return filters.join(',');
  }

  bool get isEmpty =>
      rotation == VideoRotation.none &&
      brightness == 0.0 &&
      contrast == 1.0 &&
      saturation == 1.0;
}
