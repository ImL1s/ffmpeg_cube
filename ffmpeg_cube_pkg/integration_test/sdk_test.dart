import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

/// SDK Core Integration Tests
///
/// These tests verify the core SDK functionality at the package level.
/// For E2E tests with actual FFmpeg processing, see the example app.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FFmpegCubeClient Integration Tests', () {
    late FFmpegCubeClient client;

    setUp(() {
      client = FFmpegCubeClient();
    });

    tearDown(() {
      client.dispose();
    });

    test('Client initializes successfully', () {
      expect(client, isNotNull);
    });

    test('Client provides codec recommendations', () {
      final recommendation = client.getRecommendation();
      expect(recommendation, isNotNull);
      expect(recommendation.videoCodec, isNotNull);
      expect(recommendation.audioCodec, isNotNull);
    });

    test('Client provides web-optimized recommendations', () {
      final recommendation = client.getRecommendation(isWebTarget: true);
      expect(recommendation, isNotNull);
      // Web targets should prefer VP9 or H.264 for compatibility
      expect(
        [VideoCodec.h264, VideoCodec.vp9].contains(recommendation.videoCodec),
        isTrue,
      );
    });
  });

  group('UnifiedPlayer Integration Tests', () {
    test('Player creates successfully', () {
      final player = UnifiedPlayer();
      expect(player, isNotNull);
      expect(player.isPlaying, isFalse);
      expect(player.position, equals(Duration.zero));
      player.dispose();
    });

    test('Player exposes streams correctly', () {
      final player = UnifiedPlayer();
      expect(player.positionStream, isNotNull);
      expect(player.durationStream, isNotNull);
      expect(player.playingStream, isNotNull);
      expect(player.completedStream, isNotNull);
      expect(player.volumeStream, isNotNull);
      player.dispose();
    });
  });

  group('Job Model Integration Tests', () {
    test('TranscodeJob validates correctly', () {
      final validJob = TranscodeJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
      );
      expect(validJob.validate(), isTrue);

      final invalidJob = TranscodeJob(
        inputPath: '',
        outputPath: '/output.mp4',
      );
      expect(invalidJob.validate(), isFalse);
    });

    test('TrimJob generates correct FFmpeg args', () {
      final job = TrimJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
        startTime: const Duration(seconds: 10),
        endTime: const Duration(seconds: 30),
      );

      final args = job.toFFmpegArgs();
      expect(args, contains('-ss'));
      expect(args, contains('10'));
      expect(args, contains('-to'));
      expect(args, contains('30'));
    });

    test('ThumbnailJob validates correctly', () {
      final job = ThumbnailJob(
        videoPath: '/video.mp4',
        outputPath: '/thumbnail.jpg',
        timestamp: const Duration(seconds: 5),
      );
      expect(job.validate(), isTrue);
    });

    test('ConcatJob requires at least 2 inputs', () {
      final validJob = ConcatJob(
        inputPaths: ['/input1.mp4', '/input2.mp4'],
        outputPath: '/output.mp4',
      );
      expect(validJob.validate(), isTrue);

      final invalidJob = ConcatJob(
        inputPaths: ['/input1.mp4'],
        outputPath: '/output.mp4',
      );
      expect(invalidJob.validate(), isFalse);
    });

    test('SubtitleJob supports hardcode and softcode', () {
      final hardcodeJob = SubtitleJob(
        videoPath: '/video.mp4',
        subtitlePath: '/subs.srt',
        outputPath: '/output.mp4',
        embedType: SubtitleEmbedType.hardcode,
      );

      final args = hardcodeJob.toFFmpegArgs();
      expect(args, contains('-vf'));

      final softcodeJob = SubtitleJob(
        videoPath: '/video.mp4',
        subtitlePath: '/subs.srt',
        outputPath: '/output.mp4',
        embedType: SubtitleEmbedType.softcode,
      );

      final softArgs = softcodeJob.toFFmpegArgs();
      expect(softArgs, contains('-c:s'));
      expect(softArgs, contains('mov_text'));
    });

    test('MixAudioJob generates correct filter complex', () {
      final job = MixAudioJob(
        primaryPath: '/video.mp4',
        secondaryPath: '/audio.mp3',
        outputPath: '/output.mp4',
      );

      final args = job.toFFmpegArgs();
      expect(args, contains('-filter_complex'));
    });
  });

  group('FormatPolicy Integration Tests', () {
    test('FormatPolicy provides sensible defaults', () {
      final policy = FormatPolicy();
      final recommendation = policy.recommend();

      expect(recommendation.videoCodec, isNotNull);
      expect(recommendation.audioCodec, isNotNull);
      expect(recommendation.resolution, isNotNull);
    });

    test('FormatPolicy adjusts for web target', () {
      final policy = FormatPolicy();
      final recommendation = policy.recommend(isWebTarget: true);

      // Web should use widely compatible codecs
      expect(
        [VideoCodec.h264, VideoCodec.vp9].contains(recommendation.videoCodec),
        isTrue,
      );
    });
  });
}
