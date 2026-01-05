/// Error codes for job failures
enum JobErrorCode {
  /// Input file not found
  inputNotFound,
  /// Output path is not writable
  outputNotWritable,
  /// Unsupported format
  unsupportedFormat,
  /// Codec not available
  codecNotAvailable,
  /// FFmpeg execution failed
  ffmpegExecutionFailed,
  /// Job was cancelled
  cancelled,
  /// Invalid parameters
  invalidParameters,
  /// Out of memory
  outOfMemory,
  /// Platform not supported
  platformNotSupported,
  /// Permission denied
  permissionDenied,
  /// Unknown error
  unknown,
}

/// Exception thrown when a job fails
class JobError implements Exception {
  /// Error code
  final JobErrorCode code;
  
  /// Human-readable error message
  final String message;
  
  /// Detailed description (may include FFmpeg output)
  final String? details;
  
  /// FFmpeg return code (if applicable)
  final int? ffmpegReturnCode;
  
  /// Stack trace when error occurred
  final StackTrace? stackTrace;
  
  JobError({
    required this.code,
    required this.message,
    this.details,
    this.ffmpegReturnCode,
    this.stackTrace,
  });
  
  @override
  String toString() {
    var result = 'JobError(${code.name}): $message';
    if (ffmpegReturnCode != null) {
      result += ' [FFmpeg return code: $ffmpegReturnCode]';
    }
    if (details != null) {
      result += '\nDetails: $details';
    }
    return result;
  }
  
  /// Create from FFmpeg execution failure
  factory JobError.ffmpegFailed({
    required int returnCode,
    required String output,
  }) {
    String message;
    JobErrorCode code = JobErrorCode.ffmpegExecutionFailed;
    
    // Try to parse common FFmpeg errors
    if (output.contains('No such file or directory')) {
      code = JobErrorCode.inputNotFound;
      message = 'Input file not found';
    } else if (output.contains('Permission denied')) {
      code = JobErrorCode.permissionDenied;
      message = 'Permission denied';
    } else if (output.contains('Unknown encoder') || output.contains('Encoder not found')) {
      code = JobErrorCode.codecNotAvailable;
      message = 'Required codec is not available';
    } else if (output.contains('Invalid data found')) {
      code = JobErrorCode.unsupportedFormat;
      message = 'Invalid or unsupported input format';
    } else if (output.contains('Out of memory')) {
      code = JobErrorCode.outOfMemory;
      message = 'Out of memory during processing';
    } else {
      message = 'FFmpeg execution failed';
    }
    
    return JobError(
      code: code,
      message: message,
      details: output,
      ffmpegReturnCode: returnCode,
    );
  }
  
  /// Create from validation failure
  factory JobError.validation(String reason) {
    return JobError(
      code: JobErrorCode.invalidParameters,
      message: 'Invalid job parameters: $reason',
    );
  }
  
  /// Create for platform not supported
  factory JobError.platformNotSupported(String platform) {
    return JobError(
      code: JobErrorCode.platformNotSupported,
      message: 'This operation is not supported on $platform',
    );
  }
  
  /// Create for cancelled job
  factory JobError.cancelled() {
    return JobError(
      code: JobErrorCode.cancelled,
      message: 'Job was cancelled',
    );
  }
}

/// Result of a job execution
class JobResult<T> {
  /// Whether the job succeeded
  final bool success;
  
  /// Result data (if successful)
  final T? data;
  
  /// Error (if failed)
  final JobError? error;
  
  /// Execution duration
  final Duration? executionTime;
  
  /// Output path (if applicable)
  final String? outputPath;
  
  JobResult._({
    required this.success,
    this.data,
    this.error,
    this.executionTime,
    this.outputPath,
  });
  
  /// Create a successful result
  factory JobResult.success({
    T? data,
    Duration? executionTime,
    String? outputPath,
  }) {
    return JobResult._(
      success: true,
      data: data,
      executionTime: executionTime,
      outputPath: outputPath,
    );
  }
  
  /// Create a failed result
  factory JobResult.failure(JobError error) {
    return JobResult._(
      success: false,
      error: error,
    );
  }
  
  /// Get data or throw error
  T get dataOrThrow {
    if (success && data != null) {
      return data as T;
    }
    throw error ?? JobError(
      code: JobErrorCode.unknown,
      message: 'No data available',
    );
  }
}
