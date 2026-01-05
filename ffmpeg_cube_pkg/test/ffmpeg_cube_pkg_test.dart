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
      const line = 'frame=  120 fps=30 q=28.0 size=   1234kB time=00:00:04.00 bitrate=2456.7kbits/s speed=1.00x';
      final totalDuration = Duration(seconds: 10);
      
      final progress = JobProgress.fromFFmpegOutput(line, totalDuration: totalDuration);
      
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
