import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Unified player for cross-platform video playback
///
/// Uses media_kit as backend for consistent playback across:
/// - Android
/// - iOS
/// - macOS
/// - Windows
/// - Linux
/// - Web (limited support)
///
/// Example usage:
/// ```dart
/// final player = UnifiedPlayer();
/// await player.open('/path/to/video.mp4');
///
/// // In your widget tree:
/// Video(controller: player.videoController)
/// ```
class UnifiedPlayer {
  late final Player _player;
  late final VideoController _videoController;

  /// Create a new UnifiedPlayer
  ///
  /// Call [MediaKit.ensureInitialized] before creating the first player
  UnifiedPlayer() {
    _player = Player();
    _videoController = VideoController(_player);
  }

  /// Get the underlying media_kit player
  Player get player => _player;

  /// Get the video controller for use with Video widget
  VideoController get videoController => _videoController;

  /// Current position stream
  Stream<Duration> get positionStream => _player.stream.position;

  /// Current duration stream
  Stream<Duration> get durationStream => _player.stream.duration;

  /// Buffering position stream
  Stream<Duration> get bufferStream => _player.stream.buffer;

  /// Playing state stream
  Stream<bool> get playingStream => _player.stream.playing;

  /// Completed state stream
  Stream<bool> get completedStream => _player.stream.completed;

  /// Volume stream (0.0 to 1.0)
  Stream<double> get volumeStream => _player.stream.volume;

  /// Playback rate stream
  Stream<double> get rateStream => _player.stream.rate;

  /// Whether currently playing
  bool get isPlaying => _player.state.playing;

  /// Current position
  Duration get position => _player.state.position;

  /// Total duration
  Duration get duration => _player.state.duration;

  /// Current volume (0.0 to 1.0)
  double get volume => _player.state.volume;

  /// Current playback rate
  double get rate => _player.state.rate;

  /// Open a media file for playback
  ///
  /// [source] can be:
  /// - Local file path: '/path/to/video.mp4'
  /// - Network URL: 'https://example.com/video.mp4'
  /// - Asset: 'asset:///assets/video.mp4'
  Future<void> open(String source, {bool autoPlay = true}) async {
    final media = Media(source);
    await _player.open(media, play: autoPlay);
  }

  /// Open multiple media files as a playlist
  Future<void> openPlaylist(List<String> sources,
      {bool autoPlay = true}) async {
    final playlist = Playlist(sources.map((s) => Media(s)).toList());
    await _player.open(playlist, play: autoPlay);
  }

  /// Play the media
  Future<void> play() => _player.play();

  /// Pause the media
  Future<void> pause() => _player.pause();

  /// Play or pause based on current state
  Future<void> playOrPause() => _player.playOrPause();

  /// Stop playback
  Future<void> stop() => _player.stop();

  /// Seek to position
  Future<void> seek(Duration position) => _player.seek(position);

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) => _player.setVolume(volume * 100);

  /// Set playback rate (1.0 is normal)
  Future<void> setRate(double rate) => _player.setRate(rate);

  /// Toggle mute
  Future<void> toggleMute() async {
    if (volume > 0) {
      await setVolume(0);
    } else {
      await setVolume(1.0);
    }
  }

  /// Skip forward by duration
  Future<void> skipForward(Duration amount) async {
    final newPosition = position + amount;
    await seek(newPosition > duration ? duration : newPosition);
  }

  /// Skip backward by duration
  Future<void> skipBackward(Duration amount) async {
    final newPosition = position - amount;
    await seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  /// Dispose the player
  void dispose() {
    _player.dispose();
  }
}

/// Widget for displaying video with controls
class UnifiedVideoPlayer extends StatefulWidget {
  /// The unified player instance
  final UnifiedPlayer player;

  /// Whether to show default controls
  final bool showControls;

  /// Aspect ratio for the video
  final double? aspectRatio;

  /// Fill mode
  final BoxFit fit;

  const UnifiedVideoPlayer({
    super.key,
    required this.player,
    this.showControls = true,
    this.aspectRatio,
    this.fit = BoxFit.contain,
  });

  @override
  State<UnifiedVideoPlayer> createState() => _UnifiedVideoPlayerState();
}

class _UnifiedVideoPlayerState extends State<UnifiedVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? 16 / 9,
      child: Video(
        controller: widget.player.videoController,
        controls: widget.showControls ? AdaptiveVideoControls : NoVideoControls,
        fit: widget.fit,
      ),
    );
  }
}
