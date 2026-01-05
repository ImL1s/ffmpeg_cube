import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/jobs/base_job.dart';
import '../models/job_error.dart';
import '../models/job_progress.dart';
import '../models/probe_result.dart';
import 'ffmpeg_kit_backend.dart';
import 'process_backend.dart';
import 'wasm_backend.dart';
import 'remote_backend.dart';

/// Supported backend types
enum BackendType {
  /// FFmpegKit for Android/iOS/macOS
  ffmpegKit,

  /// System Process for Windows/Linux
  process,

  /// WebAssembly for Web
  wasm,

  /// Remote API for fallback
  remote,
}

/// Abstract interface for all backends
abstract class FFmpegBackend {
  /// Get the backend type
  BackendType get type;

  /// Check if this backend is available on the current platform
  Future<bool> isAvailable();

  /// Execute FFmpeg with the given arguments
  Future<JobResult<void>> execute(
    List<String> args, {
    void Function(JobProgress)? onProgress,
    Duration? totalDuration,
  });

  /// Execute FFprobe to get media information
  Future<JobResult<ProbeResult>> probe(String filePath);

  /// Cancel a running job
  Future<void> cancel();

  /// Dispose resources
  void dispose();
}

/// Platform router that selects the appropriate backend
class BackendRouter {
  /// Remote API endpoint (optional, for fallback)
  final String? remoteEndpoint;

  /// Preferred backend type (optional)
  final BackendType? preferredBackend;

  /// Path to FFmpeg binary (for Process backend)
  final String? ffmpegPath;

  FFmpegBackend? _cachedBackend;

  BackendRouter({
    this.remoteEndpoint,
    this.preferredBackend,
    this.ffmpegPath,
  });

  /// Get the current platform
  TargetPlatform get currentPlatform {
    if (kIsWeb) return TargetPlatform.web;
    if (Platform.isAndroid) return TargetPlatform.android;
    if (Platform.isIOS) return TargetPlatform.ios;
    if (Platform.isMacOS) return TargetPlatform.macos;
    if (Platform.isWindows) return TargetPlatform.windows;
    if (Platform.isLinux) return TargetPlatform.linux;
    throw JobError.platformNotSupported('Unknown platform');
  }

  /// Get the appropriate backend for the current platform
  Future<FFmpegBackend> getBackend() async {
    if (_cachedBackend != null) {
      return _cachedBackend!;
    }

    // If preferred backend is specified, try to use it
    if (preferredBackend != null) {
      final backend = _createBackend(preferredBackend!);
      if (await backend.isAvailable()) {
        _cachedBackend = backend;
        return backend;
      }
    }

    // Otherwise, select based on platform
    final defaultType = _getDefaultBackendType();
    var backend = _createBackend(defaultType);

    // Check if available
    if (!await backend.isAvailable()) {
      // Try fallbacks
      for (final fallback in _getFallbackTypes(defaultType)) {
        backend = _createBackend(fallback);
        if (await backend.isAvailable()) {
          break;
        }
      }
    }

    _cachedBackend = backend;
    return backend;
  }

  BackendType _getDefaultBackendType() {
    if (kIsWeb) return BackendType.wasm;

    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return BackendType.ffmpegKit;
    }

    if (Platform.isWindows || Platform.isLinux) {
      return BackendType.process;
    }

    return BackendType.remote;
  }

  List<BackendType> _getFallbackTypes(BackendType primary) {
    switch (primary) {
      case BackendType.ffmpegKit:
        return [BackendType.process, BackendType.remote];
      case BackendType.process:
        return [BackendType.remote];
      case BackendType.wasm:
        return [BackendType.remote];
      case BackendType.remote:
        return [];
    }
  }

  FFmpegBackend _createBackend(BackendType type) {
    switch (type) {
      case BackendType.ffmpegKit:
        return FFmpegKitBackend();
      case BackendType.process:
        return ProcessBackend(ffmpegPath: ffmpegPath);
      case BackendType.wasm:
        return WasmBackend();
      case BackendType.remote:
        return RemoteBackend(endpoint: remoteEndpoint ?? '');
    }
  }

  /// Execute a job using the appropriate backend
  Future<JobResult<void>> execute(
    BaseJob job, {
    void Function(JobProgress)? onProgress,
    Duration? totalDuration,
  }) async {
    final backend = await getBackend();
    return backend.execute(
      job.toFFmpegArgs(),
      onProgress: onProgress,
      totalDuration: totalDuration,
    );
  }

  /// Probe a media file using the appropriate backend
  Future<JobResult<ProbeResult>> probe(String filePath) async {
    final backend = await getBackend();
    return backend.probe(filePath);
  }

  /// Dispose resources
  void dispose() {
    _cachedBackend?.dispose();
    _cachedBackend = null;
  }
}

/// Target platform enumeration
enum TargetPlatform {
  android,
  ios,
  macos,
  windows,
  linux,
  web,
}
