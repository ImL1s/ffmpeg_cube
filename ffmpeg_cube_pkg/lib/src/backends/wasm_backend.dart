import 'dart:async';
import 'dart:typed_data';
import 'backend_router.dart';
import '../models/jobs/base_job.dart';
import '../models/job_error.dart';
import '../models/job_progress.dart';
import '../models/probe_result.dart';

// Conditional import for web
import 'wasm_backend_stub.dart' if (dart.library.html) 'wasm_backend_web.dart'
    as impl;

/// Backend using FFmpeg.wasm for Web platform
///
/// This backend uses ffmpeg.wasm to run FFmpeg directly in the browser.
///
/// ## Requirements
///
/// 1. Add to your `web/index.html`:
/// ```html
/// <script src="https://unpkg.com/@aspect-dev/ffmpeg-wasm@0.12.14/dist/ffmpeg.min.js"></script>
/// ```
///
/// 2. Configure your web server with COOP/COEP headers:
/// ```
/// Cross-Origin-Embedder-Policy: require-corp
/// Cross-Origin-Opener-Policy: same-origin
/// ```
///
/// 3. For local development, run with:
/// ```bash
/// flutter run -d chrome --web-browser-flag "--enable-features=SharedArrayBuffer"
/// ```
///
/// ## Limitations
///
/// - File size limited to ~2GB due to browser memory constraints
/// - Performance is slower than native FFmpeg
/// - Some codecs may not be available in ffmpeg.wasm builds
class WasmBackend implements FFmpegBackend {
  bool _isCancelled = false;

  @override
  BackendType get type => BackendType.wasm;

  /// Check if ffmpeg.wasm is available
  ///
  /// Returns true if:
  /// - Running on web platform
  /// - ffmpeg.wasm is loaded
  /// - SharedArrayBuffer is available (COOP/COEP headers set)
  @override
  Future<bool> isAvailable() async {
    return impl.isWasmAvailable();
  }

  @override
  Future<JobResult<void>> execute(
    BaseJob job, {
    void Function(JobProgress)? onProgress,
    Duration? totalDuration,
  }) async {

    if (!await isAvailable()) {
      return JobResult.failure(JobError.platformNotSupported(
          'Web (ffmpeg.wasm not available). Ensure COOP/COEP headers are set.'));
    }

    _isCancelled = false;

    try {
      await impl.executeWasm(
        job,
        onProgress: onProgress != null
            ? (double progress) {
                onProgress(JobProgress(
                  progress: progress,
                  totalDuration: totalDuration,
                ));
              }
            : null,
        isCancelled: () => _isCancelled,
      );

      return JobResult.success();
    } catch (e, st) {
      if (_isCancelled) {
        return JobResult.failure(JobError.cancelled());
      }
      return JobResult.failure(JobError(
        code: JobErrorCode.ffmpegExecutionFailed,
        message: e.toString(),
        stackTrace: st,
      ));
    }
  }

  @override
  Future<JobResult<ProbeResult>> probe(String filePath) async {
    if (!await isAvailable()) {
      return JobResult.failure(
          JobError.platformNotSupported('Web (ffmpeg.wasm not available)'));
    }

    try {
      final json = await impl.probeWasm(filePath);
      return JobResult.success(
        data: ProbeResult.fromJson(filePath, json),
      );
    } catch (e, st) {
      return JobResult.failure(JobError(
        code: JobErrorCode.ffmpegExecutionFailed,
        message: e.toString(),
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Uint8List?> readFile(String path) async {
    if (!await isAvailable()) return null;
    try {
      return await impl.readFileWasm(path);
    } catch (e) {
      return null;
    }
  }

  /// Write a file to the ffmpeg.wasm virtual filesystem
  Future<void> writeFile(String path, Uint8List data) async {
    if (!await isAvailable()) {
      throw JobError.platformNotSupported('Web (ffmpeg.wasm not available)');
    }
    await impl.writeFileWasm(path, data);
  }

  /// Delete a file from the ffmpeg.wasm virtual filesystem
  Future<void> deleteFile(String path) async {
    if (!await isAvailable()) return;
    await impl.deleteFileWasm(path);
  }

  @override
  Future<void> cancel() async {
    _isCancelled = true;
    await impl.cancelWasm();
  }

  @override
  void dispose() {
    cancel();
  }
}
