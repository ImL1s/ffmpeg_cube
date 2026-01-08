import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

void main() {
  group('TranscodeJob', () {
    test('toFFmpegArgs generates correct arguments', () {
      final job = TranscodeJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
        videoCodec: VideoCodec.h264,
        audioCodec: AudioCodec.aac,
      );

      final args = job.toFFmpegArgs();

      expect(args.contains('-i'), true);
      expect(args.contains('/input.mp4'), true);
      expect(args.contains('-c:v'), true);
      expect(args.contains('libx264'), true);
      expect(args.contains('-c:a'), true);
      expect(args.contains('aac'), true);
      expect(args.contains('/output.mp4'), true);
    });

    test('toFFmpegArgs includes preset if provided', () {
      final job = TranscodeJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
        preset: 'ultrafast',
      );

      final args = job.toFFmpegArgs();

      expect(args.contains('-preset'), true);
      expect(args.contains('ultrafast'), true);
    });

    test('toFFmpegArgs handles hardware acceleration flag (Android mock)', () {
      // Note: testing actual platform detection in unit test might be tricky
      // but we can verify the property is accepted by the constructor
      final job = TranscodeJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
        videoCodec: VideoCodec.h264,
        useHardwareAcceleration: true,
      );

      expect(job.useHardwareAcceleration, true);

      final args = job.toFFmpegArgs();
      // On most environments (like CI), Platform.isAndroid/iOS will be false
      // so it will fallback to libx264.
      // We'll verify it doesn't crash and contains the default codec at least.
      expect(args.contains('-c:v'), true);
    });

    test('validate returns true for valid job', () {
      final job = TranscodeJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
      );

      expect(job.validate(), true);
    });

    test('validate returns false for empty paths', () {
      final job = TranscodeJob(
        inputPath: '',
        outputPath: '/output.mp4',
      );

      expect(job.validate(), false);
    });

    test('toFFmpegArgs includes filters when provided', () {
      final job = TranscodeJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
        filters: const VideoFilters(
          rotation: VideoRotation.rotate90,
          brightness: 0.1,
        ),
      );

      final args = job.toFFmpegArgs();
      expect(args.contains('-vf'), true);
      final argsStr = args.join(' ');
      expect(argsStr.contains('transpose=1'), true);
      expect(argsStr.contains('eq=brightness=0.1'), true);
    });

    test('toFFmpegArgs includes watermark overlay', () {
      final job = TranscodeJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
        watermarkPath: '/logo.png',
        watermarkPosition: WatermarkPosition.topLeft,
      );

      final args = job.toFFmpegArgs();
      expect(args.contains('-filter_complex'), true);
      final argsStr = args.join(' ');
      expect(argsStr.contains('overlay=10:10'), true);
    });

    test('toFFmpegArgs adds faststart for MP4', () {
      final job = TranscodeJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
      );

      final args = job.toFFmpegArgs();
      expect(args.contains('-movflags'), true);
      expect(args.contains('+faststart'), true);
    });
  });

  group('TrimJob', () {
    test('toFFmpegArgs includes correct time parameters', () {
      final job = TrimJob(
        inputPath: '/input.mp4',
        outputPath: '/output.mp4',
        startTime: Duration(seconds: 10),
        duration: Duration(seconds: 30),
      );

      final args = job.toFFmpegArgs();

      expect(args.contains('-ss'), true);
      expect(args.contains('-t'), true);
      expect(args.contains('-c'), true);
      expect(args.contains('copy'), true);
    });
  });

  group('ThumbnailJob', () {
    test('toFFmpegArgs generates single frame output', () {
      final job = ThumbnailJob(
        videoPath: '/video.mp4',
        timePosition: Duration(seconds: 5),
        outputImagePath: '/thumb.jpg',
      );

      final args = job.toFFmpegArgs();

      expect(args.contains('-vframes'), true);
      expect(args.contains('1'), true);
    });
  });

  group('JobProgress', () {
    test('fromFFmpegOutput parses progress correctly', () {
      const line =
          'frame=  120 fps=30 q=28.0 size=   1234kB time=00:00:04.00 bitrate=2456.7kbits/s speed=1.00x';
      final totalDuration = Duration(seconds: 10);

      final progress =
          JobProgress.fromFFmpegOutput(line, totalDuration: totalDuration);

      expect(progress, isNotNull);
      expect(progress!.currentTime, Duration(seconds: 4));
      expect(progress.progress, closeTo(0.4, 0.01));
      expect(progress.currentFrame, 120);
      expect(progress.speed, 1.0);
    });

    test('fromFFmpegOutput returns null for non-progress lines', () {
      const line = 'Some random log message';

      final progress = JobProgress.fromFFmpegOutput(line);

      expect(progress, isNull);
    });
  });

  group('FormatPolicy', () {
    test('crossPlatform mode returns H.264/AAC recommendation', () {
      final policy = FormatPolicy(mode: FormatPolicyMode.crossPlatform);
      final recommendation = policy.getRecommendation();

      expect(recommendation.videoCodec, VideoCodec.h264);
      expect(recommendation.audioCodec, AudioCodec.aac);
      expect(recommendation.container, ContainerFormat.mp4);
    });

    test('compression mode returns H.265 recommendation', () {
      final policy = FormatPolicy(mode: FormatPolicyMode.compression);
      final recommendation = policy.getRecommendation();

      expect(recommendation.videoCodec, VideoCodec.h265);
    });
  });

  group('ProbeResult', () {
    test('fromJson parses FFprobe output correctly', () {
      final json = {
        'format': {
          'duration': '10.5',
          'format_name': 'mov,mp4,m4a,3gp,3g2,mj2',
          'size': '1048576',
          'bit_rate': '800000',
        },
        'streams': [
          {
            'codec_type': 'video',
            'codec_name': 'h264',
            'width': 1920,
            'height': 1080,
            'r_frame_rate': '30/1',
          },
          {
            'codec_type': 'audio',
            'codec_name': 'aac',
            'sample_rate': '48000',
            'channels': 2,
          },
        ],
      };

      final result = ProbeResult.fromJson('/test.mp4', json);

      expect(result.isVideo, true);
      expect(result.hasAudio, true);
      expect(result.videoStream?.width, 1920);
      expect(result.videoStream?.height, 1080);
      expect(result.videoStream?.codec, 'h264');
      expect(result.audioStream?.codec, 'aac');
    });
  });
}
