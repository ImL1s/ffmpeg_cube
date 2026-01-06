import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class BaseJobScreen extends StatefulWidget {
  const BaseJobScreen({super.key});
}

abstract class BaseJobScreenState<T extends BaseJobScreen> extends State<T> {
  String? inputPath;
  String? outputPath;
  bool isProcessing = false;
  JobProgress? currentProgress;
  String? errorMessage;
  final FFmpegCubeClient client = FFmpegCubeClient();
  
  // Custom config widgets for child classes to implement
  Widget buildConfigSection(BuildContext context);
  
  // The actual job execution logic
  Future<void> executeJob();

  String get title;
  
  // Permission handling
  Future<bool> checkPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
       if (await Permission.storage.request().isGranted) return true;
       if (await Permission.photos.request().isGranted) return true;
       if (await Permission.videos.request().isGranted) return true;
       return false;
    }
    return true;
  }

  Future<void> pickInputFile() async {
    if (!await checkPermission()) {
      setState(() => errorMessage = 'Permission denied');
      return;
    }
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        inputPath = result.files.single.path;
        outputPath = null; // Reset output
        errorMessage = null;
        currentProgress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Input Section
            _buildSectionHeader('Input File'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.file_present),
                title: Text(inputPath != null 
                    ? inputPath!.split(Platform.pathSeparator).last 
                    : 'Select a file'),
                subtitle: inputPath != null ? Text(inputPath!) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: isProcessing ? null : pickInputFile,
                ),
              ),
            ),
            const Gap(16),

            // 2. Configuration Section (Abstract)
            _buildSectionHeader('Configuration'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: buildConfigSection(context),
              ),
            ),
            const Gap(24),
            
            // 3. Action Section
            if (isProcessing) ...[
              LinearProgressIndicator(
                value: currentProgress?.progress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const Gap(8),
              if (currentProgress != null)
                Text(
                  'Progress: ${(currentProgress!.progress * 100).toStringAsFixed(1)}% | '
                  'Speed: ${currentProgress!.speed}x | '
                  'Time: ${currentProgress!.currentTime} / ${currentProgress!.totalDuration}',
                   style: Theme.of(context).textTheme.bodySmall,
                   textAlign: TextAlign.center,
                ),
            ] else 
              ElevatedButton.icon(
                onPressed: inputPath == null ? null : () async {
                  setState(() {
                    isProcessing = true;
                    errorMessage = null;
                    currentProgress = null;
                  });
                  try {
                    await executeJob();
                  } catch (e) {
                    setState(() => errorMessage = e.toString());
                  } finally {
                    setState(() => isProcessing = false);
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Job'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

             // 4. Result Section
             if (outputPath != null) ...[
               const Gap(24),
               _buildSectionHeader('Output'),
               Card(
                 color: Colors.green.shade50,
                 child: ListTile(
                   leading: const Icon(Icons.check_circle, color: Colors.green),
                   title: Text(outputPath!.split(Platform.pathSeparator).last),
                   subtitle: Text(outputPath!),
                   trailing: const Icon(Icons.chevron_right),
                   onTap: () {
                     // TODO: Open preview
                   },
                 ),
               )
             ],
             
             if (errorMessage != null) ...[
               const Gap(24),
               Card(
                 color: Colors.red.shade50,
                 child: Padding(
                   padding: const EdgeInsets.all(16),
                   child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                 ),
               )
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
