import 'package:flutter/material.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

/// Widget for displaying job progress
class JobProgressWidget extends StatelessWidget {
  final JobProgress? progress;
  final bool isProcessing;
  final bool completed;
  final String? outputPath;

  const JobProgressWidget({
    super.key,
    this.progress,
    this.isProcessing = false,
    this.completed = false,
    this.outputPath,
  });

  String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  String _formatSpeed(double? speed) {
    if (speed == null) return '--';
    return '${speed.toStringAsFixed(2)}x';
  }
  
  String _formatSize(int? bytes) {
    if (bytes == null) return '--';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: completed ? Colors.green.withValues(alpha: 0.2) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (completed)
                  const Icon(Icons.check_circle, color: Colors.green)
                else if (isProcessing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.hourglass_empty, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  completed ? '處理完成' : (isProcessing ? '處理中...' : '準備中'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            if (progress != null || isProcessing) ...[
              const SizedBox(height: 16),
              
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress?.progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completed ? Colors.green : Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Progress Percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress?.progressPercent ?? 0}%',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (progress?.estimatedTimeRemaining != null)
                    Text(
                      '剩餘 ${_formatDuration(progress!.estimatedTimeRemaining)}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.timer,
                    label: '時間',
                    value: _formatDuration(progress?.currentTime),
                  ),
                  _StatItem(
                    icon: Icons.speed,
                    label: '速度',
                    value: _formatSpeed(progress?.speed),
                  ),
                  _StatItem(
                    icon: Icons.storage,
                    label: '大小',
                    value: _formatSize(progress?.currentSize),
                  ),
                ],
              ),
            ],
            
            // Output Path
            if (completed && outputPath != null) ...[
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.save, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      outputPath!.split('\\').last.split('/').last,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
