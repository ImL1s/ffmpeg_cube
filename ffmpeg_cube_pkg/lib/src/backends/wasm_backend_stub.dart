import 'dart:typed_data';

/// Stub implementation for non-web platforms
/// These functions will never be called on non-web platforms

Future<bool> isWasmAvailable() async => false;

Future<void> executeWasm(
  List<String> args, {
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
