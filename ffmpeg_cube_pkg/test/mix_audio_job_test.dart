import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

/// MixAudioJob 完整測試
void main() {
  group('MixAudioJob Validation', () {
    test('Valid mix job with 2 tracks passes', () {
      final job = MixAudioJob(
        inputAudioPaths: ['/audio1.mp3', '/audio2.mp3'],
        outputPath: '/output.mp3',
      );

      expect(job.validate(), true);
    });

    test('Mix job with 1 track fails', () {
      final job = MixAudioJob(
        inputAudioPaths: ['/audio1.mp3'],
        outputPath: '/output.mp3',
      );

      expect(job.validate(), false);
    });

    test('Empty output path fails', () {
      final job = MixAudioJob(
        inputAudioPaths: ['/audio1.mp3', '/audio2.mp3'],
        outputPath: '',
      );

      expect(job.validate(), false);
    });

    test('Volume settings are applied correctly', () {
      final job = MixAudioJob(
        inputAudioPaths: ['/audio1.mp3', '/audio2.mp3'],
        outputPath: '/output.mp3',
        volumes: [0.5, 1.0],
      );

      final args = job.toFFmpegArgs();
      final argsString = args.join(' ');

      // Should contain volume filter
      expect(argsString.contains('volume'), true);
    });
  });

  group('MixAudioJob FFmpeg Args', () {
    test('Generates multiple input arguments', () {
      final job = MixAudioJob(
        inputAudioPaths: ['/a1.mp3', '/a2.mp3', '/a3.mp3'],
        outputPath: '/out.mp3',
      );

      final args = job.toFFmpegArgs();

      // Should have 3 input files
      int inputCount = 0;
      for (int i = 0; i < args.length; i++) {
        if (args[i] == '-i') inputCount++;
      }
      expect(inputCount, 3);
    });

    test('Includes filter_complex for mixing', () {
      final job = MixAudioJob(
        inputAudioPaths: ['/a1.mp3', '/a2.mp3'],
        outputPath: '/out.mp3',
      );

      final args = job.toFFmpegArgs();

      expect(args.contains('-filter_complex'), true);
      expect(args.any((a) => a.contains('amix')), true);
    });

    test('Applies normalization when enabled', () {
      final job = MixAudioJob(
        inputAudioPaths: ['/a1.mp3', '/a2.mp3'],
        outputPath: '/out.mp3',
        normalize: true,
      );

      final args = job.toFFmpegArgs();
      final argsString = args.join(' ');

      expect(argsString.contains('loudnorm'), true);
    });
  });
}
