import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

/// JobProgress 完整測試
void main() {
  group('JobProgress Basic Properties', () {
    test('Create progress with all properties', () {
      final progress = JobProgress(
        progress: 0.5,
        totalDuration: const Duration(minutes: 10),
        currentTime: const Duration(minutes: 5),
        currentFrame: 9000,
        speed: 1.5,
        currentSize: 52428800, // 50MB
        bitrate: 5000000,
      );

      expect(progress.progress, 0.5);
      expect(progress.progressPercent, 50);
      expect(progress.currentFrame, 9000);
      expect(progress.speed, 1.5);
      expect(progress.currentSize, 52428800);
    });

    test('Progress percentage calculation', () {
      final progress25 = JobProgress(progress: 0.25);
      final progress75 = JobProgress(progress: 0.75);
      final progress100 = JobProgress(progress: 1.0);

      expect(progress25.progressPercent, 25);
      expect(progress75.progressPercent, 75);
      expect(progress100.progressPercent, 100);
    });

    test('Estimated time remaining from parsed output', () {
      // Use a progress line that will be parsed with speed
      const line =
          'frame= 300 fps=30 q=28.0 size=   1000kB time=00:00:30.00 bitrate=1000.0kbits/s speed=1.00x';
      final duration = const Duration(minutes: 1);

      final progress =
          JobProgress.fromFFmpegOutput(line, totalDuration: duration);

      expect(progress, isNotNull);
      final remaining = progress!.estimatedTimeRemaining;
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, closeTo(30, 5)); // ~30 seconds remaining
    });
  });

  group('JobProgress FFmpeg Parsing', () {
    test('Parse complete progress line', () {
      const line =
          'frame= 1500 fps=59.9 q=28.0 size=   25600kB time=00:00:50.00 bitrate=4198.2kbits/s dup=0 drop=0 speed=2.00x';
      final duration = const Duration(minutes: 2);

      final progress =
          JobProgress.fromFFmpegOutput(line, totalDuration: duration);

      expect(progress, isNotNull);
      expect(progress!.currentFrame, 1500);
      expect(progress.currentTime?.inSeconds, 50);
      expect(progress.speed, 2.0);
    });

    test('Parse progress with milliseconds', () {
      const line =
          'frame=   30 fps=30 q=23.0 size=     256kB time=00:00:01.00 bitrate=2097.2kbits/s speed=1.00x';

      final progress = JobProgress.fromFFmpegOutput(line);

      expect(progress, isNotNull);
      expect(progress!.currentFrame, 30);
      expect(progress.currentTime?.inSeconds, 1);
    });

    test('Parse progress with hours', () {
      const line =
          'frame=108000 fps=60 q=25.0 size= 1024000kB time=01:30:00.00 bitrate=1500.0kbits/s speed=1.50x';
      final duration = const Duration(hours: 2);

      final progress =
          JobProgress.fromFFmpegOutput(line, totalDuration: duration);

      expect(progress, isNotNull);
      expect(progress!.currentTime?.inHours, 1);
      expect(progress.currentTime?.inMinutes, 90);
    });

    test('Return null for non-progress lines', () {
      final nonProgressLines = [
        'Input #0, mov,mp4,m4a,3gp,3g2,mj2, from "input.mp4":',
        'Duration: 00:10:00.00, start: 0.000000, bitrate: 5000 kb/s',
        'Stream #0:0(und): Video: h264 (High)',
        'ffmpeg version 5.1.2',
        '',
        'Press [q] to stop, [?] for help',
      ];

      for (final line in nonProgressLines) {
        final progress = JobProgress.fromFFmpegOutput(line);
        expect(progress, isNull, reason: 'Line should not parse: $line');
      }
    });

    test('Handle malformed progress line gracefully', () {
      const malformedLines = [
        'frame=abc fps=30',
        'time=invalid',
        'frame=100 time=',
      ];

      for (final line in malformedLines) {
        // Should not throw, may return null or partial data
        // ignore: unused_local_variable
        final progress = JobProgress.fromFFmpegOutput(line);
        // Just verify no exception is thrown
        expect(true, true);
      }
    });
  });

  group('JobProgress String Representation', () {
    test('progressString format', () {
      final progress = JobProgress(
        progress: 0.5,
        currentTime: const Duration(minutes: 5, seconds: 30),
        currentFrame: 9900,
        speed: 1.25,
      );

      final str = progress.progressString;
      expect(str.contains('50'), true); // 50%
    });
  });
}
