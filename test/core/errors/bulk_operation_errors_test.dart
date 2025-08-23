import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';
import 'package:odtrack_academia/core/errors/bulk_operation_errors.dart';

void main() {
  group('BulkOperationError', () {
    test('should create basic bulk operation error', () {
      final error = BulkOperationError(
        code: 'TEST_ERROR',
        message: 'Test error message',
        userMessage: 'User-friendly error message',
        operationId: 'test_op_123',
      );

      expect(error.code, equals('TEST_ERROR'));
      expect(error.message, equals('Test error message'));
      expect(error.userMessage, equals('User-friendly error message'));
      expect(error.operationId, equals('test_op_123'));
      expect(error.category, equals(ErrorCategory.unknown));
      expect(error.isRetryable, isFalse);
      expect(error.severity, equals(ErrorSeverity.medium));
    });

    test('should create operation cancelled error', () {
      final error = BulkOperationError.operationCancelled('cancelled_op_456');

      expect(error.code, equals('BULK_OPERATION_CANCELLED'));
      expect(error.message, contains('cancelled_op_456'));
      expect(error.userMessage, equals('Operation was cancelled by user.'));
      expect(error.operationId, equals('cancelled_op_456'));
      expect(error.isRetryable, isFalse);
      expect(error.severity, equals(ErrorSeverity.low));
    });

    test('should create batch size exceeded error', () {
      final error = BulkOperationError.batchSizeExceeded(150, 100);

      expect(error.code, equals('BATCH_SIZE_EXCEEDED'));
      expect(error.message, contains('150'));
      expect(error.message, contains('100'));
      expect(error.userMessage, contains('100 items'));
      expect(error.isRetryable, isFalse);
      expect(error.severity, equals(ErrorSeverity.medium));
    });

    test('should create operation in progress error', () {
      final error = BulkOperationError.operationInProgress('active_op_789');

      expect(error.code, equals('OPERATION_IN_PROGRESS'));
      expect(error.message, contains('active_op_789'));
      expect(error.userMessage, contains('Another operation is in progress'));
      expect(error.operationId, equals('active_op_789'));
      expect(error.isRetryable, isTrue);
      expect(error.severity, equals(ErrorSeverity.medium));
    });

    test('should create partial failure error', () {
      final errors = ['Error 1', 'Error 2', 'Error 3'];
      final error = BulkOperationError.partialFailure(
        'partial_op_101',
        7,
        3,
        errors,
      );

      expect(error.code, equals('PARTIAL_FAILURE'));
      expect(error.message, contains('7 successful'));
      expect(error.message, contains('3 failed'));
      expect(error.userMessage, contains('7 items processed successfully'));
      expect(error.userMessage, contains('3 failed'));
      expect(error.operationId, equals('partial_op_101'));
      expect(error.processedItems, equals(7));
      expect(error.totalItems, equals(10));
      expect(error.context?['errors'], equals(errors));
      expect(error.isRetryable, isFalse);
      expect(error.severity, equals(ErrorSeverity.medium));
    });

    test('should create undo not available error', () {
      final error = BulkOperationError.undoNotAvailable(
        'no_undo_op_202',
        'Operation was an export',
      );

      expect(error.code, equals('UNDO_NOT_AVAILABLE'));
      expect(error.message, contains('no_undo_op_202'));
      expect(error.message, contains('Operation was an export'));
      expect(error.userMessage, contains('Cannot undo this operation'));
      expect(error.userMessage, contains('Operation was an export'));
      expect(error.operationId, equals('no_undo_op_202'));
      expect(error.isRetryable, isFalse);
      expect(error.severity, equals(ErrorSeverity.low));
    });

    test('should create undo time limit exceeded error', () {
      final error = BulkOperationError.undoTimeLimitExceeded('expired_op_303');

      expect(error.code, equals('UNDO_TIME_LIMIT_EXCEEDED'));
      expect(error.message, contains('expired_op_303'));
      expect(error.userMessage, contains('Time limit exceeded'));
      expect(error.operationId, equals('expired_op_303'));
      expect(error.isRetryable, isFalse);
      expect(error.severity, equals(ErrorSeverity.low));
    });

    test('should create invalid request state error', () {
      final error = BulkOperationError.invalidRequestState(
        'req_404',
        'approved',
        'pending',
      );

      expect(error.code, equals('INVALID_REQUEST_STATE'));
      expect(error.message, contains('req_404'));
      expect(error.message, contains('approved'));
      expect(error.message, contains('pending'));
      expect(error.userMessage, contains('cannot be processed due to their current state'));
      expect(error.context?['requestId'], equals('req_404'));
      expect(error.context?['currentState'], equals('approved'));
      expect(error.context?['requiredState'], equals('pending'));
      expect(error.isRetryable, isFalse);
      expect(error.severity, equals(ErrorSeverity.low));
    });

    test('should create export failed error', () {
      final error = BulkOperationError.exportFailed(
        'export_op_505',
        'Insufficient storage space',
      );

      expect(error.code, equals('EXPORT_FAILED'));
      expect(error.message, contains('Insufficient storage space'));
      expect(error.userMessage, contains('Export failed'));
      expect(error.userMessage, contains('check available storage'));
      expect(error.operationId, equals('export_op_505'));
      expect(error.isRetryable, isTrue);
      expect(error.severity, equals(ErrorSeverity.medium));
    });

    test('should create storage error', () {
      final error = BulkOperationError.storageError(
        'storage_op_606',
        'write operation',
      );

      expect(error.code, equals('BULK_STORAGE_ERROR'));
      expect(error.message, contains('write operation'));
      expect(error.userMessage, contains('Storage error occurred'));
      expect(error.userMessage, contains('check available space'));
      expect(error.operationId, equals('storage_op_606'));
      expect(error.isRetryable, isTrue);
      expect(error.severity, equals(ErrorSeverity.high));
    });

    test('should inherit from BaseError correctly', () {
      final error = BulkOperationError(
        code: 'INHERITANCE_TEST',
        message: 'Testing inheritance',
        operationId: 'inherit_op_707',
      );

      expect(error, isA<BaseError>());
      expect(error, isA<Exception>());
      expect(error.timestamp, isA<DateTime>());
      expect(error.toString(), contains('INHERITANCE_TEST'));
    });

    test('should handle optional fields correctly', () {
      final error = BulkOperationError(
        code: 'OPTIONAL_TEST',
        message: 'Testing optional fields',
      );

      expect(error.operationId, isNull);
      expect(error.processedItems, isNull);
      expect(error.totalItems, isNull);
      expect(error.userMessage, isNull);
      expect(error.context, isNull);
      expect(error.stackTrace, isNull);
    });

    test('should handle all optional constructor parameters', () {
      final timestamp = DateTime.now();
      final context = {'key': 'value'};
      
      final error = BulkOperationError(
        code: 'FULL_TEST',
        message: 'Testing all parameters',
        userMessage: 'User message',
        context: context,
        timestamp: timestamp,
        isRetryable: true,
        severity: ErrorSeverity.high,
        stackTrace: 'Stack trace here',
        operationId: 'full_op_808',
        processedItems: 5,
        totalItems: 10,
      );

      expect(error.code, equals('FULL_TEST'));
      expect(error.message, equals('Testing all parameters'));
      expect(error.userMessage, equals('User message'));
      expect(error.context, equals(context));
      expect(error.timestamp, equals(timestamp));
      expect(error.isRetryable, isTrue);
      expect(error.severity, equals(ErrorSeverity.high));
      expect(error.stackTrace, equals('Stack trace here'));
      expect(error.operationId, equals('full_op_808'));
      expect(error.processedItems, equals(5));
      expect(error.totalItems, equals(10));
    });
  });

  group('Error Factory Methods', () {
    test('should create appropriate error types for different scenarios', () {
      // Test cancellation scenario
      final cancelError = BulkOperationError.operationCancelled('test_op');
      expect(cancelError.severity, equals(ErrorSeverity.low));
      expect(cancelError.isRetryable, isFalse);

      // Test validation scenario
      final batchError = BulkOperationError.batchSizeExceeded(200, 100);
      expect(batchError.severity, equals(ErrorSeverity.medium));
      expect(batchError.isRetryable, isFalse);

      // Test retry scenario
      final progressError = BulkOperationError.operationInProgress('active_op');
      expect(progressError.severity, equals(ErrorSeverity.medium));
      expect(progressError.isRetryable, isTrue);

      // Test storage scenario
      final storageError = BulkOperationError.storageError('op', 'write');
      expect(storageError.severity, equals(ErrorSeverity.high));
      expect(storageError.isRetryable, isTrue);
    });

    test('should provide meaningful error messages', () {
      final errors = [
        BulkOperationError.operationCancelled('op1'),
        BulkOperationError.batchSizeExceeded(150, 100),
        BulkOperationError.operationInProgress('op2'),
        BulkOperationError.partialFailure('op3', 5, 2, ['error1', 'error2']),
        BulkOperationError.undoNotAvailable('op4', 'export operation'),
        BulkOperationError.undoTimeLimitExceeded('op5'),
        BulkOperationError.invalidRequestState('req1', 'approved', 'pending'),
        BulkOperationError.exportFailed('op6', 'no space'),
        BulkOperationError.storageError('op7', 'read'),
      ];

      for (final error in errors) {
        expect(error.message, isNotEmpty);
        expect(error.userMessage, isNotEmpty);
        expect(error.code, isNotEmpty);
      }
    });
  });

  group('Error Context and Metadata', () {
    test('should preserve operation context in partial failure', () {
      final errorList = ['Network timeout', 'Invalid data', 'Permission denied'];
      final error = BulkOperationError.partialFailure('ctx_op', 7, 3, errorList);

      expect(error.context, isNotNull);
      expect(error.context!['errors'], equals(errorList));
      expect(error.processedItems, equals(7));
      expect(error.totalItems, equals(10));
    });

    test('should preserve request context in invalid state error', () {
      final error = BulkOperationError.invalidRequestState('req123', 'rejected', 'pending');

      expect(error.context, isNotNull);
      expect(error.context!['requestId'], equals('req123'));
      expect(error.context!['currentState'], equals('rejected'));
      expect(error.context!['requiredState'], equals('pending'));
    });

    test('should handle missing context gracefully', () {
      final error = BulkOperationError(
        code: 'NO_CONTEXT',
        message: 'No context provided',
      );

      expect(error.context, isNull);
      expect(() => error.toString(), returnsNormally);
    });
  });
}