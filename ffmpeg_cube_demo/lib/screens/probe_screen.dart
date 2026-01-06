import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';
import 'base_job_screen.dart';

// ProbeScreen doesn't really fit BaseJobScreen model perfectly regarding output,
// but we can reuse the input selection part.
class ProbeScreen extends BaseJobScreen {
  const ProbeScreen({super.key});

  @override
  State<ProbeScreen> createState() => _ProbeScreenState();
}

class _ProbeScreenState extends BaseJobScreenState<ProbeScreen> {
  Map<String, dynamic>? _probeData;

  @override
  String get title => 'Probe Media';

  @override
  Widget buildConfigSection(BuildContext context) {
    return _probeData == null 
        ? const Text('Click Start Job to probe.') 
        : Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(_probeData),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          );
  }

  @override
  Future<void> executeJob() async {
    final result = await client.probe(inputPath!);
    
    if (result.success) {
      setState(() {
        // ProbeResult to Map
        _probeData = result.data?.rawData ?? {'error': 'No data'};
        // Hide standard progress bar usage in base
        currentProgress = JobProgress(progress: 1.0, totalDuration: Duration.zero); 
      });
    } else {
      throw result.error?.message ?? 'Unknown error';
    }
  }
}
