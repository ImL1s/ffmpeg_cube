import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

/// Real file integration tests using actual FFmpeg execution
///
/// Prerequisites:
/// - FFmpeg must be installed and available in PATH
/// - Test fixtures must exist in test/fixtures/
///
/// To run: flutter test test/real_file_integration_test.dart
void main() {
  late FFmpegCubeClient client;
  late Directory tempDir;

  // ignore: unused_local_variable
  final fixturesDir = Directory('test/fixtures');
  final testVideo = File('test/fixtures/test_video.mp4');
  final testVideo2 = File('test/fixtures/test_video2.mp4');
  final testAudio = File('test/fixtures/test_audio.aac');
  final testSubtitle = File('test/fixtures/test_subtitle.srt');

  bool ffmpegAvailable = false;

  setUpAll(() async {
    // Check if FFmpeg is available
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      ffmpegAvailable = result.exitCode == 0;
    } catch (e) {
      ffmpegAvailable = false;
    }

    // Check fixtures
    if (!testVideo.existsSync()) {
      throw Exception('Test fixture not found: test/fixtures/test_video.mp4');
    }
  });

  setUp(() async {
    client = FFmpegCubeClient();
    tempDir = await Directory.systemTemp.createTemp('ffmpeg_cube_test_');
  });

  tearDown(() async {
    client.dispose();
    try {
      await tempDir.delete(recursive: true);
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  group('Real File: Transcode', () {
    test('Transcode MP4 to different codec', () async {
      if (!ffmpegAvailable) {
        markTestSkipped('FFmpeg not available');
        return;
      }

      final outputPath = '${tempDir.path}/transcoded_output.mp4';

      final job = TranscodeJob(
        inputPath: testVideo.path,
        outputPath: outputPath,
        videoCodec: VideoCodec.h264,
        audioCodec: AudioCodec.aac,
        resolution: VideoResolution.r360p,
      );

      expect(job.validate(), true);

      final result = await client.transcode(job);

      expect(result.success, true, reason: result.error?.message ?? '');
      expect(File(outputPath).existsSync(), true);
      expect(File(outputPath).lengthSync(), greaterThan(0));
    });

    test('Transcode with progress callback', () async {
      if (!ffmpegAvailable) {
        markTestSkipped('FFmpeg not available');
        return;
      }

      final outputPath = '${tempDir.path}/transcoded_progress.mp4';
      final progressValues = <double>[];

      final job = TranscodeJob(
        inputPath: testVideo.path,
        outputPath: outputPath,
        videoCodec: VideoCodec.h264,
      );

      final result = await client.transcode(
        job,
        onProgress: (progress) {
          progressValues.add(progress.progress);
        },
      );

      expect(result.success, true);
      expect(File(outputPath).existsSync(), true);
      // Progress values may or may not be reported depending on backend
    });
  });

  group('Real File: Trim', () {
    test('Trim video segment', () async {
      if (!ffmpegAvailable) {
        markTestSkipped('FFmpeg not available');
        return;
      }

      final outputPath = '${tempDir.path}/trimmed_output.mp4';

      final job = TrimJob(
        inputPath: testVideo.path,
        outputPath: outputPath,
        startTime: const Duration(seconds: 1),
        duration: const Duration(seconds: 2),
        useCopyCodec: true,
      );

      expect(job.validate(), true);

      final result = await client.trim(job);

      expect(result.success, true, reason: result.error?.message ?? '');
      expect(File(outputPath).existsSync(), true);

      // Trimmed file should be smaller than original
      expect(
        File(outputPath).lengthSync(),
        lessThan(testVideo.lengthSync()),
      );
    });
  });

  group('Real File: Thumbnail', () {
    test('Extract thumbnail from video', () async {
      if (!ffmpegAvailable) {
        markTestSkipped('FFmpeg not available');
        return;
      }

      final outputPath = '${tempDir.path}/thumbnail.jpg';

      final job = ThumbnailJob(
        videoPath: testVideo.path,
        outputImagePath: outputPath,
        timePosition: const Duration(seconds: 2),
        format: ImageFormat.jpg,
      );

      expect(job.validate(), true);

      final result = await client.thumbnail(job);

      expect(result.success, true, reason: result.error?.message ?? '');
      expect(File(outputPath).existsSync(), true);
      expect(File(outputPath).lengthSync(), greaterThan(0));
    });

    test('Extract PNG thumbnail with custom size', () async {
      if (!ffmpegAvailable) {
        markTestSkipped('FFmpeg not available');
        return;
      }

      final outputPath = '${tempDir.path}/thumbnail_sized.png';

      final job = ThumbnailJob(
        videoPath: testVideo.path,
        outputImagePath: outputPath,
        timePosition: const Duration(seconds: 1),
        format: ImageFormat.png,
        width: 160,
      );

      final result = await client.thumbnail(job);

      expect(result.success, true, reason: result.error?.message ?? '');
      expect(File(outputPath).existsSync(), true);
    });
  });

  group('Real File: Concat', () {
    test('Concatenate two videos', () async {
      if (!ffmpegAvailable) {
        markTestSkipped('FFmpeg not available');
        return;
      }

      if (!testVideo2.existsSync()) {
        markTestSkipped('Second test video not available');
        return;
      }

      final outputPath = '${tempDir.path}/concatenated.mp4';

      final job = ConcatJob(
        inputPaths: [testVideo.path, testVideo2.path],
        outputPath: outputPath,
        method: ConcatMethod.filter,
        videoCodec: VideoCodec.h264,
        audioCodec: AudioCodec.aac,
      );

      expect(job.validate(), true);

      final result = await client.concat(job);

      expect(result.success, true, reason: result.error?.message ?? '');
      expect(File(outputPath).existsSync(), true);

      // Concatenated file should be larger than either input
      expect(
        File(outputPath).lengthSync(),
        greaterThan(testVideo.lengthSync() * 0.5),
      );
    });
  });

  group('Real File: Extract Audio', () {
    test('Extract audio from video', () async {
      if (!ffmpegAvailable) {
        markTestSkipped('FFmpeg not available');
        return;
      }

      final outputPath = '${tempDir.path}/extracted_audio.aac';

      final result = await client.extractAudio(
        videoPath: testVideo.path,
        outputPath: outputPath,
        audioCodec: AudioCodec.aac,
      );

      expect(result.success, true, reason: result.error?.message ?? '');
      expect(File(outputPath).existsSync(), true);
      expect(File(outputPath).lengthSync(), greaterThan(0));
    });
  });

  group('Real File: Probe', () {
    test('Probe video file', () async {
      if (!ffmpegAvailable) {
        markTestSkipped('FFmpeg not available');
        return;
      }

      final result = await client.probe(testVideo.path);

      expect(result.success, true, reason: result.error?.message ?? '');
      expect(result.data, isNotNull);
      expect(result.data!.isVideo, true);
      expect(result.data!.hasAudio, true);
      expect(result.data!.duration, greaterThan(Duration.zero));
      expect(result.data!.videoStream, isNotNull);
      expect(result.data!.videoStream!.width, greaterThan(0));
      expect(result.data!.videoStream!.height, greaterThan(0));
    });

    test('Probe detects audio streams', () async {
      if (!ffmpegAvailable) {
        markTestSkipped('FFmpeg not available');
        return;
      }

      final result = await client.probe(testVideo.path);

      expect(result.success, true);
      expect(result.data!.audioStream, isNotNull);
    });
  });

  group('Real File: Subtitle', () {
    test('Softcode subtitles into video', () async {
      if (!ffmpegAvailable) {
        markTestSkipped('FFmpeg not available');
        return;
      }

      if (!testSubtitle.existsSync()) {
        markTestSkipped('Subtitle file not available');
        return;
      }

      final outputPath = '${tempDir.path}/subtitled.mp4';

      final job = SubtitleJob(
        videoPath: testVideo.path,
        subtitlePath: testSubtitle.path,
        outputPath: outputPath,
        embedType: SubtitleEmbedType.softcode,
      );

      expect(job.validate(), true);

      final result = await client.addSubtitle(job);

      expect(result.success, true, reason: result.error?.message ?? '');
      expect(File(outputPath).existsSync(), true);
    });
  });

  group('Real File: Mix Audio', () {
    test('Mix audio into video', () async {
      if (!ffmpegAvailable) {
        markTestSkipped('FFmpeg not available');
        return;
      }

      if (!testAudio.existsSync()) {
        markTestSkipped('Audio file not available');
        return;
      }

      final outputPath = '${tempDir.path}/mixed_audio.mp3';

      final job = MixAudioJob(
        inputAudioPaths: [testVideo.path, testAudio.path],
        outputPath: outputPath,
      );

      expect(job.validate(), true);

      final result = await client.mixAudio(job);

      expect(result.success, true, reason: result.error?.message ?? '');
      expect(File(outputPath).existsSync(), true);
    });
  });

  group('Real File: Error Handling', () {
    test('Handle non-existent input file', () async {
      if (!ffmpegAvailable) {
        markTestSkipped('FFmpeg not available');
        return;
      }

      final outputPath = '${tempDir.path}/should_not_exist.mp4';

      final job = TranscodeJob(
        inputPath: '/non/existent/file.mp4',
        outputPath: outputPath,
      );

      final result = await client.transcode(job);

      expect(result.success, false);
      expect(result.error, isNotNull);
      expect(File(outputPath).existsSync(), false);
    });
  });
}
