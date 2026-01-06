import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_cube_demo/widgets/simple_video_player.dart';
import 'package:gap/gap.dart';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({super.key});

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  String? _path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playback')),
      body: Column(
        children: [
          Expanded(
            child: _path == null
                ? const Center(child: Text('Select a video to play'))
                : SimpleVideoPlayer(
                    key: ValueKey(_path), path: _path!, autoPlay: true),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.file_open),
                    label: const Text('Open Local File'),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null) {
                        setState(() => _path = result.files.single.path);
                      }
                    },
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text('Open URL (Test)'),
                    onPressed: () {
                      // Sample Big Buck Bunny
                      setState(() => _path =
                          'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8');
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
