import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class SubtitleScreen extends StatefulWidget {
  const SubtitleScreen({super.key});

  @override
  State<SubtitleScreen> createState() => _SubtitleScreenState();
}

class _SubtitleScreenState extends State<SubtitleScreen> {
  final FFmpegCubeClient client = FFmpegCubeClient();
  String? videoPath;
  String? subtitlePath;
  String? outputPath;
  bool isProcessing = false;
  JobProgress? currentProgress;
  String? errorMessage;

  SubtitleEmbedType embedType = SubtitleEmbedType.hardcode;

  Future<void> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) setState(() => videoPath = result.files.single.path);
  }

  Future<void> pickSubtitle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'ass', 'vtt'],
    );
    if (result != null) setState(() => subtitlePath = result.files.single.path);
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
          dir.path, 'subbed_${DateTime.now().millisecondsSinceEpoch}.mp4');

      final job = SubtitleJob(
        videoPath: videoPath!,
        subtitlePath: subtitlePath!,
        outputPath: out,
        embedType: embedType,
      );

      final result = await client.addSubtitle(
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
      appBar: AppBar(title: const Text('Subtitle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFileCard('Video File', videoPath, Icons.movie, pickVideo),
            const Gap(16),
            _buildFileCard(
                'Subtitle File', subtitlePath, Icons.subtitles, pickSubtitle),
            const Gap(16),

            // Config
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<SubtitleEmbedType>(
                      decoration:
                          const InputDecoration(labelText: 'Embed Type'),
                      initialValue: embedType,
                      items: SubtitleEmbedType.values
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e.name)))
                          .toList(),
                      onChanged: (v) => setState(() => embedType = v!),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(24),

            if (isProcessing) ...[
              LinearProgressIndicator(value: currentProgress?.progress),
              Text('Processing...'),
            ] else
              ElevatedButton.icon(
                onPressed: (videoPath != null && subtitlePath != null)
                    ? executeJob
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Burn/Embed Subtitles'),
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
