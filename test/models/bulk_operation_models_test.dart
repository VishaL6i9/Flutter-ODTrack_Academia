import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/models/bulk_operation_models.dart';

void main() {
  group('BulkOperationResult', () {
    test('should create instance with required fields', () {
      final startTime = DateTime.now();
      final result = BulkOperationResult(
        operationId: 'test_op_123',
        type: BulkOperationType.approval,
        totalItems: 10,
        successfulItems: 8,
        failedItems: 2,
        errors: ['Error 1', 'Error 2'],
        startTime: startTime,
      );

      expect(result.operationId, equals('test_op_123'));
      expect(result.type, equals(BulkOperationType.approval));
      expect(result.totalItems, equals(10));
      expect(result.successfulItems, equals(8));
      expect(result.failedItems, equals(2));
      expect(result.errors, hasLength(2));
      expect(result.startTime, equals(startTime));
      expect(result.endTime, isNull);
      expect(result.canUndo, isFalse);
    });

    test('should create instance with optional fields', () {
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(minutes: 5));
      
      final result = BulkOperationResult(
        operationId: 'test_op_456',
        type: BulkOperationType.rejection,
        totalItems: 5,
        successfulItems: 5,
        failedItems: 0,
        errors: [],
        startTime: startTime,
        endTime: endTime,
        canUndo: true,
      );

      expect(result.endTime, equals(endTime));
      expect(result.canUndo, isTrue);
      expect(result.errors, isEmpty);
    });

    test('should serialize to and from JSON correctly', () {
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(minutes: 2));
      
      final original = BulkOperationResult(
        operationId: 'test_op_789',
        type: BulkOperationType.export,
        totalItems: 15,
        successfulItems: 12,
        failedItems: 3,
        errors: ['Export error 1', 'Export error 2'],
        startTime: startTime,
        endTime: endTime,
        canUndo: false,
      );

      final json = original.toJson();
      final restored = BulkOperationResult.fromJson(json);

      expect(restored.operationId, equals(original.operationId));
      expect(restored.type, equals(original.type));
      expect(restored.totalItems, equals(original.totalItems));
      expect(restored.successfulItems, equals(original.successfulItems));
      expect(restored.failedItems, equals(original.failedItems));
      expect(restored.errors, equals(original.errors));
      expect(restored.startTime, equals(original.startTime));
      expect(restored.endTime, equals(original.endTime));
      expect(restored.canUndo, equals(original.canUndo));
    });

    test('should handle null endTime in JSON serialization', () {
      final result = BulkOperationResult(
        operationId: 'test_op_null',
        type: BulkOperationType.approval,
        totalItems: 1,
        successfulItems: 1,
        failedItems: 0,
        errors: [],
        startTime: DateTime.now(),
        endTime: null,
      );

      final json = result.toJson();
      final restored = BulkOperationResult.fromJson(json);

      expect(restored.endTime, isNull);
    });
  });

  group('BulkOperationProgress', () {
    test('should create instance with required fields', () {
      const progress = BulkOperationProgress(
        operationId: 'progress_test_123',
        progress: 0.75,
        processedItems: 15,
        totalItems: 20,
        currentItem: 'item_15',
      );

      expect(progress.operationId, equals('progress_test_123'));
      expect(progress.progress, equals(0.75));
      expect(progress.processedItems, equals(15));
      expect(progress.totalItems, equals(20));
      expect(progress.currentItem, equals('item_15'));
      expect(progress.message, isNull);
    });

    test('should create instance with optional message', () {
      const progress = BulkOperationProgress(
        operationId: 'progress_test_456',
        progress: 1.0,
        processedItems: 10,
        totalItems: 10,
        currentItem: 'item_10',
        message: 'Operation completed successfully',
      );

      expect(progress.message, equals('Operation completed successfully'));
    });

    test('should serialize to and from JSON correctly', () {
      const original = BulkOperationProgress(
        operationId: 'progress_json_test',
        progress: 0.5,
        processedItems: 5,
        totalItems: 10,
        currentItem: 'item_5',
        message: 'Processing item 5 of 10',
      );

      final json = original.toJson();
      final restored = BulkOperationProgress.fromJson(json);

      expect(restored.operationId, equals(original.operationId));
      expect(restored.progress, equals(original.progress));
      expect(restored.processedItems, equals(original.processedItems));
      expect(restored.totalItems, equals(original.totalItems));
      expect(restored.currentItem, equals(original.currentItem));
      expect(restored.message, equals(original.message));
    });

    test('should handle null message in JSON serialization', () {
      const progress = BulkOperationProgress(
        operationId: 'progress_null_test',
        progress: 0.25,
        processedItems: 2,
        totalItems: 8,
        currentItem: 'item_2',
        message: null,
      );

      final json = progress.toJson();
      final restored = BulkOperationProgress.fromJson(json);

      expect(restored.message, isNull);
    });

    test('should validate progress bounds', () {
      // Test valid progress values
      expect(() => const BulkOperationProgress(
        operationId: 'test',
        progress: 0.0,
        processedItems: 0,
        totalItems: 10,
        currentItem: 'item_0',
      ), returnsNormally);

      expect(() => const BulkOperationProgress(
        operationId: 'test',
        progress: 1.0,
        processedItems: 10,
        totalItems: 10,
        currentItem: 'item_10',
      ), returnsNormally);

      expect(() => const BulkOperationProgress(
        operationId: 'test',
        progress: 0.5,
        processedItems: 5,
        totalItems: 10,
        currentItem: 'item_5',
      ), returnsNormally);
    });
  });

  group('BulkOperationType', () {
    test('should have correct JSON values', () {
      expect(BulkOperationType.approval.toString(), contains('approval'));
      expect(BulkOperationType.rejection.toString(), contains('rejection'));
      expect(BulkOperationType.export.toString(), contains('export'));
    });

    test('should contain all expected operation types', () {
      const types = BulkOperationType.values;
      expect(types, hasLength(3));
      expect(types, contains(BulkOperationType.approval));
      expect(types, contains(BulkOperationType.rejection));
      expect(types, contains(BulkOperationType.export));
    });
  });

  group('Model Integration', () {
    test('should work together in a complete workflow', () {
      const operationId = 'integration_test_123';
      final startTime = DateTime.now();

      // Create initial progress
      const initialProgress = BulkOperationProgress(
        operationId: operationId,
        progress: 0.0,
        processedItems: 0,
        totalItems: 5,
        currentItem: 'starting',
        message: 'Starting bulk operation',
      );

      // Create mid-operation progress
      const midProgress = BulkOperationProgress(
        operationId: operationId,
        progress: 0.6,
        processedItems: 3,
        totalItems: 5,
        currentItem: 'item_3',
        message: 'Processing item 3 of 5',
      );

      // Create final result
      final result = BulkOperationResult(
        operationId: operationId,
        type: BulkOperationType.approval,
        totalItems: 5,
        successfulItems: 4,
        failedItems: 1,
        errors: ['Failed to process item_4'],
        startTime: startTime,
        endTime: startTime.add(const Duration(seconds: 30)),
        canUndo: true,
      );

      // Verify all models have consistent operation ID
      expect(initialProgress.operationId, equals(operationId));
      expect(midProgress.operationId, equals(operationId));
      expect(result.operationId, equals(operationId));

      // Verify progress consistency
      expect(initialProgress.totalItems, equals(result.totalItems));
      expect(midProgress.totalItems, equals(result.totalItems));

      // Verify final state
      expect(result.successfulItems + result.failedItems, equals(result.totalItems));
      expect(result.errors, hasLength(result.failedItems));
    });

    test('should handle serialization of complete workflow', () {
      const operationId = 'serialization_test_456';
      
      const progress = BulkOperationProgress(
        operationId: operationId,
        progress: 0.8,
        processedItems: 4,
        totalItems: 5,
        currentItem: 'item_4',
        message: 'Almost done',
      );

      final result = BulkOperationResult(
        operationId: operationId,
        type: BulkOperationType.rejection,
        totalItems: 5,
        successfulItems: 5,
        failedItems: 0,
        errors: [],
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 1)),
        canUndo: true,
      );

      // Serialize and deserialize
      final progressJson = progress.toJson();
      final resultJson = result.toJson();

      final restoredProgress = BulkOperationProgress.fromJson(progressJson);
      final restoredResult = BulkOperationResult.fromJson(resultJson);

      // Verify consistency after serialization
      expect(restoredProgress.operationId, equals(restoredResult.operationId));
      expect(restoredProgress.totalItems, equals(restoredResult.totalItems));
    });
  });
}