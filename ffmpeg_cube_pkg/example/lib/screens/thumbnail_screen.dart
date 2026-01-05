import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

class ThumbnailScreen extends StatefulWidget {
  const ThumbnailScreen({super.key});

  @override
  State<ThumbnailScreen> createState() => _ThumbnailScreenState();
}

class _ThumbnailScreenState extends State<ThumbnailScreen> {
  final FFmpegCubeClient _client = FFmpegCubeClient();
  
  String? _inputPath;
  String? _thumbnailPath;
  bool _isProcessing = false;
  String? _error;
  Duration? _videoDuration;
  double _timePosition = 0; // 0.0 to 1.0
  
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
        _thumbnailPath = null;
        _error = null;
      });
      
      // Probe to get duration
      final probe = await _client.probe(_inputPath!);
      if (probe.success && probe.data?.duration != null) {
        setState(() {
          _videoDuration = probe.data!.duration;
        });
      }
    }
  }
  
  Future<void> _extractThumbnail() async {
    if (_inputPath == null) return;
    
    setState(() {
      _isProcessing = true;
      _error = null;
      _thumbnailPath = null;
    });
    
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = p.join(tempDir.path, 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Calculate time position
      Duration timePos = Duration.zero;
      if (_videoDuration != null) {
        timePos = Duration(milliseconds: (_videoDuration!.inMilliseconds * _timePosition).round());
      }
      
      final job = ThumbnailJob(
        videoPath: _inputPath!,
        timePosition: timePos,
        outputImagePath: outputPath,
        format: ImageFormat.jpg,
        width: 640,
      );
      
      final result = await _client.thumbnail(job);
      
      if (result.success) {
        setState(() {
          _thumbnailPath = outputPath;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _error = result.error?.message ?? '擷取失敗';
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
  
  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    Duration currentPosition = Duration.zero;
    if (_videoDuration != null) {
      currentPosition = Duration(milliseconds: (_videoDuration!.inMilliseconds * _timePosition).round());
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('縮圖擷取'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '選擇影片',
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
                      if (_videoDuration != null)
                        Text(
                          '時長: ${_formatDuration(_videoDuration!)}',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Time Position Slider
            if (_inputPath != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '選擇時間點',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(_formatDuration(currentPosition)),
                          Expanded(
                            child: Slider(
                              value: _timePosition,
                              onChanged: _isProcessing ? null : (v) {
                                setState(() => _timePosition = v);
                              },
                            ),
                          ),
                          Text(_videoDuration != null ? _formatDuration(_videoDuration!) : '--:--:--'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Thumbnail Preview
            if (_thumbnailPath != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '擷取結果',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_thumbnailPath!),
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '儲存於: ${p.basename(_thumbnailPath!)}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
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
            
            // Action Button
            ElevatedButton.icon(
              onPressed: (_inputPath != null && !_isProcessing) ? _extractThumbnail : null,
              icon: _isProcessing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image),
              label: Text(_isProcessing ? '擷取中...' : '擷取縮圖'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
