# FFmpeg Cube Workspace

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Framework-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/FFmpeg-Powered-green?logo=ffmpeg" alt="FFmpeg">
  <a href="https://github.com/ImL1s/ffmpeg_cube/actions"><img src="https://github.com/ImL1s/ffmpeg_cube/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
</p>


[English](#english) | [中文](#中文)

---

<a name="english"></a>
## English

**Cross-platform Audio/Video Processing & Playback SDK for Flutter.**  
Supports **Android**, **iOS**, **macOS**, **Windows**, **Linux**, and **Web**.

### 📂 Project Structure

```
ffmpeg_cube/
├── ffmpeg_cube_pkg/     # 💎 Core Flutter SDK Package
│   ├── lib/             # SDK Source Code
│   ├── example/         # Example Application
│   └── test/            # Unit Tests (106 tests)
├── ffmpeg_cube_demo/    # 📱 Full-Featured Demo App
├── docs/                # Design Documentation
├── .github/workflows/   # CI/CD Configuration
└── README.md            # This File
```

### 🚀 Quick Start

**For detailed documentation, please visit: [ffmpeg_cube_pkg/README.md](ffmpeg_cube_pkg/README.md)**

#### Installation

```yaml
dependencies:
  ffmpeg_cube: ^0.1.3
```

#### Basic Usage

```dart
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

final client = FFmpegCubeClient();

// Transcode
await client.transcode(TranscodeJob(
  inputPath: '/input.mp4',
  outputPath: '/output.mp4',
  videoCodec: VideoCodec.h264,
));

// Media Probe
final probe = await client.probe('/video.mp4');
print('Duration: ${probe.data?.duration}');
```

### ✨ Features

| Feature | Description |
|---------|-------------|
| 🎬 **Transcode** | Convert format, codec (H.264, H.265, VP9, etc.) |
| ✂️ **Trim** | Cut video by time range |
| 🖼️ **Thumbnail** | Extract static images from video |
| 🔗 **Concat** | Merge multiple video clips |
| 📝 **Subtitle** | Embed hard or soft subtitles |
| 🎵 **Audio** | Extract audio, mix tracks |
| ▶️ **Playback** | Unified cross-platform player interface |
| 🧠 **Smart Policy** | Auto-select best codec settings |

### 📱 Demo App

A full-featured demo app showcasing all SDK capabilities:

```bash
cd ffmpeg_cube_demo
flutter run
```

Supports: Android, iOS, macOS, Windows, Linux, Web

---

<a name="中文"></a>
## 中文

**跨平台影音處理與播放 SDK for Flutter**  
支援 **Android**、**iOS**、**macOS**、**Windows**、**Linux**、**Web** 六大平台。

### 📂 專案結構

```
ffmpeg_cube/
├── ffmpeg_cube_pkg/     # 💎 核心 Flutter SDK 套件
│   ├── lib/             # SDK 源碼
│   ├── example/         # 範例應用程式
│   └── test/            # 單元測試 (106 tests)
├── ffmpeg_cube_demo/    # 📱 完整功能展示 App
├── docs/                # 設計文檔
├── .github/workflows/   # CI/CD 配置
└── README.md            # 本文件
```

### 🚀 快速開始

**詳細文檔請參閱：[ffmpeg_cube_pkg/README.md](ffmpeg_cube_pkg/README.md)**

#### 安裝

```yaml
dependencies:
  ffmpeg_cube: ^0.1.3
```

#### 基本使用

```dart
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

final client = FFmpegCubeClient();

// 轉檔
await client.transcode(TranscodeJob(
  inputPath: '/input.mp4',
  outputPath: '/output.mp4',
  videoCodec: VideoCodec.h264,
));

// 探測媒體資訊
final probe = await client.probe('/video.mp4');
print('Duration: ${probe.data?.duration}');
```

### ✨ 功能亮點

| 功能 | 說明 |
|------|------|
| 🎬 **影片轉檔** | 支援 H.264, H.265, VP9 等編碼轉換 |
| ✂️ **影片裁剪** | 精確截取時間區間 |
| 🖼️ **縮圖擷取** | 從任意時間點擷取靜態圖 |
| 🔗 **影片合併** | 串接多個影片片段 |
| 📝 **字幕嵌入** | 硬字幕/軟字幕支援 |
| 🎵 **音訊處理** | 音軌提取、多軌混音 |
| ▶️ **統一播放** | 跨平台播放器介面 |
| 🧠 **智能策略** | 自動選擇最佳編碼參數 |

### 📱 Demo App

完整功能展示應用程式：

```bash
cd ffmpeg_cube_demo
flutter run
```

支援平台：Android、iOS、macOS、Windows、Linux、Web

---

## 🛠️ 開發

### 運行測試

```bash
cd ffmpeg_cube_pkg
flutter test
```

### 代碼分析

```bash
cd ffmpeg_cube_pkg
flutter analyze
```

### 格式化

```bash
cd ffmpeg_cube_pkg
dart format .
```

---

## 🏗️ 架構設計

```
┌─────────────────────────────────────────────────────┐
│                  FFmpegCubeClient                   │
├─────────────────────────────────────────────────────┤
│  transcode() | trim() | concat() | probe() | ...    │
├─────────────────────────────────────────────────────┤
│                   BackendRouter                     │
├──────────┬──────────┬──────────┬───────────────────┤
│ FFmpegKit│ Process  │   Wasm   │      Remote       │
│ (Mobile) │(Desktop) │  (Web)   │    (Fallback)     │
└──────────┴──────────┴──────────┴───────────────────┘
```

---

## 📄 授權

BSD-3-Clause License

---

## 🔗 連結

- 📦 [pub.dev](https://pub.dev/packages/ffmpeg_cube)
- 📖 [完整 SDK 文檔](ffmpeg_cube_pkg/README.md)
- 📚 [API Documentation](https://iml1s.github.io/ffmpeg_cube/)
- 🐛 [Issue Tracker](https://github.com/ImL1s/ffmpeg_cube/issues)

