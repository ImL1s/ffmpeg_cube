import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  UnifiedPlayer? _player;
  String? _currentSource;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _player = UnifiedPlayer();
  }
  
  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
  
  Future<void> _pickAndPlayLocal() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    
    if (result != null && result.files.single.path != null) {
      await _playSource(result.files.single.path!);
    }
  }
  
  Future<void> _playNetworkSample() async {
    // Sample video URL (Big Buck Bunny)
    const sampleUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    await _playSource(sampleUrl);
  }
  
  Future<void> _playSource(String source) async {
    setState(() {
      _isLoading = true;
      _currentSource = source;
    });
    
    try {
      await _player?.open(source);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失敗: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('影片播放'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '開啟本地檔案',
            onPressed: _pickAndPlayLocal,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: '播放範例影片',
            onPressed: _playNetworkSample,
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player
          Expanded(
            child: _player != null
                ? UnifiedVideoPlayer(
                    player: _player!,
                    showControls: true,
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          
          // Info and Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Current Source
                if (_currentSource != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            _currentSource!.startsWith('http') 
                                ? Icons.cloud 
                                : Icons.insert_drive_file,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentSource!.split('/').last,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                
                // Playback Info
                if (_player != null)
                  StreamBuilder<Duration>(
                    stream: _player!.positionStream,
                    builder: (context, posSnapshot) {
                      return StreamBuilder<Duration>(
                        stream: _player!.durationStream,
                        builder: (context, durSnapshot) {
                          final pos = posSnapshot.data ?? Duration.zero;
                          final dur = durSnapshot.data ?? Duration.zero;
                          
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _InfoChip(
                                icon: Icons.timer,
                                label: '位置',
                                value: _formatDuration(pos),
                              ),
                              _InfoChip(
                                icon: Icons.timelapse,
                                label: '總長',
                                value: _formatDuration(dur),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 12),
                
                // Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      iconSize: 36,
                      onPressed: () => _player?.skipBackward(const Duration(seconds: 10)),
                    ),
                    const SizedBox(width: 16),
                    StreamBuilder<bool>(
                      stream: _player?.playingStream,
                      initialData: false,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
                          iconSize: 64,
                          color: Colors.deepPurple,
                          onPressed: () => _player?.playOrPause(),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      iconSize: 36,
                      onPressed: () => _player?.skipForward(const Duration(seconds: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
