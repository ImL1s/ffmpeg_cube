import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Standalone implementation for multi-file selection
class ConcatScreen extends StatefulWidget {
  const ConcatScreen({super.key});

  @override
  State<ConcatScreen> createState() => _ConcatScreenState();
}

class _ConcatScreenState extends State<ConcatScreen> {
  final FFmpegCubeClient client = FFmpegCubeClient();
  List<String> inputPaths = [];
  String? outputPath;
  bool isProcessing = false;
  JobProgress? currentProgress;
  String? errorMessage;
  ConcatMethod method = ConcatMethod.demuxer;

  Future<void> pickInputFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        inputPaths = result.paths.whereType<String>().toList();
        outputPath = null;
        errorMessage = null;
      });
    }
  }

  Future<void> executeJob() async {
    if (inputPaths.isEmpty) return;

    setState(() {
      isProcessing = true;
      errorMessage = null;
      currentProgress = null;
    });

    try {
      final dir = await getTemporaryDirectory();
      final out = p.join(
          dir.path, 'concat_${DateTime.now().millisecondsSinceEpoch}.mp4');

      final job = ConcatJob(
        inputPaths: inputPaths,
        outputPath: out,
        method: method,
      );

      final result = await client.concat(
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
      appBar: AppBar(title: const Text('Concat')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input List
            Text('Input Files', style: Theme.of(context).textTheme.titleSmall),
            const Gap(8),
            Card(
              child: Column(
                children: [
                  ...inputPaths.map((path) => ListTile(
                        leading: const Icon(Icons.movie),
                        title: Text(path.split(Platform.pathSeparator).last),
                        subtitle: Text(path,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => inputPaths.remove(path)),
                        ),
                      )),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Add Files'),
                    onTap: pickInputFiles,
                  ),
                ],
              ),
            ),
            const Gap(16),

            // Config
            Text('Configuration',
                style: Theme.of(context).textTheme.titleSmall),
            const Gap(8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<ConcatMethod>(
                      decoration: const InputDecoration(labelText: 'Method'),
                      initialValue: method,
                      items: ConcatMethod.values
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e.name)))
                          .toList(),
                      onChanged: (v) => setState(() => method = v!),
                    ),
                    const Gap(8),
                    const Text(
                        'Demuxer: Fast, no re-encode (requires same codec)\n'
                        'Filter: Slow, re-encode (supports any inputs)',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const Gap(24),

            // Action
            if (isProcessing) ...[
              LinearProgressIndicator(value: currentProgress?.progress),
              Text(currentProgress != null
                  ? '${(currentProgress!.progress * 100).toStringAsFixed(1)}%'
                  : 'Processing...'),
            ] else
              ElevatedButton.icon(
                onPressed: inputPaths.length < 2 ? null : executeJob,
                icon: const Icon(Icons.merge_type),
                label: const Text('Merge Files'),
              ),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(errorMessage!,
                    style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
