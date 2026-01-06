import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MixAudioScreen extends StatefulWidget {
  const MixAudioScreen({super.key});

  @override
  State<MixAudioScreen> createState() => _MixAudioScreenState();
}

class _MixAudioScreenState extends State<MixAudioScreen> {
  final FFmpegCubeClient client = FFmpegCubeClient();
  String? videoPath;
  String? audioPath;
  String? outputPath;
  bool isProcessing = false;
  JobProgress? currentProgress;
  String? errorMessage;

  double videoVolume = 1.0;
  double audioVolume = 0.5;

  Future<void> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) setState(() => videoPath = result.files.single.path);
  }

  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) setState(() => audioPath = result.files.single.path);
  }

  Future<void> executeJob() async {
    setState(() {
      isProcessing = true;
      errorMessage = null;
      currentProgress = null;
    });

    try {
      final dir = await getTemporaryDirectory();
      final out = p.join(
          dir.path, 'mixed_${DateTime.now().millisecondsSinceEpoch}.mp4');

      final job = MixAudioJob(
        inputAudioPaths: [
          videoPath!,
          audioPath!
        ], // Video is also an input with audio stream
        outputPath: out,
        volumes: [videoVolume, audioVolume],
      );

      final result = await client.mixAudio(
        job,
        onProgress: (p) => setState(() => currentProgress = p),
      );

      if (result.success) {
        setState(() => outputPath = out);
      } else {
        throw result.error?.message ?? 'Unknown error';
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mix Audio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFileCard('Main Video', videoPath, Icons.movie, pickVideo),
            if (videoPath != null)
              _buildVolumeSlider(
                  'Video Volume', videoVolume, (v) => videoVolume = v),
            const Gap(16),
            _buildFileCard(
                'Background Audio', audioPath, Icons.music_note, pickAudio),
            if (audioPath != null)
              _buildVolumeSlider(
                  'Audio Volume', audioVolume, (v) => audioVolume = v),
            const Gap(24),
            if (isProcessing) ...[
              LinearProgressIndicator(value: currentProgress?.progress),
              Text('Processing...'),
            ] else
              ElevatedButton.icon(
                onPressed: (videoPath != null && audioPath != null)
                    ? executeJob
                    : null,
                icon: const Icon(Icons.graphic_eq),
                label: const Text('Mix Audio Tracks'),
              ),
            if (outputSection != null) outputSection!,
            if (errorMessage != null)
              Padding(
                  padding: EdgeInsets.all(8),
                  child:
                      Text(errorMessage!, style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(
      String title, String? path, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(path != null
            ? path.split(Platform.pathSeparator).last
            : 'Select $title'),
        subtitle: path != null ? Text(path) : null,
        trailing:
            IconButton(icon: const Icon(Icons.folder_open), onPressed: onTap),
      ),
    );
  }

  Widget _buildVolumeSlider(
      String label, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text('$label: ${(value * 100).toInt()}%'),
          Expanded(
            child: Slider(
              value: value,
              min: 0,
              max: 2.0,
              divisions: 20,
              onChanged: (v) => setState(() => onChanged(v)),
            ),
          ),
        ],
      ),
    );
  }

  Widget? get outputSection {
    if (outputPath == null) return null;
    return Column(
      children: [
        const Gap(24),
        const Text('Output', style: TextStyle(fontWeight: FontWeight.bold)),
        Card(
          color: Colors.green.shade50,
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(outputPath!.split(Platform.pathSeparator).last),
            subtitle: Text(outputPath!),
          ),
        )
      ],
    );
  }
}
