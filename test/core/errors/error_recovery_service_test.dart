import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';
import 'package:odtrack_academia/core/errors/error_recovery_service.dart';

void main() {
  group('ErrorRecoveryService', () {
    late ErrorRecoveryService errorRecoveryService;

    setUp(() {
      errorRecoveryService = ErrorRecoveryService.instance;
    });

    test('should be singleton', () {
      final instance1 = ErrorRecoveryService.instance;
      final instance2 = ErrorRecoveryService.instance;
      expect(identical(instance1, instance2), true);
    });

    group('handleNetworkError', () {
      test('should handle network timeout error', () async {
        final error = NetworkError.connectionTimeout(endpoint: '/api/test');
        
        // Should not throw
        await expectLater(
          errorRecoveryService.handleNetworkError(error),
          completes,
        );
      });

      test('should handle no connection error', () async {
        final error = NetworkError.noConnection();
        
        await expectLater(
          errorRecoveryService.handleNetworkError(error),
          completes,
        );
      });

      test('should handle server error', () async {
        final error = NetworkError.serverError(500, endpoint: '/api/data');
        
        await expectLater(
          errorRecoveryService.handleNetworkError(error),
          completes,
        );
      });
    });

    group('handleStorageError', () {
      test('should handle insufficient space error', () async {
        final error = StorageError.insufficientSpace();
        
        await expectLater(
          errorRecoveryService.handleStorageError(error),
          completes,
        );
      });

      test('should handle corrupted data error', () async {
        final error = StorageError.corruptedData('test_key');
        
        await expectLater(
          errorRecoveryService.handleStorageError(error),
          completes,
        );
      });
    });

    group('handlePermissionError', () {
      test('should handle permission denied error', () async {
        final error = PermissionError.denied('camera');
        
        await expectLater(
          errorRecoveryService.handlePermissionError(error),
          completes,
        );
      });
    });

    group('handleSyncError', () {
      test('should handle sync conflict error', () async {
        final error = SyncError.conflictDetected('123', 'ODRequest');
        
        await expectLater(
          errorRecoveryService.handleSyncError(error),
          completes,
        );
      });

      test('should handle sync failed error', () async {
        final error = SyncError.syncFailed('Network timeout');
        
        await expectLater(
          errorRecoveryService.handleSyncError(error),
          completes,
        );
      });
    });

    group('retryWithBackoff', () {
      test('should succeed on first attempt', () async {
        int callCount = 0;
        
        final result = await errorRecoveryService.retryWithBackoff<String>(
          () async {
            callCount++;
            return 'success';
          },
        );

        expect(result, 'success');
        expect(callCount, 1);
      });

      test('should retry on failure and eventually succeed', () async {
        int callCount = 0;
        
        final result = await errorRecoveryService.retryWithBackoff<String>(
          () async {
            callCount++;
            if (callCount < 3) {
              throw NetworkError.connectionTimeout();
            }
            return 'success';
          },
          maxRetries: 3,
          initialDelay: const Duration(milliseconds: 10),
        );

        expect(result, 'success');
        expect(callCount, 3);
      });

      test('should fail after max retries', () async {
        int callCount = 0;
        
        await expectLater(
          errorRecoveryService.retryWithBackoff<String>(
            () async {
              callCount++;
              throw NetworkError.connectionTimeout();
            },
            maxRetries: 2,
            initialDelay: const Duration(milliseconds: 10),
          ),
          throwsA(isA<NetworkError>()),
        );

        expect(callCount, 2);
      });

      test('should not retry non-retryable errors', () async {
        int callCount = 0;
        
        await expectLater(
          errorRecoveryService.retryWithBackoff<String>(
            () async {
              callCount++;
              throw PermissionError.permanentlyDenied('camera');
            },
            maxRetries: 3,
            initialDelay: const Duration(milliseconds: 10),
          ),
          throwsA(isA<PermissionError>()),
        );

        expect(callCount, 1);
      });

      test('should apply exponential backoff', () async {
        int callCount = 0;
        final stopwatch = Stopwatch()..start();
        
        try {
          await errorRecoveryService.retryWithBackoff<String>(
            () async {
              callCount++;
              throw NetworkError.connectionTimeout();
            },
            maxRetries: 3,
            initialDelay: const Duration(milliseconds: 100),
            backoffMultiplier: 2.0,
          );
        } catch (e) {
          // Expected to fail
        }

        stopwatch.stop();
        expect(callCount, 3);
        // Should take at least 100ms + 200ms = 300ms for the delays
        expect(stopwatch.elapsedMilliseconds, greaterThan(250));
      });
    });

    group('retryWithLinearBackoff', () {
      test('should succeed on first attempt', () async {
        int callCount = 0;
        
        final result = await errorRecoveryService.retryWithLinearBackoff<String>(
          () async {
            callCount++;
            return 'success';
          },
        );

        expect(result, 'success');
        expect(callCount, 1);
      });

      test('should retry with linear delay', () async {
        int callCount = 0;
        final stopwatch = Stopwatch()..start();
        
        try {
          await errorRecoveryService.retryWithLinearBackoff<String>(
            () async {
              callCount++;
              throw NetworkError.connectionTimeout();
            },
            maxRetries: 2,
            delay: const Duration(milliseconds: 100),
          );
        } catch (e) {
          // Expected to fail
        }

        stopwatch.stop();
        expect(callCount, 2);
        // Should take at least 100ms for one delay
        expect(stopwatch.elapsedMilliseconds, greaterThan(80));
      });
    });

    group('isRecoverable', () {
      test('should return true for retryable errors with non-critical severity', () {
        final error = NetworkError.connectionTimeout();
        expect(errorRecoveryService.isRecoverable(error), true);
      });

      test('should return false for non-retryable errors', () {
        final error = PermissionError.permanentlyDenied('camera');
        expect(errorRecoveryService.isRecoverable(error), false);
      });

      test('should return false for critical errors', () {
        final error = BaseError(
          category: ErrorCategory.storage,
          code: 'CRITICAL_ERROR',
          message: 'Critical error',
          severity: ErrorSeverity.critical,
          isRetryable: true,
        );
        expect(errorRecoveryService.isRecoverable(error), false);
      });
    });

    group('getRecoveryAction', () {
      test('should return appropriate action for network errors', () {
        final error = NetworkError.connectionTimeout();
        final action = errorRecoveryService.getRecoveryAction(error);
        expect(action, contains('internet connection'));
      });

      test('should return appropriate action for storage errors', () {
        final error = StorageError.insufficientSpace();
        final action = errorRecoveryService.getRecoveryAction(error);
        expect(action, contains('storage space'));
      });

      test('should return appropriate action for permission errors', () {
        final error = PermissionError.denied('camera');
        final action = errorRecoveryService.getRecoveryAction(error);
        expect(action, contains('permission'));
      });

      test('should return appropriate action for sync errors', () {
        final error = SyncError.syncFailed('Network timeout');
        final action = errorRecoveryService.getRecoveryAction(error);
        expect(action, contains('retry automatically'));
      });

      test('should return appropriate action for validation errors', () {
        final error = ValidationError.required('email');
        final action = errorRecoveryService.getRecoveryAction(error);
        expect(action, contains('correct the input'));
      });

      test('should return generic action for unknown errors', () {
        final error = BaseError(
          category: ErrorCategory.unknown,
          code: 'UNKNOWN_ERROR',
          message: 'Unknown error',
        );
        final action = errorRecoveryService.getRecoveryAction(error);
        expect(action, contains('try again'));
      });
    });
  });
}