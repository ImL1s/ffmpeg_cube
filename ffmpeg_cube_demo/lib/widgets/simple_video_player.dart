import 'package:flutter/material.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

class SimpleVideoPlayer extends StatefulWidget {
  final String path;
  final bool autoPlay;

  const SimpleVideoPlayer({
    super.key,
    required this.path,
    this.autoPlay = false,
  });

  @override
  State<SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<SimpleVideoPlayer> {
  final UnifiedPlayer _player = UnifiedPlayer();

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.open(widget.path, autoPlay: widget.autoPlay);
    setState(() {});
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            UnifiedVideoPlayer(player: _player),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _player.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_player.isPlaying) {
                  _player.pause();
                } else {
                  _player.play();
                }
              });
            },
          ),
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                return Slider(
                  value: pos.inSeconds.toDouble(),
                  max: _player.duration.inSeconds.toDouble(),
                  onChanged: (v) {
                    _player.seek(Duration(seconds: v.toInt()));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
