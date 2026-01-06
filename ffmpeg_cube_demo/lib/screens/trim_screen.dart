import 'package:flutter/material.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'base_job_screen.dart';

class TrimScreen extends BaseJobScreen {
  const TrimScreen({super.key});

  @override
  State<TrimScreen> createState() => _TrimScreenState();
}

class _TrimScreenState extends BaseJobScreenState<TrimScreen> {
  RangeValues? _rangeValues;
  Duration? _totalDuration;
  bool _isProbing = false;

  @override
  String get title => 'Trim';

  @override
  Future<void> pickInputFile() async {
    await super.pickInputFile();
    if (inputPath != null) {
      setState(() => _isProbing = true);
      try {
        final result = await client.probe(inputPath!);
        if (result.success && result.data != null) {
          final d = result.data!.duration; // Duration object
          if (d != null) {
            setState(() {
              _totalDuration = d;
              _rangeValues = RangeValues(0, d.inSeconds.toDouble());
            });
          }
        }
      } catch (e) {
        // ignore probe error
      } finally {
        setState(() => _isProbing = false);
      }
    }
  }

  @override
  Widget buildConfigSection(BuildContext context) {
    if (_isProbing) return const Center(child: CircularProgressIndicator());
    
    if (_totalDuration == null) {
      return const Text('Select a file to load duration.');
    }

    return Column(
      children: [
        Text(
          'Range: ${_formatDuration(Duration(seconds: _rangeValues!.start.toInt()))} - '
          '${_formatDuration(Duration(seconds: _rangeValues!.end.toInt()))}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        RangeSlider(
          values: _rangeValues!,
          min: 0,
          max: _totalDuration!.inSeconds.toDouble(),
          divisions: _totalDuration!.inSeconds > 0 ? _totalDuration!.inSeconds : 1,
          labels: RangeLabels(
            _formatDuration(Duration(seconds: _rangeValues!.start.toInt())),
            _formatDuration(Duration(seconds: _rangeValues!.end.toInt())),
          ),
          onChanged: (values) {
            setState(() => _rangeValues = values);
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Future<void> executeJob() async {
    if (_rangeValues == null) return;
    
    final dir = await getTemporaryDirectory();
    final out = p.join(dir.path, 'trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4');
    
    final start = Duration(seconds: _rangeValues!.start.toInt());
    final end = Duration(seconds: _rangeValues!.end.toInt());

    final job = TrimJob(
      inputPath: inputPath!,
      outputPath: out,
      startTime: start,
      endTime: end,
    );

    final result = await client.trim(
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
