# FFmpeg Cube Workspace

Welcome to the **FFmpeg Cube** project workspace.

## 📂 Structure

- **`ffmpeg_cube_pkg/`**: The core Flutter SDK package. This is the main component of the project.
- **`docs/`**: Design documents and specifications.
- **`extract_pdf.js`**: Utility script for extracting design specs.

## 🚀 FFmpeg Cube SDK

**FFmpeg Cube** is a cross-platform video/audio processing and playback SDK for Flutter.

### Features
- **Cross-Platform**: Android, iOS, macOS, Windows, Linux, Web
- **Backends**: FFmpegKit, Process (Dart:IO), WebAssembly, Remote API
- **Operations**: Transcode, Trim, Concat, Mix Audio, Extract Thumbnail, Embed Subtitles
- **Playback**: Unified player interface via `media_kit`

✅ **See [ffmpeg_cube_pkg/README.md](ffmpeg_cube_pkg/README.md) for full SDK documentation and usage.**

## 🛠️ Development

### Prerequisites
- Flutter SDK
- Node.js (for utility scripts)

### Running Tests
```bash
cd ffmpeg_cube_pkg
flutter test
```

## 📄 License
BSD-3-Clause
