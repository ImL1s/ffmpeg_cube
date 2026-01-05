import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

/// ConcatJob 完整測試
void main() {
  group('ConcatJob Validation', () {
    test('Valid concat with 2 files passes', () {
      final job = ConcatJob(
        inputPaths: ['/a.mp4', '/b.mp4'],
        outputPath: '/out.mp4',
      );

      expect(job.validate(), true);
    });

    test('Valid concat with 5 files passes', () {
      final job = ConcatJob(
        inputPaths: ['/1.mp4', '/2.mp4', '/3.mp4', '/4.mp4', '/5.mp4'],
        outputPath: '/out.mp4',
      );

      expect(job.validate(), true);
    });

    test('Empty input list fails', () {
      final job = ConcatJob(
        inputPaths: [],
        outputPath: '/out.mp4',
      );

      expect(job.validate(), false);
    });

    test('Single file fails', () {
      final job = ConcatJob(
        inputPaths: ['/a.mp4'],
        outputPath: '/out.mp4',
      );

      expect(job.validate(), false);
    });

    test('Empty output path fails', () {
      final job = ConcatJob(
        inputPaths: ['/a.mp4', '/b.mp4'],
        outputPath: '',
      );

      expect(job.validate(), false);
    });
  });

  group('ConcatJob FFmpeg Args - Demuxer Method', () {
    test('Uses demuxer method by default', () {
      final job = ConcatJob(
        inputPaths: ['/a.mp4', '/b.mp4'],
        outputPath: '/out.mp4',
        method: ConcatMethod.demuxer,
      );

      final args = job.toFFmpegArgs();

      expect(args.contains('-f'), true);
      expect(args.contains('concat'), true);
    });

    test('Demuxer method uses safe flag', () {
      final job = ConcatJob(
        inputPaths: ['/a.mp4', '/b.mp4'],
        outputPath: '/out.mp4',
        method: ConcatMethod.demuxer,
      );

      final args = job.toFFmpegArgs();

      expect(args.contains('-safe'), true);
    });
  });

  group('ConcatJob FFmpeg Args - Filter Method', () {
    test('Filter method uses filter_complex', () {
      final job = ConcatJob(
        inputPaths: ['/a.mp4', '/b.mp4'],
        outputPath: '/out.mp4',
        method: ConcatMethod.filter,
      );

      final args = job.toFFmpegArgs();

      expect(args.contains('-filter_complex'), true);
    });

    test('Filter method includes all inputs', () {
      final job = ConcatJob(
        inputPaths: ['/a.mp4', '/b.mp4', '/c.mp4'],
        outputPath: '/out.mp4',
        method: ConcatMethod.filter,
      );

      final args = job.toFFmpegArgs();

      // Should have 3 -i flags
      int inputCount = 0;
      for (int i = 0; i < args.length; i++) {
        if (args[i] == '-i') inputCount++;
      }
      expect(inputCount, 3);
    });
  });

  group('ConcatJob with Re-encoding', () {
    test('Re-encode option adds codec settings', () {
      final job = ConcatJob(
        inputPaths: ['/a.mp4', '/b.mp4'],
        outputPath: '/out.mp4',
        method: ConcatMethod.filter,
        videoCodec: VideoCodec.h264,
        audioCodec: AudioCodec.aac,
      );

      final args = job.toFFmpegArgs();

      expect(args.contains('-c:v'), true);
      expect(args.contains('-c:a'), true);
    });
  });

  group('ConcatJob Utility Methods', () {
    test('Generate concat file content', () {
      final job = ConcatJob(
        inputPaths: ['/video1.mp4', '/video2.mp4', '/video3.mp4'],
        outputPath: '/out.mp4',
      );

      final content = job.generateConcatFileContent();

      expect(content.contains("file '/video1.mp4'"), true);
      expect(content.contains("file '/video2.mp4'"), true);
      expect(content.contains("file '/video3.mp4'"), true);
    });
  });
}
