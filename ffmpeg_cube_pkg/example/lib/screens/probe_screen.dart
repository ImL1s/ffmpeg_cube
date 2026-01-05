import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

class ProbeScreen extends StatefulWidget {
  const ProbeScreen({super.key});

  @override
  State<ProbeScreen> createState() => _ProbeScreenState();
}

class _ProbeScreenState extends State<ProbeScreen> {
  final FFmpegCubeClient _client = FFmpegCubeClient();
  
  String? _inputPath;
  ProbeResult? _probeResult;
  bool _isLoading = false;
  String? _error;
  
  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }
  
  Future<void> _pickAndProbe() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    
    if (result != null && result.files.single.path != null) {
      setState(() {
        _inputPath = result.files.single.path;
        _isLoading = true;
        _probeResult = null;
        _error = null;
      });
      
      final probeResult = await _client.probe(_inputPath!);
      
      if (probeResult.success) {
        setState(() {
          _probeResult = probeResult.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = probeResult.error?.message ?? '探測失敗';
          _isLoading = false;
        });
      }
    }
  }
  
  String _formatDuration(Duration? d) {
    if (d == null) return 'N/A';
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
  
  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'N/A';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  String _formatBitrate(int? bps) {
    if (bps == null) return 'N/A';
    if (bps < 1000) return '$bps bps';
    if (bps < 1000000) return '${(bps / 1000).toStringAsFixed(0)} kbps';
    return '${(bps / 1000000).toStringAsFixed(1)} Mbps';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('媒體探測'),
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
                      '選擇媒體檔案',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickAndProbe,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.folder_open),
                      label: Text(_isLoading ? '探測中...' : '選擇檔案'),
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
            
            // Error
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
            
            // Results
            if (_probeResult != null) ...[
              const SizedBox(height: 16),
              
              // General Info
              _InfoSection(
                title: '基本資訊',
                icon: Icons.info,
                items: [
                  _InfoItem('格式', _probeResult!.format ?? 'N/A'),
                  _InfoItem('時長', _formatDuration(_probeResult!.duration)),
                  _InfoItem('檔案大小', _formatFileSize(_probeResult!.fileSize)),
                  _InfoItem('位元率', _formatBitrate(_probeResult!.bitrate)),
                ],
              ),
              
              // Video Stream
              if (_probeResult!.videoStream != null) ...[
                const SizedBox(height: 16),
                _InfoSection(
                  title: '視訊串流',
                  icon: Icons.videocam,
                  items: [
                    _InfoItem('編碼', _probeResult!.videoStream!.codec ?? 'N/A'),
                    _InfoItem('解析度', _probeResult!.videoStream!.resolution),
                    _InfoItem('幀率', _probeResult!.videoStream!.frameRate != null 
                        ? '${_probeResult!.videoStream!.frameRate!.toStringAsFixed(2)} fps' 
                        : 'N/A'),
                    _InfoItem('像素格式', _probeResult!.videoStream!.pixelFormat ?? 'N/A'),
                  ],
                ),
              ],
              
              // Audio Stream
              if (_probeResult!.audioStream != null) ...[
                const SizedBox(height: 16),
                _InfoSection(
                  title: '音訊串流',
                  icon: Icons.audiotrack,
                  items: [
                    _InfoItem('編碼', _probeResult!.audioStream!.codec ?? 'N/A'),
                    _InfoItem('取樣率', _probeResult!.audioStream!.sampleRate != null 
                        ? '${_probeResult!.audioStream!.sampleRate} Hz' 
                        : 'N/A'),
                    _InfoItem('聲道數', _probeResult!.audioStream!.channels?.toString() ?? 'N/A'),
                    _InfoItem('位元率', _formatBitrate(_probeResult!.audioStream!.bitrate)),
                  ],
                ),
              ],
              
              // Subtitle Streams
              if (_probeResult!.subtitleStreams.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoSection(
                  title: '字幕串流 (${_probeResult!.subtitleStreams.length})',
                  icon: Icons.subtitles,
                  items: _probeResult!.subtitleStreams.map((s) => 
                    _InfoItem(s.language ?? 'Unknown', s.codec ?? 'N/A')
                  ).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoItem> items;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.label, style: TextStyle(color: Colors.grey[400])),
                  Text(item.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  
  _InfoItem(this.label, this.value);
}
