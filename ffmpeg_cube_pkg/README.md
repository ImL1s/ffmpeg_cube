# FFmpeg Cube

跨平台影音處理與播放 SDK for Flutter

支援 **Android**、**iOS**、**macOS**、**Windows**、**Linux**、**Web** 六大平台。

## 功能特色

### 影音處理
- ✅ **轉檔** - 影片格式轉換、編碼調整
- ✅ **裁剪** - 截取影片指定時間區間
- ✅ **合併** - 串接多個影片
- ✅ **縮圖** - 從影片擷取靜態圖片
- ✅ **字幕** - 嵌入或軟編碼字幕
- ✅ **音訊** - 抽取音訊、混音

### 播放支援
- ✅ **跨平台播放** - 基於 media_kit 統一介面
- ✅ **串流支援** - 支援本地檔案、網路 URL

### 智慧功能
- ✅ **策略引擎** - 自動選擇最佳編碼格式
- ✅ **平台路由** - 根據平台自動選擇後端
- ✅ **進度回調** - 實時追蹤處理進度

## 安裝

```yaml
dependencies:
  ffmpeg_cube:
    path: ../ffmpeg_cube  # 或發布到 pub.dev 後使用版本號
```

## 快速開始

### 初始化

```dart
import 'package:ffmpeg_cube/ffmpeg_cube.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  // 初始化 media_kit（用於播放功能）
  MediaKit.ensureInitialized();
  
  runApp(MyApp());
}
```

### 轉檔影片

```dart
final client = FFmpegCubeClient();

final result = await client.transcode(
  TranscodeJob(
    inputPath: '/path/to/input.mp4',
    outputPath: '/path/to/output.mp4',
    videoCodec: VideoCodec.h264,
    audioCodec: AudioCodec.aac,
    resolution: VideoResolution.r1080p,
  ),
  onProgress: (progress) {
    print('進度: ${progress.progressPercent}%');
  },
);

if (result.success) {
  print('轉檔完成！');
}
```

### 擷取縮圖

```dart
await client.thumbnail(ThumbnailJob(
  videoPath: '/path/to/video.mp4',
  timePosition: Duration(seconds: 5),
  outputImagePath: '/path/to/thumbnail.jpg',
));
```

### 裁剪影片

```dart
await client.trim(TrimJob(
  inputPath: '/path/to/input.mp4',
  outputPath: '/path/to/output.mp4',
  startTime: Duration(seconds: 10),
  endTime: Duration(seconds: 30),
));
```

### 探測媒體信息

```dart
final probe = await client.probe('/path/to/video.mp4');
if (probe.success) {
  final data = probe.data!;
  print('時長: ${data.duration}');
  print('解析度: ${data.videoStream?.resolution}');
  print('編碼: ${data.videoStream?.codec}');
}
```

### 播放影片

```dart
final player = UnifiedPlayer();
await player.open('/path/to/video.mp4');

// 在 Widget 中使用
@override
Widget build(BuildContext context) {
  return UnifiedVideoPlayer(player: player);
}

// 控制播放
await player.play();
await player.pause();
await player.seek(Duration(seconds: 30));
```

## 平台支援

| 功能 | Android | iOS | macOS | Windows | Linux | Web |
|------|---------|-----|-------|---------|-------|-----|
| 轉檔 | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| 播放 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

- ✅ 完整支援
- ⚠️ 有限支援（Web 需使用遠端 API 或 ffmpeg.wasm）

## 後端策略

| 平台 | 後端 |
|------|------|
| Android/iOS/macOS | `ffmpeg_kit_flutter_new` |
| Windows/Linux | 系統 FFmpeg (`Process`) |
| Web | `ffmpeg.wasm` 或遠端 API |

## 授權

MIT License

## 相關連結

- [ffmpeg_kit_flutter_new](https://pub.dev/packages/ffmpeg_kit_flutter_new)
- [media_kit](https://pub.dev/packages/media_kit)
- [FFmpeg 官方文檔](https://ffmpeg.org/documentation.html)
