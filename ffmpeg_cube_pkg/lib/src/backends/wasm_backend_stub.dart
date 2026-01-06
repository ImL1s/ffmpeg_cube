import 'dart:typed_data';
import '../models/jobs/base_job.dart';

Future<bool> isWasmAvailable() async => false;

Future<void> executeWasm(
  BaseJob job, {
  void Function(double)? onProgress,
  bool Function()? isCancelled,
}) async {
  throw UnsupportedError('ffmpeg.wasm is only supported on web');
}

Future<Map<String, dynamic>> probeWasm(String filePath) async {
  throw UnsupportedError('ffmpeg.wasm is only supported on web');
}

Future<void> writeFileWasm(String path, Uint8List data) async {
  throw UnsupportedError('ffmpeg.wasm is only supported on web');
}

Future<Uint8List> readFileWasm(String path) async {
  throw UnsupportedError('ffmpeg.wasm is only supported on web');
}

Future<void> deleteFileWasm(String path) async {
  throw UnsupportedError('ffmpeg.wasm is only supported on web');
}

Future<void> cancelWasm() async {
  // No-op on non-web platforms
}
