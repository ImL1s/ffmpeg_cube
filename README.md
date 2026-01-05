# FFmpeg Cube Workspace

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Framework-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/FFmpeg-Powered-green?logo=ffmpeg" alt="FFmpeg">
  <a href="https://github.com/ImL1s/ffmpeg_cube/actions"><img src="https://github.com/ImL1s/ffmpeg_cube/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
</p>

跨平台影音處理與播放 SDK for Flutter，支援 Android、iOS、macOS、Windows、Linux、Web 六大平台。

---

## 📂 專案結構

```
ffmpeg_cube/
├── ffmpeg_cube_pkg/     # 💎 核心 Flutter SDK 套件
│   ├── lib/             # SDK 源碼
│   ├── example/         # 範例應用程式
│   └── test/            # 單元測試 (106 tests)
├── docs/                # 設計文檔
├── .github/workflows/   # CI/CD 配置
└── README.md            # 本文件
```

---

## 🚀 快速開始

**詳細文檔請參閱：[ffmpeg_cube_pkg/README.md](ffmpeg_cube_pkg/README.md)**

### 安裝

```yaml
dependencies:
  ffmpeg_cube: ^0.1.0
```

### 基本使用

```dart
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

final client = FFmpegCubeClient();

// 轉檔
await client.transcode(TranscodeJob(
  inputPath: '/input.mp4',
  outputPath: '/output.mp4',
  videoCodec: VideoCodec.h264,
));

// 裁剪
await client.trim(TrimJob(
  inputPath: '/video.mp4',
  outputPath: '/clip.mp4',
  startTime: Duration(seconds: 10),
  duration: Duration(seconds: 30),
));

// 探測媒體資訊
final probe = await client.probe('/video.mp4');
print('Duration: ${probe.data?.duration}');
```

---

## ✨ 功能亮點

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
- 🐛 [Issue Tracker](https://github.com/ImL1s/ffmpeg_cube/issues)
