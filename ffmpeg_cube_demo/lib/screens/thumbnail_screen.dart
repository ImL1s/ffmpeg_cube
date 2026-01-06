import 'package:flutter/material.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:gap/gap.dart';
import 'base_job_screen.dart';

class ThumbnailScreen extends BaseJobScreen {
  const ThumbnailScreen({super.key});

  @override
  State<ThumbnailScreen> createState() => _ThumbnailScreenState();
}

class _ThumbnailScreenState extends BaseJobScreenState<ThumbnailScreen> {
  Duration? _totalDuration;
  double _sliderValue = 0.0;
  bool _isProbing = false;
  int _quality = 2; // 1-31

  @override
  String get title => 'Thumbnail';

  @override
  Future<void> pickInputFile() async {
    await super.pickInputFile();
    if (inputPath != null) {
      setState(() => _isProbing = true);
      try {
        final result = await client.probe(inputPath!);
        if (result.success && result.data != null) {
          setState(() {
            _totalDuration = result.data!.duration;
            _sliderValue = 0.0;
          });
        }
      } catch (e) {
        // ignore
      } finally {
        setState(() => _isProbing = false);
      }
    }
  }

  @override
  Widget buildConfigSection(BuildContext context) {
    if (_isProbing) return const Center(child: CircularProgressIndicator());
    if (_totalDuration == null) return const Text('Select a file to enable options.');

    return Column(
      children: [
        Text(
          'Position: ${_formatDuration(Duration(seconds: _sliderValue.toInt()))}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: _sliderValue,
          min: 0,
          max: _totalDuration!.inSeconds.toDouble(),
          onChanged: (v) => setState(() => _sliderValue = v),
        ),
        const Gap(16),
        Text('Quality (1-31, lower is better): $_quality'),
        Slider(
          value: _quality.toDouble(),
          min: 1,
          max: 31,
          divisions: 30,
          label: _quality.toString(),
          onChanged: (v) => setState(() => _quality = v.toInt()),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Future<void> executeJob() async {
    final dir = await getTemporaryDirectory();
    final out = p.join(dir.path, 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    final job = ThumbnailJob(
      videoPath: inputPath!,
      outputImagePath: out,
      timePosition: Duration(seconds: _sliderValue.toInt()),
      quality: _quality,
    );

    final result = await client.thumbnail(job);

    if (result.success) {
      setState(() {
         outputPath = out;
         // Fake progress since thumbnail usually doesn't have progress
         currentProgress = JobProgress(progress: 1.0, totalDuration: Duration.zero);
      });
    } else {
      throw result.error?.message ?? 'Unknown error';
    }
  }
}
