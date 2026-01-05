import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_cube/ffmpeg_cube.dart';

/// Backend Router 測試
void main() {
  group('BackendRouter', () {
    test('Creates BackendRouter with default preferences', () {
      final router = BackendRouter();
      
      expect(router, isNotNull);
    });

    test('BackendRouter with remote backup configured', () {
      final router = BackendRouter(
        remoteEndpoint: 'https://api.example.com',
      );
      
      expect(router, isNotNull);
    });

    test('Preferred backend can be set', () {
      final router = BackendRouter(
        preferredBackend: BackendType.remote,
        remoteEndpoint: 'https://api.example.com',
      );
      
      expect(router, isNotNull);
    });

    test('BackendRouter with ffmpegPath', () {
      final router = BackendRouter(
        ffmpegPath: '/usr/bin/ffmpeg',
      );
      
      expect(router, isNotNull);
    });

    test('Dispose cleans up resources', () {
      final router = BackendRouter();
      router.dispose(); // Should not throw
      expect(true, true);
    });
  });

  group('BackendType Enum', () {
    test('All backend types are defined', () {
      expect(BackendType.ffmpegKit, isNotNull);
      expect(BackendType.process, isNotNull);
      expect(BackendType.wasm, isNotNull);
      expect(BackendType.remote, isNotNull);
    });

    test('Backend types have correct names', () {
      expect(BackendType.ffmpegKit.name, 'ffmpegKit');
      expect(BackendType.process.name, 'process');
      expect(BackendType.wasm.name, 'wasm');
      expect(BackendType.remote.name, 'remote');
    });
  });

  group('JobResult', () {
    test('Success result', () {
      final result = JobResult<String>.success(data: 'test');
      
      expect(result.success, true);
      expect(result.data, 'test');
      expect(result.error, isNull);
    });

    test('Failure result', () {
      final result = JobResult<String>.failure(
        JobError.validation('Invalid'),
      );
      
      expect(result.success, false);
      expect(result.data, isNull);
      expect(result.error, isNotNull);
      expect(result.error!.code, JobErrorCode.invalidParameters);
    });

    test('Success without data', () {
      final result = JobResult<void>.success();
      
      expect(result.success, true);
    });
  });

  group('JobError Types', () {
    test('Validation error', () {
      final error = JobError.validation('Bad input');
      
      expect(error.code, JobErrorCode.invalidParameters);
      expect(error.message, contains('Bad input'));
    });

    test('Cancelled error', () {
      final error = JobError.cancelled();
      
      expect(error.code, JobErrorCode.cancelled);
    });

    test('Platform not supported error', () {
      final error = JobError.platformNotSupported('TestPlatform');
      
      expect(error.code, JobErrorCode.platformNotSupported);
      expect(error.message, contains('TestPlatform'));
    });

    test('FFmpeg failed error', () {
      final error = JobError.ffmpegFailed(
        returnCode: 1,
        output: 'Error output',
      );
      
      expect(error.code, JobErrorCode.ffmpegExecutionFailed);
      // Message contains error info
      expect(error.message, isNotEmpty);
    });

    test('Input not found error', () {
      final error = JobError(
        code: JobErrorCode.inputNotFound,
        message: 'File not found',
      );
      
      expect(error.code, JobErrorCode.inputNotFound);
    });

    test('Error with stack trace', () {
      final error = JobError(
        code: JobErrorCode.unknown,
        message: 'Unknown error',
        stackTrace: StackTrace.current,
      );
      
      expect(error.stackTrace, isNotNull);
    });
  });
}
