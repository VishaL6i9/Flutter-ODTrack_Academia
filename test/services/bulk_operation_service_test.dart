import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/bulk_operation_models.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/services/bulk_operations/hive_bulk_operation_service.dart';

void main() {
  group('HiveBulkOperationService Tests', () {
    late HiveBulkOperationService service;

    setUpAll(() async {
      // Initialize Hive with a temporary directory for testing
      final tempDir = Directory.systemTemp.createTempSync('hive_test_');
      Hive.init(tempDir.path);
      
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ODRequestAdapter());
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(BulkOperationResultAdapter());
      }
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(BulkOperationTypeAdapter());
      }
    });

    setUp(() async {
      // Clear any existing boxes
      await Hive.deleteBoxFromDisk('od_requests');
      await Hive.deleteBoxFromDisk('bulk_operation_history');
      await Hive.deleteBoxFromDisk('bulk_operation_undo_data');
      
      service = HiveBulkOperationService();
      await service.initialize();
    });

    tearDown(() async {
      // Close all boxes and clean up
      await Hive.deleteFromDisk();
    });

    tearDownAll(() async {
      await Hive.close();
    });

    test('service initialization works correctly', () async {
      expect(service.maxBatchSize, equals(100));
    });

    test('bulk approval with valid requests works', () async {
      // Create test requests
      final testRequests = _createTestRequests(3);
      final odBox = await Hive.openBox<ODRequest>('od_requests');
      
      for (final request in testRequests) {
        await odBox.put(request.id, request);
      }

      // Perform bulk approval
      final result = await service.performBulkApproval(
        testRequests.map((r) => r.id).toList(),
        'Test approval reason',
      );

      // Verify results
      expect(result.type, equals(BulkOperationType.approval));
      expect(result.totalItems, equals(3));
      expect(result.successfulItems, equals(3));
      expect(result.failedItems, equals(0));
      expect(result.canUndo, isTrue);

      // Verify requests were updated
      for (final request in testRequests) {
        final updatedRequest = odBox.get(request.id);
        expect(updatedRequest?.status, equals('approved'));
      }
    });

    test('bulk rejection with valid requests works', () async {
      // Create test requests
      final testRequests = _createTestRequests(2);
      final odBox = await Hive.openBox<ODRequest>('od_requests');
      
      for (final request in testRequests) {
        await odBox.put(request.id, request);
      }

      // Perform bulk rejection
      final result = await service.performBulkRejection(
        testRequests.map((r) => r.id).toList(),
        'Test rejection reason',
      );

      // Verify results
      expect(result.type, equals(BulkOperationType.rejection));
      expect(result.totalItems, equals(2));
      expect(result.successfulItems, equals(2));
      expect(result.failedItems, equals(0));
      expect(result.canUndo, isTrue);

      // Verify requests were updated
      for (final request in testRequests) {
        final updatedRequest = odBox.get(request.id);
        expect(updatedRequest?.status, equals('rejected'));
        expect(updatedRequest?.rejectionReason, equals('Test rejection reason'));
      }
    });

    test('bulk export works correctly', () async {
      // Create test requests
      final testRequests = _createTestRequests(2);
      final odBox = await Hive.openBox<ODRequest>('od_requests');
      
      for (final request in testRequests) {
        await odBox.put(request.id, request);
      }

      // Perform bulk export
      final result = await service.performBulkExport(
        testRequests.map((r) => r.id).toList(),
        ExportFormat.pdf,
      );

      // Verify results
      expect(result.type, equals(BulkOperationType.export));
      expect(result.totalItems, equals(2));
      expect(result.successfulItems, equals(2));
      expect(result.failedItems, equals(0));
      expect(result.canUndo, isFalse); // Export operations cannot be undone
    });

    test('error handling for invalid requests', () async {
      // Try to process non-existent requests
      final result = await service.performBulkApproval(
        ['non_existent_1', 'non_existent_2'],
        'Test reason',
      );

      // Should complete but with failures
      expect(result.totalItems, equals(2));
      expect(result.successfulItems, equals(0));
      expect(result.failedItems, equals(2));
      expect(result.errors.length, equals(2));
    });

    test('error handling for empty request list', () async {
      expect(
        () => service.performBulkApproval([], 'Test reason'),
        throwsA(isA<Exception>()),
      );
    });

    test('error handling for empty reason', () async {
      expect(
        () => service.performBulkApproval(['test_id'], ''),
        throwsA(isA<Exception>()),
      );
    });

    test('error handling for too many requests', () async {
      final tooManyIds = List.generate(200, (i) => 'id_$i');
      expect(
        () => service.performBulkApproval(tooManyIds, 'Test reason'),
        throwsA(isA<Exception>()),
      );
    });

    test('operation history is maintained', () async {
      // Create and process test requests
      final testRequests = _createTestRequests(2);
      final odBox = await Hive.openBox<ODRequest>('od_requests');
      
      for (final request in testRequests) {
        await odBox.put(request.id, request);
      }

      // Perform multiple operations
      await service.performBulkApproval([testRequests[0].id], 'First approval');
      await service.performBulkRejection([testRequests[1].id], 'First rejection');

      // Check history
      final history = await service.getBulkOperationHistory();
      expect(history.length, equals(2));
      
      // History should be sorted by most recent first
      expect(history[0].type, equals(BulkOperationType.rejection));
      expect(history[1].type, equals(BulkOperationType.approval));
    });

    test('undo functionality works correctly', () async {
      // Create test requests
      final testRequests = _createTestRequests(2);
      final odBox = await Hive.openBox<ODRequest>('od_requests');
      
      for (final request in testRequests) {
        await odBox.put(request.id, request);
      }

      // Perform bulk approval
      final result = await service.performBulkApproval(
        testRequests.map((r) => r.id).toList(),
        'Test approval',
      );

      // Verify requests are approved
      for (final request in testRequests) {
        final updatedRequest = odBox.get(request.id);
        expect(updatedRequest?.status, equals('approved'));
      }

      // Check if operation can be undone
      expect(await service.canUndoBulkOperation(result.operationId), isTrue);

      // Undo the operation
      final undoSuccess = await service.undoLastBulkOperation();
      expect(undoSuccess, isTrue);

      // Verify requests are back to pending
      for (final request in testRequests) {
        final restoredRequest = odBox.get(request.id);
        expect(restoredRequest?.status, equals('pending'));
      }

      // Operation should no longer be undoable
      expect(await service.canUndoBulkOperation(result.operationId), isFalse);
    });

    test('progress stream emits updates during operation', () async {
      // Create test requests
      final testRequests = _createTestRequests(3);
      final odBox = await Hive.openBox<ODRequest>('od_requests');
      
      for (final request in testRequests) {
        await odBox.put(request.id, request);
      }

      // Listen to progress stream
      final progressUpdates = <BulkOperationProgress>[];
      final subscription = service.progressStream.listen((progress) {
        progressUpdates.add(progress);
      });

      // Perform bulk operation
      await service.performBulkApproval(
        testRequests.map((r) => r.id).toList(),
        'Test approval',
      );

      // Wait a bit for stream updates
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify progress updates were emitted
      expect(progressUpdates.isNotEmpty, isTrue);
      
      // Should have progress updates for each item plus completion
      expect(progressUpdates.length, greaterThanOrEqualTo(3));
      
      // Final progress should be 100%
      final finalProgress = progressUpdates.last;
      expect(finalProgress.progress, equals(1.0));
      expect(finalProgress.processedItems, equals(3));
      expect(finalProgress.totalItems, equals(3));

      await subscription.cancel();
    });

    test('operation cancellation works', () async {
      // Create test requests
      final testRequests = _createTestRequests(5);
      final odBox = await Hive.openBox<ODRequest>('od_requests');
      
      for (final request in testRequests) {
        await odBox.put(request.id, request);
      }

      // Start bulk operation
      final operationFuture = service.performBulkApproval(
        testRequests.map((r) => r.id).toList(),
        'Test approval',
      );

      // Cancel operation quickly
      await Future<void>.delayed(const Duration(milliseconds: 10));
      
      // Get operation ID from progress stream
      String? operationId;
      final subscription = service.progressStream.listen((progress) {
        operationId = progress.operationId;
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));
      
      if (operationId != null) {
        await service.cancelBulkOperation(operationId!);
      }

      // Wait for operation to complete
      final result = await operationFuture;

      // Operation should have been cancelled (some items may still be processed)
      expect(result.totalItems, equals(5));
      expect(result.successfulItems, lessThan(5)); // Not all should be processed

      await subscription.cancel();
    });
  });
}

/// Helper function to create test OD requests
List<ODRequest> _createTestRequests(int count) {
  return List.generate(count, (index) => ODRequest(
    id: 'test_request_$index',
    studentId: 'student_$index',
    studentName: 'Test Student $index',
    registerNumber: 'REG${index.toString().padLeft(3, '0')}',
    date: DateTime.now().add(Duration(days: index + 1)),
    periods: [1, 2],
    reason: 'Test reason $index',
    status: 'pending',
    createdAt: DateTime.now().subtract(Duration(hours: index)),
    staffId: 'staff_1',
  ));
}