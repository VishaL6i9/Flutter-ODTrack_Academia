import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';

void main() {
  group('BaseError', () {
    test('should create BaseError with required fields', () {
      final error = BaseError(
        category: ErrorCategory.network,
        code: 'TEST_ERROR',
        message: 'Test error message',
      );

      expect(error.category, ErrorCategory.network);
      expect(error.code, 'TEST_ERROR');
      expect(error.message, 'Test error message');
      expect(error.severity, ErrorSeverity.medium);
      expect(error.isRetryable, false);
      expect(error.userMessage, isNull);
    });

    test('should create BaseError with all fields', () {
      final timestamp = DateTime.now();
      final context = {'key': 'value'};
      
      final error = BaseError(
        category: ErrorCategory.storage,
        code: 'STORAGE_ERROR',
        message: 'Storage error occurred',
        userMessage: 'Please try again',
        context: context,
        timestamp: timestamp,
        isRetryable: true,
        severity: ErrorSeverity.high,
        stackTrace: 'stack trace here',
      );

      expect(error.category, ErrorCategory.storage);
      expect(error.code, 'STORAGE_ERROR');
      expect(error.message, 'Storage error occurred');
      expect(error.userMessage, 'Please try again');
      expect(error.context, context);
      expect(error.timestamp, timestamp);
      expect(error.isRetryable, true);
      expect(error.severity, ErrorSeverity.high);
      expect(error.stackTrace, 'stack trace here');
    });

    test('should create copy with updated fields', () {
      final originalError = BaseError(
        category: ErrorCategory.network,
        code: 'ORIGINAL_ERROR',
        message: 'Original message',
      );

      final copiedError = originalError.copyWith(
        code: 'UPDATED_ERROR',
        message: 'Updated message',
        isRetryable: true,
      );

      expect(copiedError.category, ErrorCategory.network);
      expect(copiedError.code, 'UPDATED_ERROR');
      expect(copiedError.message, 'Updated message');
      expect(copiedError.isRetryable, true);
      expect(copiedError.severity, ErrorSeverity.medium);
    });

    test('should serialize to and from JSON', () {
      final error = BaseError(
        category: ErrorCategory.sync,
        code: 'SYNC_ERROR',
        message: 'Sync failed',
        userMessage: 'Please check connection',
        context: {'itemId': '123'},
        isRetryable: true,
        severity: ErrorSeverity.high,
      );

      final json = error.toJson();
      final deserializedError = BaseError.fromJson(json);

      expect(deserializedError.category, error.category);
      expect(deserializedError.code, error.code);
      expect(deserializedError.message, error.message);
      expect(deserializedError.userMessage, error.userMessage);
      expect(deserializedError.context, error.context);
      expect(deserializedError.isRetryable, error.isRetryable);
      expect(deserializedError.severity, error.severity);
    });

    test('toString should return formatted string', () {
      final error = BaseError(
        category: ErrorCategory.validation,
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        severity: ErrorSeverity.low,
      );

      final result = error.toString();
      expect(result, contains('BaseError'));
      expect(result, contains('validation'));
      expect(result, contains('VALIDATION_ERROR'));
      expect(result, contains('Invalid input'));
      expect(result, contains('low'));
    });
  });

  group('NetworkError', () {
    test('should create connection timeout error', () {
      final error = NetworkError.connectionTimeout(endpoint: '/api/test');

      expect(error.category, ErrorCategory.network);
      expect(error.code, 'NETWORK_TIMEOUT');
      expect(error.message, 'Network connection timeout');
      expect(error.userMessage, contains('Connection timed out'));
      expect(error.endpoint, '/api/test');
      expect(error.isRetryable, true);
      expect(error.severity, ErrorSeverity.medium);
    });

    test('should create no connection error', () {
      final error = NetworkError.noConnection();

      expect(error.category, ErrorCategory.network);
      expect(error.code, 'NO_CONNECTION');
      expect(error.message, 'No internet connection available');
      expect(error.userMessage, contains('No internet connection'));
      expect(error.isRetryable, true);
      expect(error.severity, ErrorSeverity.high);
    });

    test('should create server error with retryable status for 5xx', () {
      final error = NetworkError.serverError(500, endpoint: '/api/data');

      expect(error.category, ErrorCategory.network);
      expect(error.code, 'SERVER_ERROR');
      expect(error.message, 'Server returned error: 500');
      expect(error.statusCode, 500);
      expect(error.endpoint, '/api/data');
      expect(error.isRetryable, true);
      expect(error.severity, ErrorSeverity.high);
    });

    test('should create server error with non-retryable status for 4xx', () {
      final error = NetworkError.serverError(404, endpoint: '/api/notfound');

      expect(error.category, ErrorCategory.network);
      expect(error.code, 'SERVER_ERROR');
      expect(error.statusCode, 404);
      expect(error.isRetryable, false);
    });
  });

  group('StorageError', () {
    test('should create insufficient space error', () {
      final error = StorageError.insufficientSpace();

      expect(error.category, ErrorCategory.storage);
      expect(error.code, 'INSUFFICIENT_SPACE');
      expect(error.message, 'Insufficient storage space');
      expect(error.userMessage, contains('Not enough storage space'));
      expect(error.severity, ErrorSeverity.high);
    });

    test('should create corrupted data error', () {
      final error = StorageError.corruptedData('user_data');

      expect(error.category, ErrorCategory.storage);
      expect(error.code, 'CORRUPTED_DATA');
      expect(error.message, 'Data corruption detected for key: user_data');
      expect(error.key, 'user_data');
      expect(error.severity, ErrorSeverity.high);
    });
  });

  group('PermissionError', () {
    test('should create permission denied error', () {
      final error = PermissionError.denied('camera');

      expect(error.category, ErrorCategory.permission);
      expect(error.code, 'PERMISSION_DENIED');
      expect(error.message, 'Permission denied: camera');
      expect(error.permission, 'camera');
      expect(error.isRetryable, true);
      expect(error.severity, ErrorSeverity.medium);
    });

    test('should create permanently denied error', () {
      final error = PermissionError.permanentlyDenied('location');

      expect(error.category, ErrorCategory.permission);
      expect(error.code, 'PERMISSION_PERMANENTLY_DENIED');
      expect(error.permission, 'location');
      expect(error.isRetryable, false);
      expect(error.severity, ErrorSeverity.high);
    });
  });

  group('SyncError', () {
    test('should create conflict detected error', () {
      final error = SyncError.conflictDetected('123', 'ODRequest');

      expect(error.category, ErrorCategory.sync);
      expect(error.code, 'SYNC_CONFLICT');
      expect(error.itemId, '123');
      expect(error.itemType, 'ODRequest');
      expect(error.isRetryable, false);
      expect(error.severity, ErrorSeverity.medium);
    });

    test('should create sync failed error', () {
      final error = SyncError.syncFailed('Network timeout');

      expect(error.category, ErrorCategory.sync);
      expect(error.code, 'SYNC_FAILED');
      expect(error.message, 'Sync operation failed: Network timeout');
      expect(error.isRetryable, true);
    });
  });

  group('ValidationError', () {
    test('should create required field error', () {
      final error = ValidationError.required('email');

      expect(error.category, ErrorCategory.validation);
      expect(error.code, 'FIELD_REQUIRED');
      expect(error.field, 'email');
      expect(error.userMessage, 'This field is required.');
      expect(error.severity, ErrorSeverity.low);
    });

    test('should create invalid field error', () {
      final error = ValidationError.invalid('age', -5, 'Age must be positive');

      expect(error.category, ErrorCategory.validation);
      expect(error.code, 'FIELD_INVALID');
      expect(error.field, 'age');
      expect(error.value, -5);
      expect(error.userMessage, 'Invalid value. Age must be positive');
      expect(error.severity, ErrorSeverity.low);
    });
  });

  group('BaseErrorExtension', () {
    test('shouldNotifyUser should return true for high and critical severity', () {
      final highError = BaseError(
        category: ErrorCategory.network,
        code: 'HIGH_ERROR',
        message: 'High severity error',
        severity: ErrorSeverity.high,
      );

      final criticalError = BaseError(
        category: ErrorCategory.storage,
        code: 'CRITICAL_ERROR',
        message: 'Critical error',
        severity: ErrorSeverity.critical,
      );

      final lowError = BaseError(
        category: ErrorCategory.validation,
        code: 'LOW_ERROR',
        message: 'Low severity error',
        severity: ErrorSeverity.low,
      );

      expect(highError.shouldNotifyUser, true);
      expect(criticalError.shouldNotifyUser, true);
      expect(lowError.shouldNotifyUser, false);
    });

    test('displayMessage should return userMessage if available, otherwise message', () {
      final errorWithUserMessage = BaseError(
        category: ErrorCategory.network,
        code: 'ERROR_WITH_USER_MSG',
        message: 'Technical message',
        userMessage: 'User-friendly message',
      );

      final errorWithoutUserMessage = BaseError(
        category: ErrorCategory.storage,
        code: 'ERROR_WITHOUT_USER_MSG',
        message: 'Technical message only',
      );

      expect(errorWithUserMessage.displayMessage, 'User-friendly message');
      expect(errorWithoutUserMessage.displayMessage, 'Technical message only');
    });

    test('isRecent should return true for errors within 5 minutes', () {
      final recentError = BaseError(
        category: ErrorCategory.sync,
        code: 'RECENT_ERROR',
        message: 'Recent error',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      );

      final oldError = BaseError(
        category: ErrorCategory.sync,
        code: 'OLD_ERROR',
        message: 'Old error',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      expect(recentError.isRecent, true);
      expect(oldError.isRecent, false);
    });
  });
}