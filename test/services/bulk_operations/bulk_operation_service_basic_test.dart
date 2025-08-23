import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/models/bulk_operation_models.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/services/bulk_operations/bulk_operation_service.dart';
import 'package:odtrack_academia/services/bulk_operations/hive_bulk_operation_service.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';

void main() {
  group('BulkOperationService Interface', () {
    test('should define all required methods', () {
      // This test verifies that the interface is properly defined
      expect(BulkOperationService, isA<Type>());
      
      // Check that HiveBulkOperationService implements the interface
      final service = HiveBulkOperationService();
      expect(service, isA<BulkOperationService>());
    });

    test('should have correct method signatures', () {
      final service = HiveBulkOperationService();
      
      // Check that methods exist and return correct types
      expect(service.initialize, isA<Function>());
      expect(service.performBulkApproval, isA<Function>());
      expect(service.performBulkRejection, isA<Function>());
      expect(service.performBulkExport, isA<Function>());
      expect(service.progressStream, isA<Stream<BulkOperationProgress>>());
      expect(service.cancelBulkOperation, isA<Function>());
      expect(service.getBulkOperationHistory, isA<Function>());
      expect(service.undoLastBulkOperation, isA<Function>());
      expect(service.canUndoBulkOperation, isA<Function>());
      expect(service.maxBatchSize, isA<int>());
    });

    test('should have reasonable max batch size', () {
      final service = HiveBulkOperationService();
      expect(service.maxBatchSize, greaterThan(0));
      expect(service.maxBatchSize, lessThanOrEqualTo(1000)); // Reasonable upper limit
    });
  });

  group('BulkOperationService Error Handling', () {
    test('should handle validation errors for empty request list', () async {
      final service = HiveBulkOperationService();
      
      // Should throw validation error for empty list
      expect(
        () => service.performBulkApproval([], 'test reason'),
        throwsA(isA<ValidationError>()),
      );
    });

    test('should handle validation errors for empty reason', () async {
      final service = HiveBulkOperationService();
      
      // Should throw validation error for empty reason
      expect(
        () => service.performBulkApproval(['req1'], ''),
        throwsA(isA<ValidationError>()),
      );
    });

    test('should handle validation errors for oversized batch', () async {
      final service = HiveBulkOperationService();
      final oversizedList = List.generate(service.maxBatchSize + 1, (i) => 'req$i');
      
      // Should throw validation error for oversized batch
      expect(
        () => service.performBulkApproval(oversizedList, 'test reason'),
        throwsA(isA<ValidationError>()),
      );
    });
  });

  group('BulkOperationType Enum', () {
    test('should have all required operation types', () {
      const types = BulkOperationType.values;
      expect(types, contains(BulkOperationType.approval));
      expect(types, contains(BulkOperationType.rejection));
      expect(types, contains(BulkOperationType.export));
    });

    test('should be serializable', () {
      for (final type in BulkOperationType.values) {
        expect(type.toString(), isNotEmpty);
      }
    });
  });

  group('ExportFormat Integration', () {
    test('should work with all export formats', () {
      // Verify that all export formats are supported
      for (final format in ExportFormat.values) {
        expect(format, isA<ExportFormat>());
        expect(format.toString(), isNotEmpty);
      }
    });
  });

  group('Progress Tracking', () {
    test('should provide progress stream', () {
      final service = HiveBulkOperationService();
      expect(service.progressStream, isA<Stream<BulkOperationProgress>>());
    });

    test('should handle progress updates correctly', () {
      const progress = BulkOperationProgress(
        operationId: 'test_op',
        progress: 0.5,
        processedItems: 5,
        totalItems: 10,
        currentItem: 'item_5',
        message: 'Processing item 5',
      );

      expect(progress.operationId, equals('test_op'));
      expect(progress.progress, equals(0.5));
      expect(progress.processedItems, equals(5));
      expect(progress.totalItems, equals(10));
      expect(progress.currentItem, equals('item_5'));
      expect(progress.message, equals('Processing item 5'));
    });
  });

  group('Operation Results', () {
    test('should create valid operation results', () {
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(minutes: 1));
      
      final result = BulkOperationResult(
        operationId: 'test_result',
        type: BulkOperationType.approval,
        totalItems: 10,
        successfulItems: 8,
        failedItems: 2,
        errors: ['Error 1', 'Error 2'],
        startTime: startTime,
        endTime: endTime,
        canUndo: true,
      );

      expect(result.operationId, equals('test_result'));
      expect(result.type, equals(BulkOperationType.approval));
      expect(result.totalItems, equals(10));
      expect(result.successfulItems, equals(8));
      expect(result.failedItems, equals(2));
      expect(result.errors, hasLength(2));
      expect(result.startTime, equals(startTime));
      expect(result.endTime, equals(endTime));
      expect(result.canUndo, isTrue);
    });

    test('should validate result consistency', () {
      final result = BulkOperationResult(
        operationId: 'consistency_test',
        type: BulkOperationType.rejection,
        totalItems: 15,
        successfulItems: 12,
        failedItems: 3,
        errors: ['Error 1', 'Error 2', 'Error 3'],
        startTime: DateTime.now(),
      );

      // Verify that successful + failed = total
      expect(result.successfulItems + result.failedItems, equals(result.totalItems));
      
      // Verify that error count matches failed items
      expect(result.errors.length, equals(result.failedItems));
    });
  });
}