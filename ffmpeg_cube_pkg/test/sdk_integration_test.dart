import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

/// SDK 核心功能整合測試
void main() {
  group('FFmpegCubeClient Integration', () {
    late FFmpegCubeClient client;

    setUp(() {
      client = FFmpegCubeClient();
    });

    tearDown(() {
      client.dispose();
    });

    test('Client initializes correctly', () {
      expect(client, isNotNull);
      expect(client.policy, isNotNull);
    });

    test('Policy returns cross-platform recommendation by default', () {
      final recommendation = client.getRecommendation();

      expect(recommendation.videoCodec, VideoCodec.h264);
      expect(recommendation.audioCodec, AudioCodec.aac);
      expect(recommendation.container, ContainerFormat.mp4);
    });
  });

  group('TranscodeJob Validation', () {
    test('Valid job passes validation', () {
      final job = TranscodeJob(
        inputPath: '/path/to/input.mp4',
        outputPath: '/path/to/output.mp4',
      );

      expect(job.validate(), true);
    });

    test('Empty input path fails validation', () {
      final job = TranscodeJob(
        inputPath: '',
        outputPath: '/path/to/output.mp4',
      );

      expect(job.validate(), false);
    });

    test('Empty output path fails validation', () {
      final job = TranscodeJob(
        inputPath: '/path/to/input.mp4',
        outputPath: '',
      );

      expect(job.validate(), false);
    });

    test('toFFmpegArgs generates correct command', () {
      final job = TranscodeJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
        videoCodec: VideoCodec.h265,
        audioCodec: AudioCodec.opus,
        resolution: VideoResolution.r1080p,
        videoBitrate: '5M',
      );

      final args = job.toFFmpegArgs();

      expect(args.contains('-i'), true);
      expect(args.contains('/input.mp4'), true);
      expect(args.contains('-c:v'), true);
      expect(args.contains('libx265'), true);
      expect(args.contains('-c:a'), true);
      expect(args.contains('libopus'), true);
      expect(args.contains('-vf'), true);
      expect(args.contains('-b:v'), true);
      expect(args.contains('5M'), true);
    });
  });

  group('TrimJob Validation', () {
    test('Valid trim job passes validation', () {
      final job = TrimJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
        startTime: Duration.zero,
        duration: const Duration(seconds: 10),
      );

      expect(job.validate(), true);
    });

    test('Negative start time fails validation', () {
      final job = TrimJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
        startTime: const Duration(seconds: -5),
        duration: const Duration(seconds: 10),
      );

      expect(job.validate(), false);
    });
  });

  group('ThumbnailJob Validation', () {
    test('Valid thumbnail job passes validation', () {
      final job = ThumbnailJob(
        videoPath: '/video.mp4',
        timePosition: const Duration(seconds: 5),
        outputImagePath: '/thumb.jpg',
      );

      expect(job.validate(), true);
    });

    test('Negative time position fails validation', () {
      final job = ThumbnailJob(
        videoPath: '/video.mp4',
        timePosition: const Duration(seconds: -1),
        outputImagePath: '/thumb.jpg',
      );

      expect(job.validate(), false);
    });
  });

  group('ConcatJob Validation', () {
    test('Valid concat job with 2+ files passes', () {
      final job = ConcatJob(
        inputPaths: ['/a.mp4', '/b.mp4'],
        outputPath: '/out.mp4',
      );

      expect(job.validate(), true);
    });

    test('Concat job with 1 file fails', () {
      final job = ConcatJob(
        inputPaths: ['/a.mp4'],
        outputPath: '/out.mp4',
      );

      expect(job.validate(), false);
    });
  });

  group('JobProgress Parsing', () {
    test('Parses standard FFmpeg output correctly', () {
      const line =
          'frame=  500 fps=30 q=28.0 size=   5000kB time=00:00:16.67 bitrate=2456.7kbits/s speed=1.00x';
      final duration = const Duration(seconds: 30);

      final progress =
          JobProgress.fromFFmpegOutput(line, totalDuration: duration);

      expect(progress, isNotNull);
      expect(progress!.currentFrame, 500);
      expect(progress.currentTime?.inSeconds, 16);
      expect(progress.speed, 1.0);
      expect(progress.progressPercent, closeTo(55, 5));
    });

    test('Returns null for non-progress lines', () {
      const line = 'Input #0, mov,mp4,m4a,3gp,3g2,mj2, from "input.mp4":';

      final progress = JobProgress.fromFFmpegOutput(line);

      expect(progress, isNull);
    });
  });

  group('FormatPolicy', () {
    test('Cross-platform mode returns H.264/AAC', () {
      final policy = FormatPolicy(mode: FormatPolicyMode.crossPlatform);
      final rec = policy.getRecommendation();

      expect(rec.videoCodec, VideoCodec.h264);
      expect(rec.audioCodec, AudioCodec.aac);
    });

    test('Quality mode returns H.265', () {
      final policy = FormatPolicy(mode: FormatPolicyMode.quality);
      final rec = policy.getRecommendation();

      expect(rec.videoCodec, VideoCodec.h265);
    });

    test('Compression mode returns H.265/Opus', () {
      final policy = FormatPolicy(mode: FormatPolicyMode.compression);
      final rec = policy.getRecommendation();

      expect(rec.videoCodec, VideoCodec.h265);
      expect(rec.audioCodec, AudioCodec.opus);
    });

    test('Speed mode returns copy codec', () {
      final policy = FormatPolicy(mode: FormatPolicyMode.speed);
      final rec = policy.getRecommendation();

      expect(rec.videoCodec, VideoCodec.copy);
      expect(rec.audioCodec, AudioCodec.copy);
    });

    test('Web target with compression returns WebM', () {
      final policy = FormatPolicy(mode: FormatPolicyMode.compression);
      final rec = policy.getRecommendation(isWebTarget: true);

      expect(rec.container, ContainerFormat.webm);
    });
  });

  group('ProbeResult Parsing', () {
    test('Parses video stream correctly', () {
      final json = {
        'format': {
          'duration': '120.5',
          'format_name': 'mp4',
          'size': '10485760',
          'bit_rate': '700000',
        },
        'streams': [
          {
            'codec_type': 'video',
            'codec_name': 'h264',
            'width': 1920,
            'height': 1080,
            'r_frame_rate': '24/1',
            'pix_fmt': 'yuv420p',
          },
        ],
      };

      final result = ProbeResult.fromJson('/test.mp4', json);

      expect(result.isVideo, true);
      expect(result.videoStream?.width, 1920);
      expect(result.videoStream?.height, 1080);
      expect(result.videoStream?.codec, 'h264');
      expect(result.duration?.inSeconds, 120);
    });

    test('Parses audio stream correctly', () {
      final json = {
        'format': {'duration': '180.0'},
        'streams': [
          {
            'codec_type': 'audio',
            'codec_name': 'aac',
            'sample_rate': '44100',
            'channels': 2,
            'bit_rate': '128000',
          },
        ],
      };

      final result = ProbeResult.fromJson('/test.mp3', json);

      expect(result.hasAudio, true);
      expect(result.audioStream?.codec, 'aac');
      expect(result.audioStream?.sampleRate, 44100);
      expect(result.audioStream?.channels, 2);
    });
  });

  group('JobError', () {
    test('Creates validation error correctly', () {
      final error = JobError.validation('Invalid parameter');

      expect(error.code, JobErrorCode.invalidParameters);
      expect(error.message.contains('Invalid parameter'), true);
    });

    test('Creates cancellation error correctly', () {
      final error = JobError.cancelled();

      expect(error.code, JobErrorCode.cancelled);
    });

    test('Creates platform not supported error correctly', () {
      final error = JobError.platformNotSupported('Web');

      expect(error.code, JobErrorCode.platformNotSupported);
      expect(error.message.contains('Web'), true);
    });
  });
}
