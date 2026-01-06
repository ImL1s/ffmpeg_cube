// ignore_for_file: avoid_print
import 'dart:io';

/// Script to generate test fixtures for integration tests
///
/// Usage: dart tool/generate_fixtures.dart
void main() async {
  print('Generating test fixtures...');

  final fixturesDir = Directory('test/fixtures');
  if (!fixturesDir.existsSync()) {
    fixturesDir.createSync(recursive: true);
  }

  // Check for FFmpeg
  bool ffmpegAvailable = false;
  try {
    final result = await Process.run('ffmpeg', ['-version']);
    if (result.exitCode == 0) {
      ffmpegAvailable = true;
      print('FFmpeg found: ${result.stdout.toString().split('\n').first}');
    }
  } catch (e) {
    print('FFmpeg check failed: $e');
  }

  if (!ffmpegAvailable) {
    print('Error: FFmpeg not found in PATH. Cannot generate fixtures.');
    exit(1);
  }

  // 1. Generate Video 1 (640x360, H.264, AAC)
  print('Generating test_video.mp4...');
  await _runFFmpeg([
    '-y',
    '-f',
    'lavfi',
    '-i',
    'testsrc=duration=5:size=640x360:rate=30',
    '-f',
    'lavfi',
    '-i',
    'sine=frequency=440:duration=5',
    '-c:v',
    'libx264',
    '-preset',
    'ultrafast',
    '-c:a',
    'aac',
    '-b:a',
    '128k',
    'test/fixtures/test_video.mp4'
  ]);

  // 2. Generate Video 2 (640x360, H.264, AAC) - Same resolution for concat
  print('Generating test_video2.mp4...');
  await _runFFmpeg([
    '-y',
    '-f',
    'lavfi',
    '-i',
    'testsrc=duration=3:size=640x360:rate=30',
    '-f',
    'lavfi',
    '-i',
    'sine=frequency=660:duration=3',
    '-c:v',
    'libx264',
    '-preset',
    'ultrafast',
    '-c:a',
    'aac',
    '-b:a',
    '128k',
    'test/fixtures/test_video2.mp4'
  ]);

  // 3. Generate Audio (AAC)
  print('Generating test_audio.aac...');
  await _runFFmpeg([
    '-y',
    '-f',
    'lavfi',
    '-i',
    'sine=frequency=880:duration=3',
    '-c:a',
    'aac',
    '-b:a',
    '128k',
    'test/fixtures/test_audio.aac'
  ]);

  // 4. Generate Subtitle (SRT)
  print('Generating test_subtitle.srt...');
  final srtContent = '''
1
00:00:00,000 --> 00:00:02,000
Test subtitle line 1

2
00:00:02,000 --> 00:00:04,000
Test subtitle line 2

3
00:00:04,000 --> 00:00:05,000
Test subtitle line 3
''';
  File('test/fixtures/test_subtitle.srt').writeAsStringSync(srtContent);

  print('Fixtures generated successfully.');
}

Future<void> _runFFmpeg(List<String> args) async {
  final result = await Process.run('ffmpeg', args);
  if (result.exitCode != 0) {
    print('FFmpeg failed: ${result.stderr}');
    exit(1);
  }
}
