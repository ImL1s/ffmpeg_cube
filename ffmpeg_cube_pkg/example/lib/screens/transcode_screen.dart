import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_cube/ffmpeg_cube.dart';
import '../widgets/job_progress_widget.dart';

class TranscodeScreen extends StatefulWidget {
  const TranscodeScreen({super.key});

  @override
  State<TranscodeScreen> createState() => _TranscodeScreenState();
}

class _TranscodeScreenState extends State<TranscodeScreen> {
  final FFmpegCubeClient _client = FFmpegCubeClient();
  
  String? _inputPath;
  String? _outputPath;
  JobProgress? _progress;
  bool _isProcessing = false;
  String? _error;
  bool _completed = false;
  
  // Transcode options
  VideoCodec _videoCodec = VideoCodec.h264;
  VideoResolution _resolution = VideoResolution.r720p;
  
  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }
  
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    
    if (result != null && result.files.single.path != null) {
      setState(() {
        _inputPath = result.files.single.path;
        _error = null;
        _completed = false;
      });
    }
  }
  
  Future<void> _startTranscode() async {
    if (_inputPath == null) return;
    
    setState(() {
      _isProcessing = true;
      _error = null;
      _completed = false;
      _progress = null;
    });
    
    try {
      // Generate output path
      final tempDir = await getTemporaryDirectory();
      final inputName = p.basenameWithoutExtension(_inputPath!);
      _outputPath = p.join(tempDir.path, '${inputName}_transcoded.mp4');
      
      final job = TranscodeJob(
        inputPath: _inputPath!,
        outputPath: _outputPath!,
        videoCodec: _videoCodec,
        audioCodec: AudioCodec.aac,
        resolution: _resolution,
      );
      
      final result = await _client.transcode(
        job,
        onProgress: (progress) {
          setState(() => _progress = progress);
        },
      );
      
      if (result.success) {
        setState(() {
          _completed = true;
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('轉檔完成！輸出: ${p.basename(_outputPath!)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _error = result.error?.message ?? '轉檔失敗';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _cancelTranscode() async {
    await _client.cancel();
    setState(() {
      _isProcessing = false;
      _progress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('影片轉檔'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '選擇輸入檔案',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('選擇影片'),
                    ),
                    if (_inputPath != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '已選擇: ${p.basename(_inputPath!)}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Settings Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '轉檔設定',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    // Video Codec
                    Row(
                      children: [
                        const Text('視訊編碼:'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButton<VideoCodec>(
                            value: _videoCodec,
                            isExpanded: true,
                            onChanged: _isProcessing ? null : (v) {
                              if (v != null) setState(() => _videoCodec = v);
                            },
                            items: const [
                              DropdownMenuItem(value: VideoCodec.h264, child: Text('H.264')),
                              DropdownMenuItem(value: VideoCodec.h265, child: Text('H.265/HEVC')),
                              DropdownMenuItem(value: VideoCodec.vp9, child: Text('VP9')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Resolution
                    Row(
                      children: [
                        const Text('解析度:'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButton<VideoResolution>(
                            value: _resolution,
                            isExpanded: true,
                            onChanged: _isProcessing ? null : (v) {
                              if (v != null) setState(() => _resolution = v);
                            },
                            items: const [
                              DropdownMenuItem(value: VideoResolution.r360p, child: Text('360p')),
                              DropdownMenuItem(value: VideoResolution.r480p, child: Text('480p')),
                              DropdownMenuItem(value: VideoResolution.r720p, child: Text('720p')),
                              DropdownMenuItem(value: VideoResolution.r1080p, child: Text('1080p')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress Card
            if (_isProcessing || _progress != null || _completed)
              JobProgressWidget(
                progress: _progress,
                isProcessing: _isProcessing,
                completed: _completed,
                outputPath: _outputPath,
              ),
            
            // Error Message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.withValues(alpha: 0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_inputPath != null && !_isProcessing) ? _startTranscode : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('開始轉檔'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                if (_isProcessing) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _cancelTranscode,
                    icon: const Icon(Icons.stop),
                    label: const Text('取消'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
