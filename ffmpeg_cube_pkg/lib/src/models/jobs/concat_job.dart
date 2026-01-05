import 'base_job.dart';

/// Concatenation method
enum ConcatMethod {
  /// Concat demuxer (fast, requires same codec)
  demuxer,

  /// Concat filter (slower, allows different codecs)
  filter,
}

/// Job for concatenating multiple videos
class ConcatJob extends BaseJob {
  /// List of input video paths
  final List<String> inputPaths;

  /// Path for output video file
  final String outputPath;

  /// Concatenation method to use
  final ConcatMethod method;

  /// Video codec for re-encoding (only for filter method)
  final VideoCodec? videoCodec;

  /// Audio codec for re-encoding (only for filter method)
  final AudioCodec? audioCodec;

  ConcatJob({
    required this.inputPaths,
    required this.outputPath,
    this.method = ConcatMethod.demuxer,
    this.videoCodec,
    this.audioCodec,
    super.id,
    super.description,
    super.additionalArgs,
  });

  /// Generate the concat file content for demuxer method
  String generateConcatFileContent() {
    return inputPaths.map((path) => "file '$path'").join('\n');
  }

  @override
  List<String> toFFmpegArgs() {
    final args = <String>[];

    if (method == ConcatMethod.demuxer) {
      // Will need to write concat file first
      // Placeholder - actual implementation handles file creation
      args.addAll([
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        'CONCAT_FILE_PLACEHOLDER',
        '-c',
        'copy',
      ]);
    } else {
      // Filter method
      for (final path in inputPaths) {
        args.addAll(['-i', path]);
      }

      final filterInputs =
          List.generate(inputPaths.length, (i) => '[$i:v][$i:a]').join('');
      final filterComplex =
          '${filterInputs}concat=n=${inputPaths.length}:v=1:a=1[outv][outa]';

      args.addAll([
        '-filter_complex',
        filterComplex,
        '-map',
        '[outv]',
        '-map',
        '[outa]',
      ]);

      if (videoCodec != null) {
        args.addAll(['-c:v', videoCodec!.ffmpegName]);
      }
      if (audioCodec != null) {
        args.addAll(['-c:a', audioCodec!.ffmpegName]);
      }
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
    return inputPaths.length >= 2 && outputPath.isNotEmpty;
  }
}
