import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'backend_router.dart';
import '../models/job_error.dart';
import '../models/job_progress.dart';
import '../models/probe_result.dart';

/// Backend using remote API for processing
///
/// This allows offloading FFmpeg processing to a server, useful for:
/// - Web platform where ffmpeg.wasm has limitations
/// - Processing large files without local resources
/// - Reducing client battery/CPU usage on mobile
///
/// ## API Requirements
///
/// Your server should implement these endpoints:
///
/// ### POST /process
/// Upload file and start processing
/// - Request: multipart/form-data with 'file' and 'args' (JSON array)
/// - Response: { "jobId": "string" }
///
/// ### GET /process/{jobId}/status
/// Get job status and progress
/// - Response: { "status": "processing|completed|failed", "progress": 0.0-1.0, "error": "string?" }
///
/// ### GET /process/{jobId}/result
/// Download processed file (only when status is "completed")
/// - Response: binary file data
///
/// ### POST /probe
/// Probe a media file
/// - Request: multipart/form-data with 'file'
/// - Response: FFprobe JSON output
///
/// ### DELETE /process/{jobId}
/// Cancel a running job
class RemoteBackend implements FFmpegBackend {
  /// Remote API endpoint (e.g., 'https://api.example.com')
  final String endpoint;

  /// API key for authentication (sent as Authorization header)
  final String? apiKey;

  /// Timeout for HTTP requests
  final Duration timeout;

  /// Polling interval for progress updates
  final Duration pollInterval;

  /// Current job ID (for cancellation)
  String? _currentJobId;

  /// Cancellation flag
  bool _isCancelled = false;

  RemoteBackend({
    required this.endpoint,
    this.apiKey,
    this.timeout = const Duration(minutes: 30),
    this.pollInterval = const Duration(seconds: 2),
  });

  @override
  BackendType get type => BackendType.remote;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      };

  @override
  Future<bool> isAvailable() async {
    if (endpoint.isEmpty) return false;

    try {
      final response = await http
          .get(
            Uri.parse('$endpoint/health'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<JobResult<void>> execute(
    List<String> args, {
    void Function(JobProgress)? onProgress,
    Duration? totalDuration,
  }) async {
    if (endpoint.isEmpty) {
      return JobResult.failure(JobError(
        code: JobErrorCode.platformNotSupported,
        message: 'Remote endpoint not configured',
      ));
    }

    _isCancelled = false;

    try {
      // Extract input file path from args
      final inputIndex = args.indexOf('-i');
      if (inputIndex == -1 || inputIndex + 1 >= args.length) {
        return JobResult.failure(
            JobError.validation('No input file specified'));
      }

      final inputPath = args[inputIndex + 1];
      final inputFile = File(inputPath);

      if (!await inputFile.exists()) {
        return JobResult.failure(JobError(
          code: JobErrorCode.inputNotFound,
          message: 'Input file not found: $inputPath',
        ));
      }

      // Upload file and start job
      final request =
          http.MultipartRequest('POST', Uri.parse('$endpoint/process'));
      request.headers.addAll(_headers);
      request.files.add(await http.MultipartFile.fromPath('file', inputPath));
      request.fields['args'] = jsonEncode(args);

      onProgress
          ?.call(JobProgress(progress: 0.0, totalDuration: totalDuration));

      final uploadResponse = await request.send().timeout(timeout);
      final uploadBody = await uploadResponse.stream.bytesToString();

      if (uploadResponse.statusCode != 200 &&
          uploadResponse.statusCode != 201) {
        return JobResult.failure(JobError.ffmpegFailed(
          returnCode: uploadResponse.statusCode,
          output: uploadBody,
        ));
      }

      final uploadJson = jsonDecode(uploadBody) as Map<String, dynamic>;
      _currentJobId = uploadJson['jobId'] as String?;

      if (_currentJobId == null) {
        return JobResult.failure(JobError(
          code: JobErrorCode.ffmpegExecutionFailed,
          message: 'Server did not return job ID',
        ));
      }

      // Poll for progress
      while (!_isCancelled) {
        await Future.delayed(pollInterval);

        final statusResponse = await http
            .get(
              Uri.parse('$endpoint/process/$_currentJobId/status'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 30));

        if (statusResponse.statusCode != 200) {
          return JobResult.failure(JobError.ffmpegFailed(
            returnCode: statusResponse.statusCode,
            output: statusResponse.body,
          ));
        }

        final statusJson =
            jsonDecode(statusResponse.body) as Map<String, dynamic>;
        final status = statusJson['status'] as String?;
        final progress = (statusJson['progress'] as num?)?.toDouble() ?? 0.0;

        onProgress?.call(JobProgress(
          progress: progress,
          totalDuration: totalDuration,
        ));

        if (status == 'completed') {
          // Download result
          final outputPath = _extractOutputPath(args);
          if (outputPath != null) {
            await _downloadResult(_currentJobId!, outputPath);
          }
          _currentJobId = null;
          return JobResult.success();
        } else if (status == 'failed') {
          final error = statusJson['error'] as String?;
          _currentJobId = null;
          return JobResult.failure(JobError.ffmpegFailed(
            returnCode: -1,
            output: error ?? 'Processing failed',
          ));
        }
      }

      // Cancelled
      return JobResult.failure(JobError.cancelled());
    } catch (e, st) {
      _currentJobId = null;
      return JobResult.failure(JobError(
        code: JobErrorCode.ffmpegExecutionFailed,
        message: e.toString(),
        stackTrace: st,
      ));
    }
  }

  String? _extractOutputPath(List<String> args) {
    // Output is typically the last argument after -y
    final yIndex = args.indexOf('-y');
    if (yIndex != -1 && yIndex + 1 < args.length) {
      return args[yIndex + 1];
    }
    // Or just the last argument
    if (args.isNotEmpty && !args.last.startsWith('-')) {
      return args.last;
    }
    return null;
  }

  Future<void> _downloadResult(String jobId, String outputPath) async {
    final response = await http
        .get(
          Uri.parse('$endpoint/process/$jobId/result'),
          headers: _headers,
        )
        .timeout(timeout);

    if (response.statusCode == 200) {
      await File(outputPath).writeAsBytes(response.bodyBytes);
    }
  }

  @override
  Future<JobResult<ProbeResult>> probe(String filePath) async {
    if (endpoint.isEmpty) {
      return JobResult.failure(JobError(
        code: JobErrorCode.platformNotSupported,
        message: 'Remote endpoint not configured',
      ));
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return JobResult.failure(JobError(
          code: JobErrorCode.inputNotFound,
          message: 'File not found: $filePath',
        ));
      }

      final request =
          http.MultipartRequest('POST', Uri.parse('$endpoint/probe'));
      request.headers.addAll(_headers);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send().timeout(const Duration(minutes: 5));
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        return JobResult.failure(JobError.ffmpegFailed(
          returnCode: response.statusCode,
          output: body,
        ));
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
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
  Future<void> cancel() async {
    _isCancelled = true;

    if (_currentJobId != null && endpoint.isNotEmpty) {
      try {
        await http
            .delete(
              Uri.parse('$endpoint/process/$_currentJobId'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        // Ignore cancel errors
      }
      _currentJobId = null;
    }
  }

  @override
  void dispose() {
    cancel();
  }
}
