import 'base_job.dart';

/// Job for mixing multiple audio tracks
class MixAudioJob extends BaseJob {
  /// List of input audio file paths
  final List<String> inputAudioPaths;
  
  /// Path for output audio file
  final String outputPath;
  
  /// Audio codec for output
  final AudioCodec? audioCodec;
  
  /// Output bitrate (e.g., '192k')
  final String? bitrate;
  
  /// Volume levels for each input (0.0 to 2.0, 1.0 is normal)
  final List<double>? volumes;
  
  /// Whether to normalize the output audio
  final bool normalize;
  
  MixAudioJob({
    required this.inputAudioPaths,
    required this.outputPath,
    this.audioCodec,
    this.bitrate,
    this.volumes,
    this.normalize = false,
    super.id,
    super.description,
    super.additionalArgs,
  });
  
  @override
  List<String> toFFmpegArgs() {
    final args = <String>[];
    
    // Add all inputs
    for (final path in inputAudioPaths) {
      args.addAll(['-i', path]);
    }
    
    // Build amix filter
    final inputs = inputAudioPaths.length;
    var filterComplex = 'amix=inputs=$inputs:duration=longest';
    
    // Add volume adjustments if specified
    if (volumes != null && volumes!.length == inputAudioPaths.length) {
      final volumeFilters = <String>[];
      for (var i = 0; i < volumes!.length; i++) {
        volumeFilters.add('[$i:a]volume=${volumes![i]}[a$i]');
      }
      final mixInputs = List.generate(inputs, (i) => '[a$i]').join('');
      filterComplex = '${volumeFilters.join(';')};${mixInputs}amix=inputs=$inputs:duration=longest';
    }
    
    // Add normalization
    if (normalize) {
      filterComplex += ',loudnorm';
    }
    
    args.addAll(['-filter_complex', filterComplex]);
    
    // Audio codec
    if (audioCodec != null) {
      args.addAll(['-c:a', audioCodec!.ffmpegName]);
    }
    
    // Bitrate
    if (bitrate != null) {
      args.addAll(['-b:a', bitrate!]);
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
    if (inputAudioPaths.length < 2) return false;
    if (outputPath.isEmpty) return false;
    if (volumes != null && volumes!.length != inputAudioPaths.length) return false;
    return true;
  }
}
