import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

/// FFmpegCubeClient 端對端測試
void main() {
  group('E2E: Transcode Workflow', () {
    late FFmpegCubeClient client;

    setUp(() {
      client = FFmpegCubeClient();
    });

    tearDown(() {
      client.dispose();
    });

    test('Create transcode job with default settings', () {
      final job = TranscodeJob(
        inputPath: '/videos/input.mp4',
        outputPath: '/videos/output.mp4',
      );

      expect(job.validate(), true);
      expect(job.id, isNotEmpty);
    });

    test('Create transcode job with custom codec', () {
      final recommendation = client.getRecommendation();
      
      final job = TranscodeJob(
        inputPath: '/videos/input.mp4',
        outputPath: '/videos/output.mp4',
        videoCodec: recommendation.videoCodec,
        audioCodec: recommendation.audioCodec,
      );

      expect(job.validate(), true);
    });

    test('Full transcode workflow generates valid args', () {
      final job = TranscodeJob(
        inputPath: '/videos/input.mp4',
        outputPath: '/videos/output.mp4',
        videoCodec: VideoCodec.h264,
        audioCodec: AudioCodec.aac,
        resolution: VideoResolution.r720p,
      );

      expect(job.validate(), true);
      
      final args = job.toFFmpegArgs();
      expect(args.length, greaterThan(5));
      expect(args.contains('-y'), true);
    });
  });

  group('E2E: Trim Workflow', () {
    test('Create trim job with duration', () {
      final job = TrimJob(
        inputPath: '/videos/long_video.mp4',
        outputPath: '/videos/clip.mp4',
        startTime: const Duration(minutes: 1, seconds: 30),
        duration: const Duration(seconds: 45),
      );

      expect(job.validate(), true);
      
      final args = job.toFFmpegArgs();
      expect(args.contains('-ss'), true);
      expect(args.contains('-t'), true);
    });

    test('Trim job with copy codec', () {
      final job = TrimJob(
        inputPath: '/videos/input.mp4',
        outputPath: '/videos/output.mp4',
        startTime: Duration.zero,
        duration: const Duration(seconds: 30),
        useCopyCodec: true,
      );

      final args = job.toFFmpegArgs();
      expect(args.contains('-c'), true);
      expect(args.contains('copy'), true);
    });
  });

  group('E2E: Thumbnail Workflow', () {
    test('Extract single thumbnail', () {
      final job = ThumbnailJob(
        videoPath: '/videos/movie.mp4',
        timePosition: const Duration(seconds: 30),
        outputImagePath: '/thumbnails/poster.jpg',
        format: ImageFormat.jpg,
      );

      expect(job.validate(), true);
      
      final args = job.toFFmpegArgs();
      expect(args.contains('-vframes'), true);
    });

    test('Extract thumbnail with custom size', () {
      final job = ThumbnailJob(
        videoPath: '/videos/movie.mp4',
        timePosition: const Duration(seconds: 10),
        outputImagePath: '/thumbnails/thumb.png',
        format: ImageFormat.png,
        width: 320,
      );

      expect(job.validate(), true);
    });
  });

  group('E2E: Concat Workflow', () {
    test('Concatenate two videos', () {
      final job = ConcatJob(
        inputPaths: ['/videos/part1.mp4', '/videos/part2.mp4'],
        outputPath: '/videos/complete.mp4',
      );

      expect(job.validate(), true);
    });

    test('Concatenate with filter method', () {
      final job = ConcatJob(
        inputPaths: ['/videos/clip1.mp4', '/videos/clip2.mp4'],
        outputPath: '/videos/compilation.mp4',
        method: ConcatMethod.filter,
        videoCodec: VideoCodec.h264,
        audioCodec: AudioCodec.aac,
      );

      expect(job.validate(), true);
      
      final args = job.toFFmpegArgs();
      expect(args.contains('-filter_complex'), true);
    });
  });

  group('E2E: Audio Mix Workflow', () {
    test('Mix two audio tracks', () {
      final job = MixAudioJob(
        inputAudioPaths: ['/audio/track1.mp3', '/audio/track2.mp3'],
        outputPath: '/audio/mixed.mp3',
      );

      expect(job.validate(), true);
    });

    test('Mix with volume control', () {
      final job = MixAudioJob(
        inputAudioPaths: ['/audio/music.mp3', '/audio/voice.mp3'],
        outputPath: '/audio/podcast.mp3',
        volumes: [0.3, 1.0],
      );

      expect(job.validate(), true);
    });
  });

  group('E2E: Subtitle Workflow', () {
    test('Hardcode subtitles', () {
      final job = SubtitleJob(
        videoPath: '/videos/movie.mp4',
        subtitlePath: '/subtitles/english.srt',
        outputPath: '/videos/movie_subbed.mp4',
        embedType: SubtitleEmbedType.hardcode,
      );

      expect(job.validate(), true);
      
      final args = job.toFFmpegArgs();
      expect(args.any((a) => a.contains('subtitle')), true);
    });

    test('Softcode subtitles', () {
      final job = SubtitleJob(
        videoPath: '/videos/movie.mp4',
        subtitlePath: '/subtitles/english.srt',
        outputPath: '/videos/movie.mkv',
        embedType: SubtitleEmbedType.softcode,
      );

      expect(job.validate(), true);
    });
  });

  group('E2E: Probe Workflow', () {
    test('Parse video probe result', () {
      final json = {
        'format': {
          'duration': '7200.5',
          'format_name': 'mov,mp4',
          'size': '2147483648',
          'bit_rate': '2500000',
        },
        'streams': [
          {
            'codec_type': 'video',
            'codec_name': 'h264',
            'width': 3840,
            'height': 2160,
            'r_frame_rate': '60/1',
          },
          {
            'codec_type': 'audio',
            'codec_name': 'ac3',
            'sample_rate': '48000',
            'channels': 6,
          },
          {
            'codec_type': 'subtitle',
            'codec_name': 'subrip',
          },
        ],
      };

      final result = ProbeResult.fromJson('/movies/4k_movie.mp4', json);

      expect(result.isVideo, true);
      expect(result.hasAudio, true);
      expect(result.subtitleStreams.length, 1);
      expect(result.videoStream?.width, 3840);
    });
  });

  group('E2E: Error Handling', () {
    test('Handle invalid job', () {
      final job = TranscodeJob(inputPath: '', outputPath: '');
      expect(job.validate(), false);
    });

    test('JobResult handles success and failure', () {
      final success = JobResult<String>.success(data: 'done');
      final failure = JobResult<String>.failure(JobError.validation('Bad'));

      expect(success.success, true);
      expect(failure.success, false);
    });
  });

  group('E2E: Policy Engine', () {
    test('Different policy modes', () {
      final crossPlatform = FormatPolicy(mode: FormatPolicyMode.crossPlatform);
      final quality = FormatPolicy(mode: FormatPolicyMode.quality);
      final compression = FormatPolicy(mode: FormatPolicyMode.compression);
      final speed = FormatPolicy(mode: FormatPolicyMode.speed);

      expect(crossPlatform.getRecommendation().videoCodec, VideoCodec.h264);
      expect(quality.getRecommendation().videoCodec, VideoCodec.h265);
      expect(compression.getRecommendation().audioCodec, AudioCodec.opus);
      expect(speed.getRecommendation().videoCodec, VideoCodec.copy);
    });

    test('Web target adjustments', () {
      final policy = FormatPolicy(mode: FormatPolicyMode.compression);
      final webRec = policy.getRecommendation(isWebTarget: true);

      expect(webRec.container, ContainerFormat.webm);
    });

    test('Custom policy', () {
      final custom = CodecRecommendation(
        videoCodec: VideoCodec.vp9,
        audioCodec: AudioCodec.opus,
        container: ContainerFormat.webm,
      );
      
      final policy = FormatPolicy(
        mode: FormatPolicyMode.custom,
        customRecommendation: custom,
      );

      final rec = policy.getRecommendation();
      expect(rec.videoCodec, VideoCodec.vp9);
    });
  });
}
