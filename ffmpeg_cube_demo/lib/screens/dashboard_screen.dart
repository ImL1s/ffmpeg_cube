import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'transcode_screen.dart';
import 'trim_screen.dart';
import 'concat_screen.dart';
import 'thumbnail_screen.dart';
import 'subtitle_screen.dart';
import 'mix_audio_screen.dart';
import 'extract_audio_screen.dart';
import 'probe_screen.dart';
import 'playback_screen.dart';
import 'format_policy_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  final List<Map<String, dynamic>> features = const [
    {
      'title': 'Transcode',
      'icon': Icons.transform,
      'color': Colors.blue,
      'route': TranscodeScreen(),
      'desc': 'Convert video formats & codecs',
    },
    {
      'title': 'Trim',
      'icon': Icons.content_cut,
      'color': Colors.red,
      'route': TrimScreen(),
      'desc': 'Cut video by time range',
    },
    {
      'title': 'Concat',
      'icon': Icons.merge_type,
      'color': Colors.green,
      'route': ConcatScreen(),
      'desc': 'Merge multiple videos',
    },
    {
      'title': 'Thumbnail',
      'icon': Icons.image,
      'color': Colors.purple,
      'route': ThumbnailScreen(),
      'desc': 'Extract specific frames',
    },
    {
      'title': 'Subtitle',
      'icon': Icons.subtitles,
      'color': Colors.orange,
      'route': SubtitleScreen(),
      'desc': 'Hard/Soft subtitle embedding',
    },
    {
      'title': 'Mix Audio',
      'icon': Icons.queue_music,
      'color': Colors.teal,
      'route': MixAudioScreen(),
      'desc': 'Mix multiple audio tracks',
    },
    {
      'title': 'Extract Audio',
      'icon': Icons.audiotrack,
      'color': Colors.pink,
      'route': ExtractAudioScreen(),
      'desc': 'Extract audio from video',
    },
    {
      'title': 'Probe',
      'icon': Icons.info,
      'color': Colors.indigo,
      'route': ProbeScreen(),
      'desc': 'View media metadata',
    },
    {
      'title': 'Format Policy',
      'icon': Icons.policy,
      'color': Colors.brown,
      'route': FormatPolicyScreen(),
      'desc': 'Codec recommendations',
    },
    {
      'title': 'Playback',
      'icon': Icons.play_circle_filled,
      'color': Colors.cyan,
      'route': PlaybackScreen(),
      'desc': 'Test UnifiedPlayer',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FFmpeg Cube Demo'),
        centerTitle: true,
        elevation: 2,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return _FeatureCard(
            title: feature['title'],
            icon: feature['icon'],
            color: feature['color'],
            desc: feature['desc'],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => feature['route']),
              );
            },
          );
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String desc;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const Gap(12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const Gap(4),
              Text(
                desc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
