# FFmpeg Cube Example App

[English](#english) | [中文](#中文)

---

<a name="english"></a>
## English

This example application demonstrates the core features of the **FFmpeg Cube SDK**.

### ✨ Features

The app includes the following demo pages:

1.  **Home** - Feature overview and navigation.
2.  **Transcode** - Video transcoding demo.
    - Select input video.
    - Set codec parameters (H.264/H.265).
    - Adjust resolution and bitrate.
    - View progress and estimated time.
3.  **Thumbnail** - Thumbnail extraction demo.
    - Slider to select time position.
    - Real-time preview of extracted thumbnail.
4.  **Player** - Cross-platform player demo.
    - Play local or network videos.
    - Playback controls (Play/Pause/Seek).
5.  **Probe** - Media information demo.
    - Display detailed video/audio/container info.

### 📱 How to Run

```bash
# Ensure Flutter is installed
flutter doctor

# Get dependencies
flutter pub get

# Run (Select your device)
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux
flutter run -d android    # Android
flutter run -d ios        # iOS
```

### 🧩 Core Snippets

#### Initialize Client

```dart
final client = FFmpegCubeClient();
```

#### Progress Listener

```dart
await client.transcode(
  job,
  onProgress: (progress) {
    setState(() {
      _progress = progress.progressPercent;
      _status = 'Processing: ${(progress.progressPercent * 100).toInt()}%';
    });
  },
);
```

#### Player Integration

```dart
// Use UnifiedPlayer
final player = UnifiedPlayer();
await player.open(filePath);

// UI Display
UnifiedVideoPlayer(player: player);
```

---

<a name="中文"></a>
## 中文

這個範例應用程式展示了 **FFmpeg Cube SDK** 的核心功能。

### ✨ 展示功能

應用程式包含以下功能演示頁面：

1.  **Home** - 功能概覽與導航
2.  **Transcode** - 影片轉檔演示
    - 選擇輸入影片
    - 設定編碼參數 (H.264/H.265)
    - 調整解析度與位元率
    - 檢視轉檔進度與預估時間
3.  **Thumbnail** - 縮圖擷取演示
    - 滑動選擇時間點
    - 即時預覽擷取的縮圖
4.  **Player** - 跨平台播放器演示
    - 播放本地或網路影片
    - 播放控制 (Play/Pause/Seek)
5.  **Probe** - 媒體探測演示
    - 顯示詳盡的影片/音訊/容器資訊

### 📱 運行方式

```bash
# 確保已安裝 Flutter
flutter doctor

# 獲取依賴
flutter pub get

# 運行 (選擇你的設備)
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux
flutter run -d android    # Android
flutter run -d ios        # iOS
```

### 🧩 核心代碼片段

#### 初始化 Client

```dart
final client = FFmpegCubeClient();
```

#### 監聽轉檔進度

```dart
await client.transcode(
  job,
  onProgress: (progress) {
    setState(() {
      _progress = progress.progressPercent;
      _status = '處理中: ${(progress.progressPercent * 100).toInt()}%';
    });
  },
);
```

#### 播放器集成

```dart
// 使用 UnifiedPlayer
final player = UnifiedPlayer();
await player.open(filePath);

// UI 顯示
UnifiedVideoPlayer(player: player);
```
