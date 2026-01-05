# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-06

### Added

#### Core SDK
- `FFmpegCubeClient` - Main API entry point for all operations
- `FormatPolicy` - Intelligent codec recommendation engine
- `BackendRouter` - Automatic platform-specific backend selection

#### Job Models
- `TranscodeJob` - Video transcoding with codec, resolution, bitrate options
- `TrimJob` - Video trimming with start/end time or duration
- `ThumbnailJob` - Frame extraction with format and quality options
- `ConcatJob` - Video concatenation (demuxer and filter methods)
- `MixAudioJob` - Audio mixing with volume control
- `SubtitleJob` - Subtitle embedding (hardcode and softcode)

#### Backend Support
- `FFmpegKitBackend` - Android/iOS/macOS via ffmpeg_kit_flutter_new
- `ProcessBackend` - Windows/Linux via system FFmpeg
- `WasmBackend` - Web platform stub (ffmpeg.wasm)
- `RemoteBackend` - Remote API fallback stub

#### Playback
- `UnifiedPlayer` - Cross-platform video playback via media_kit
- `UnifiedVideoPlayer` - Flutter widget with controls

#### Utilities
- `ProbeResult` - Media file information parsing
- `JobProgress` - Real-time progress tracking
- `JobError` / `JobResult` - Comprehensive error handling

### Example Application
- Home screen with 4 feature cards
- Transcode screen with codec/resolution options
- Thumbnail screen with time slider
- Player screen with playback controls
- Probe screen with media info display

### Tests
- 34 unit tests covering all job models
- Job validation and FFmpeg argument generation
- ProbeResult JSON parsing
- FormatPolicy recommendations
