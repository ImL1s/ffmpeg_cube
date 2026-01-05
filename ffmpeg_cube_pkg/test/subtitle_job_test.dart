import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

/// SubtitleJob 完整測試
void main() {
  group('SubtitleJob Validation', () {
    test('Valid subtitle job passes', () {
      final job = SubtitleJob(
        videoPath: '/video.mp4',
        subtitlePath: '/sub.srt',
        outputPath: '/output.mp4',
      );
      
      expect(job.validate(), true);
    });

    test('Empty video path fails', () {
      final job = SubtitleJob(
        videoPath: '',
        subtitlePath: '/sub.srt',
        outputPath: '/output.mp4',
      );
      
      expect(job.validate(), false);
    });

    test('Empty subtitle path fails', () {
      final job = SubtitleJob(
        videoPath: '/video.mp4',
        subtitlePath: '',
        outputPath: '/output.mp4',
      );
      
      expect(job.validate(), false);
    });

    test('Empty output path fails', () {
      final job = SubtitleJob(
        videoPath: '/video.mp4',
        subtitlePath: '/sub.srt',
        outputPath: '',
      );
      
      expect(job.validate(), false);
    });
  });

  group('SubtitleJob FFmpeg Args - Hardcode', () {
    test('Hardcode mode uses subtitles filter', () {
      final job = SubtitleJob(
        videoPath: '/video.mp4',
        subtitlePath: '/sub.srt',
        outputPath: '/output.mp4',
        embedType: SubtitleEmbedType.hardcode,
      );
      
      final args = job.toFFmpegArgs();
      final argsString = args.join(' ');
      
      expect(argsString.contains('subtitles') || argsString.contains('ass'), true);
    });

    test('Font size is applied in hardcode mode', () {
      final job = SubtitleJob(
        videoPath: '/video.mp4',
        subtitlePath: '/sub.srt',
        outputPath: '/output.mp4',
        embedType: SubtitleEmbedType.hardcode,
        fontSize: 24,
      );
      
      final args = job.toFFmpegArgs();
      final argsString = args.join(' ');
      
      expect(argsString.contains('24') || argsString.contains('FontSize'), true);
    });
  });

  group('SubtitleJob FFmpeg Args - Softcode', () {
    test('Softcode mode uses subtitle stream mapping', () {
      final job = SubtitleJob(
        videoPath: '/video.mp4',
        subtitlePath: '/sub.srt',
        outputPath: '/output.mkv',
        embedType: SubtitleEmbedType.softcode,
      );
      
      final args = job.toFFmpegArgs();
      
      // Softcode should have multiple inputs
      expect(args.where((a) => a == '-i').length, 2);
    });
  });

  group('SubtitleJob Subtitle Format Detection', () {
    test('Supports SRT format', () {
      final job = SubtitleJob(
        videoPath: '/video.mp4',
        subtitlePath: '/subtitle.srt',
        outputPath: '/output.mp4',
      );
      
      expect(job.validate(), true);
    });

    test('Supports ASS format', () {
      final job = SubtitleJob(
        videoPath: '/video.mp4',
        subtitlePath: '/subtitle.ass',
        outputPath: '/output.mp4',
      );
      
      expect(job.validate(), true);
    });

    test('Supports VTT format', () {
      final job = SubtitleJob(
        videoPath: '/video.mp4',
        subtitlePath: '/subtitle.vtt',
        outputPath: '/output.mp4',
      );
      
      expect(job.validate(), true);
    });
  });
}
