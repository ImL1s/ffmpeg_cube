import 'package:flutter/material.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart' as cube;
import 'package:gap/gap.dart';

class FormatPolicyScreen extends StatefulWidget {
  const FormatPolicyScreen({super.key});

  @override
  State<FormatPolicyScreen> createState() => _FormatPolicyScreenState();
}

class _FormatPolicyScreenState extends State<FormatPolicyScreen> {
  cube.FormatPolicyMode _selectedMode = cube.FormatPolicyMode.crossPlatform;
  bool _isWebTarget = false;
  cube.TargetPlatform? _simulatedPlatform; 

  @override
  Widget build(BuildContext context) {
    final policy = cube.FormatPolicy(mode: _selectedMode);
    
    // Determine platform to use for recommendation
    // Map Flutter platform to Cube platform
    final currentFlutterPlatform = Theme.of(context).platform;
    final cube.TargetPlatform currentCubePlatform = _mapPlatform(currentFlutterPlatform);

    final targetPlatform = _simulatedPlatform ?? currentCubePlatform;

    final recommendation = policy.getRecommendation(
      platform: targetPlatform,
      isWebTarget: _isWebTarget,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Format Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildControlSection(),
            const Gap(24),
            _buildRecommendationCard(recommendation),
            const Gap(24),
            _buildSupportedCodecsSection(targetPlatform),
          ],
        ),
      ),
    );
  }

  cube.TargetPlatform _mapPlatform(TargetPlatform p) {
    switch (p) {
      case TargetPlatform.android: return cube.TargetPlatform.android;
      case TargetPlatform.iOS: return cube.TargetPlatform.ios;
      case TargetPlatform.macOS: return cube.TargetPlatform.macos;
      case TargetPlatform.windows: return cube.TargetPlatform.windows;
      case TargetPlatform.linux: return cube.TargetPlatform.linux;
      case TargetPlatform.fuchsia: return cube.TargetPlatform.android; // Fallback
    }
  }

  Widget _buildControlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Policy Settings', style: Theme.of(context).textTheme.titleLarge),
            const Gap(16),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Policy Mode', border: OutlineInputBorder()),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<cube.FormatPolicyMode>(
                  value: _selectedMode,
                  isDense: true,
                  items: cube.FormatPolicyMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedMode = v!),
                ),
              ),
            ),
            const Gap(16),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Target Platform (Simulate)', border: OutlineInputBorder()),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<cube.TargetPlatform>(
                  value: _simulatedPlatform,
                  isDense: true,
                  hint: const Text('Current Device (Auto)'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Current Device (Auto)'),
                    ),
                    ...cube.TargetPlatform.values.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name),
                    )),
                  ],
                  onChanged: (v) => setState(() => _simulatedPlatform = v),
                ),
              ),
            ),
            const Gap(16),
             SwitchListTile(
              title: const Text('Is Web Target?'),
              subtitle: const Text('Simulate browser constraints'),
              value: _isWebTarget,
              onChanged: (v) => setState(() => _isWebTarget = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(cube.CodecRecommendation rec) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
              children: [
                Icon(Icons.recommend, color: Theme.of(context).colorScheme.onPrimaryContainer),
                const Gap(8),
                Text(
                  'Recommendation', 
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  )
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Container', rec.container.name.toUpperCase()),
            _buildInfoRow('Video Codec', rec.videoCodec.name.toUpperCase()),
            _buildInfoRow('Audio Codec', rec.audioCodec.name.toUpperCase()),
            _buildInfoRow('Video Bitrate', rec.videoBitrate ?? 'Auto'),
            _buildInfoRow('Audio Bitrate', rec.audioBitrate ?? 'Auto'),
            if (rec.resolution != null)
              _buildInfoRow('Resolution', rec.resolution!.name),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildSupportedCodecsSection(cube.TargetPlatform platform) {
    final codecs = cube.VideoCodec.values.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Codec Support on ${platform.name}', style: Theme.of(context).textTheme.titleMedium),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: codecs.map((codec) {
                final isSupported = cube.FormatPolicy.isCodecSupported(codec, platform);
                return Chip(
                  avatar: Icon(
                    isSupported ? Icons.check_circle : Icons.cancel,
                    color: isSupported ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  label: Text(codec.name),
                  backgroundColor: isSupported ? Colors.green.shade50 : Colors.red.shade50,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
