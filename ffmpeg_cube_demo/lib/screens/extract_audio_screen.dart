import 'package:flutter/material.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'base_job_screen.dart';

class ExtractAudioScreen extends BaseJobScreen {
  const ExtractAudioScreen({super.key});

  @override
  State<ExtractAudioScreen> createState() => _ExtractAudioScreenState();
}

class _ExtractAudioScreenState extends BaseJobScreenState<ExtractAudioScreen> {
  AudioCodec audioCodec = AudioCodec.mp3;
  String bitrate = '128k';

  @override
  String get title => 'Extract Audio';

  @override
  Widget buildConfigSection(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<AudioCodec>(
          decoration: const InputDecoration(labelText: 'Output Format'),
          initialValue: audioCodec,
          items: AudioCodec.values.map((e) => DropdownMenuItem(
            value: e, child: Text(e.name))).toList(),
          onChanged: (v) => setState(() => audioCodec = v!),
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Bitrate (e.g. 128k, 320k)'),
          initialValue: bitrate,
          onChanged: (v) => bitrate = v,
        ),
      ],
    );
  }

  @override
  Future<void> executeJob() async {
    final dir = await getTemporaryDirectory();
    // Simple extension mapping
    final ext = audioCodec == AudioCodec.aac ? 'm4a' : audioCodec.name;
    final out = p.join(dir.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.$ext');
    
    // Using transcode under the hood mostly, or specific method if available
    // FFmpegCubeClient has extractAudio convenience method
    
    final result = await client.extractAudio(
      videoPath: inputPath!,
      outputPath: out,
      audioCodec: audioCodec,
      bitrate: bitrate,
    );

    if (result.success) {
      setState(() {
        outputPath = out;
        currentProgress = JobProgress(progress: 1.0, totalDuration: Duration.zero);
      });
    } else {
      throw result.error?.message ?? 'Unknown error';
    }
  }
}
