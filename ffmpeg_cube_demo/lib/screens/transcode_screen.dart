import 'package:flutter/material.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'base_job_screen.dart';

class TranscodeScreen extends BaseJobScreen {
  const TranscodeScreen({super.key});

  @override
  State<TranscodeScreen> createState() => _TranscodeScreenState();
}

class _TranscodeScreenState extends BaseJobScreenState<TranscodeScreen> {
  VideoCodec videoCodec = VideoCodec.h264;
  AudioCodec audioCodec = AudioCodec.aac;
  VideoResolution resolution = VideoResolution.r720p;
  String containerFormat = 'mp4';
  
  // New options
  String? preset; // e.g., ultrafast, medium
  bool useHardwareAcceleration = false;
  
  final List<String> presetOptions = [
    'ultrafast',
    'superfast',
    'veryfast',
    'faster',
    'fast',
    'medium', // default
    'slow',
    'slower',
    'veryslow',
  ];

  @override
  String get title => 'Transcode';

  @override
  Widget buildConfigSection(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<VideoCodec>(
          decoration: const InputDecoration(labelText: 'Video Codec'),
          initialValue: videoCodec,
          items: VideoCodec.values
              .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
              .toList(),
          onChanged: (v) => setState(() => videoCodec = v!),
        ),
        DropdownButtonFormField<AudioCodec>(
          decoration: const InputDecoration(labelText: 'Audio Codec'),
          initialValue: audioCodec,
          items: AudioCodec.values
              .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
              .toList(),
          onChanged: (v) => setState(() => audioCodec = v!),
        ),
        DropdownButtonFormField<VideoResolution>(
          decoration: const InputDecoration(labelText: 'Resolution'),
          initialValue: resolution,
          items: VideoResolution.values
              .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
              .toList(),
          onChanged: (v) => setState(() => resolution = v!),
        ),
        
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Preset (Speed vs Quality)'),
          initialValue: preset ?? 'medium',
          items: presetOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => preset = v),
        ),
        
        SwitchListTile(
          title: const Text('Hardware Acceleration'),
          subtitle: const Text('Try to use hardware encoders if available'),
          value: useHardwareAcceleration,
          onChanged: (v) => setState(() => useHardwareAcceleration = v),
        ),
      ],
    );
  }

  @override
  Future<void> executeJob() async {
    final dir = await getTemporaryDirectory();
    final out = p.join(dir.path,
        'transcoded_${DateTime.now().millisecondsSinceEpoch}.$containerFormat');

    final job = TranscodeJob(
      inputPath: inputPath!,
      outputPath: out,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      resolution: resolution,
      preset: preset,
      useHardwareAcceleration: useHardwareAcceleration,
    );

    final result = await client.transcode(
      job,
      onProgress: (p) => setState(() => currentProgress = p),
    );

    if (result.success) {
      setState(() => outputPath = out);
    } else {
      throw result.error?.message ?? 'Unknown error';
    }
  }
}
