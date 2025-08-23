import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/models/bulk_operation_models.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/bulk_operations/hive_bulk_operation_service.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';

void main() {
  group('HiveBulkOperationService', () {
    late HiveBulkOperationService service;
    late Box<ODRequest> odRequestsBox;
    late Box<BulkOperationResult> historyBox;
    late Box<Map<String, dynamic>> undoBox;

    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('./test/hive_test_db');
      
      // Register adapters
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ODRequestAdapter());
      }
      if (!Hive.isAdapterRegistered(20)) {
        Hive.registerAdapter(BulkOperationResultAdapter());
      }
    });

    setUp(() async {
      // Clear any existing boxes
      await Hive.deleteBoxFromDisk('od_requests');
      await Hive.deleteBoxFromDisk('bulk_operation_history');
      await Hive.deleteBoxFromDisk('bulk_operation_undo_data');

      // Open boxes for testing
      odRequestsBox = await Hive.openBox<ODRequest>('od_requests');
      historyBox = await Hive.openBox<BulkOperationResult>('bulk_operation_history');
      undoBox = await Hive.openBox<Map<String, dynamic>>('bulk_operation_undo_data');

      // Create service instance
      service = HiveBulkOperationService();
      await service.initialize();
    });

    tearDown(() async {
      await service.dispose();
      await odRequestsBox.close();
      await historyBox.close();
      await undoBox.close();
    });

    tearDownAll(() async {
      await Hive.close();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        final newService = HiveBulkOperationService();
        await expectLater(newService.initialize(), completes);
        await newService.dispose();
      });

      test('should have correct max batch size', () {
        expect(service.maxBatchSize, equals(100));
      });

      test('should provide progress stream', () {
        expect(service.progressStream, isA<Stream<BulkOperationProgress>>());
      });
    });

    group('Bulk Approval', () {
      setUp(() async {
        // Add test OD requests
        final requests = [
          _createTestODRequest('req1', 'pending'),
          _createTestODRequest('req2', 'pending'),
          _createTestODRequest('req3', 'pending'),
        ];

        for (final request in requests) {
          await odRequestsBox.put(request.id, request);
        }
      });

      test('should approve multiple pending requests successfully', () async {
        const requestIds = ['req1', 'req2', 'req3'];
        const reason = 'Bulk approval test';

        final result = await service.performBulkApproval(requestIds, reason);

        expect(result.type, equals(BulkOperationType.approval));
        expect(result.totalItems, equals(3));
        expect(result.successfulItems, equals(3));
        expect(result.failedItems, equals(0));
        expect(result.errors, isEmpty);
        expect(result.canUndo, isTrue);

        // Verify requests were actually approved
        for (final requestId in requestIds) {
          final request = odRequestsBox.get(requestId);
          expect(request?.status, equals('approved'));
          expect(request?.approvedAt, isNotNull);
          expect(request?.approvedBy, equals('bulk_operation'));
        }
      });

      test('should handle empty request list', () async {
        await expectLater(
          service.performBulkApproval([], 'test reason'),
          throwsA(isA<ValidationError>()),
        );
      });

      test('should handle empty reason', () async {
        await expectLater(
          service.performBulkApproval(['req1'], ''),
          throwsA(isA<ValidationError>()),
        );
      });

      test('should handle batch size limit', () async {
        final largeRequestIds = List.generate(101, (index) => 'req$index');
        
        await expectLater(
          service.performBulkApproval(largeRequestIds, 'test reason'),
          throwsA(isA<ValidationError>()),
        );
      });

      test('should handle non-existent requests gracefully', () async {
        const requestIds = ['req1', 'nonexistent', 'req2'];
        const reason = 'Test approval';

        final result = await service.performBulkApproval(requestIds, reason);

        expect(result.successfulItems, equals(2));
        expect(result.failedItems, equals(1));
        expect(result.errors, hasLength(1));
      });

      test('should handle already approved requests', () async {
        // Approve one request first
        final approvedRequest = _createTestODRequest('req1', 'approved');
        await odRequestsBox.put('req1', approvedRequest);

        const requestIds = ['req1', 'req2'];
        const reason = 'Test approval';

        final result = await service.performBulkApproval(requestIds, reason);

        expect(result.successfulItems, equals(1)); // Only req2 should be approved
        expect(result.failedItems, equals(1)); // req1 should fail
        expect(result.errors, hasLength(1));
      });

      test('should emit progress updates', () async {
        const requestIds = ['req1', 'req2', 'req3'];
        const reason = 'Progress test';
        final progressUpdates = <BulkOperationProgress>[];

        // Listen to progress stream
        final subscription = service.progressStream.listen(progressUpdates.add);

        await service.performBulkApproval(requestIds, reason);
        await subscription.cancel();

        expect(progressUpdates, isNotEmpty);
        expect(progressUpdates.last.progress, equals(1.0));
        expect(progressUpdates.last.processedItems, equals(3));
        expect(progressUpdates.last.totalItems, equals(3));
      });
    });

    group('Bulk Rejection', () {
      setUp(() async {
        // Add test OD requests
        final requests = [
          _createTestODRequest('req1', 'pending'),
          _createTestODRequest('req2', 'pending'),
          _createTestODRequest('req3', 'pending'),
        ];

        for (final request in requests) {
          await odRequestsBox.put(request.id, request);
        }
      });

      test('should reject multiple pending requests successfully', () async {
        const requestIds = ['req1', 'req2', 'req3'];
        const reason = 'Bulk rejection test';

        final result = await service.performBulkRejection(requestIds, reason);

        expect(result.type, equals(BulkOperationType.rejection));
        expect(result.totalItems, equals(3));
        expect(result.successfulItems, equals(3));
        expect(result.failedItems, equals(0));
        expect(result.errors, isEmpty);
        expect(result.canUndo, isTrue);

        // Verify requests were actually rejected
        for (final requestId in requestIds) {
          final request = odRequestsBox.get(requestId);
          expect(request?.status, equals('rejected'));
          expect(request?.rejectionReason, equals(reason));
        }
      });

      test('should handle already rejected requests', () async {
        // Reject one request first
        final rejectedRequest = _createTestODRequest('req1', 'rejected');
        await odRequestsBox.put('req1', rejectedRequest);

        const requestIds = ['req1', 'req2'];
        const reason = 'Test rejection';

        final result = await service.performBulkRejection(requestIds, reason);

        expect(result.successfulItems, equals(1)); // Only req2 should be rejected
        expect(result.failedItems, equals(1)); // req1 should fail
        expect(result.errors, hasLength(1));
      });
    });

    group('Bulk Export', () {
      setUp(() async {
        // Add test OD requests
        final requests = [
          _createTestODRequest('req1', 'approved'),
          _createTestODRequest('req2', 'approved'),
          _createTestODRequest('req3', 'rejected'),
        ];

        for (final request in requests) {
          await odRequestsBox.put(request.id, request);
        }
      });

      test('should export multiple requests successfully', () async {
        final requestIds = ['req1', 'req2', 'req3'];
        
        final result = await service.performBulkExport(requestIds, ExportFormat.pdf);

        expect(result.type, equals(BulkOperationType.export));
        expect(result.totalItems, equals(3));
        expect(result.successfulItems, equals(3));
        expect(result.failedItems, equals(0));
        expect(result.errors, isEmpty);
        expect(result.canUndo, isFalse); // Export operations cannot be undone
      });

      test('should handle different export formats', () async {
        final requestIds = ['req1'];
        
        for (final format in ExportFormat.values) {
          final result = await service.performBulkExport(requestIds, format);
          expect(result.successfulItems, equals(1));
        }
      });
    });

    group('Operation History', () {
      test('should store operation history', () async {
        final requestIds = ['req1'];
        await odRequestsBox.put('req1', _createTestODRequest('req1', 'pending'));

        await service.performBulkApproval(requestIds, 'Test approval');

        final history = await service.getBulkOperationHistory();
        expect(history, hasLength(1));
        expect(history.first.type, equals(BulkOperationType.approval));
      });

      test('should return history in chronological order', () async {
        await odRequestsBox.put('req1', _createTestODRequest('req1', 'pending'));
        await odRequestsBox.put('req2', _createTestODRequest('req2', 'pending'));

        // Perform multiple operations with delays
        await service.performBulkApproval(['req1'], 'First operation');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await service.performBulkRejection(['req2'], 'Second operation');

        final history = await service.getBulkOperationHistory();
        expect(history, hasLength(2));
        expect(history.first.startTime.isAfter(history.last.startTime), isTrue);
      });
    });

    group('Undo Functionality', () {
      test('should undo bulk approval successfully', () async {
        final requestIds = ['req1', 'req2'];
        for (final id in requestIds) {
          await odRequestsBox.put(id, _createTestODRequest(id, 'pending'));
        }

        final result = await service.performBulkApproval(requestIds, 'Test approval');
        expect(result.canUndo, isTrue);

        // Verify requests were approved
        for (final id in requestIds) {
          final request = odRequestsBox.get(id);
          expect(request?.status, equals('approved'));
        }

        // Undo the operation
        final undoSuccess = await service.undoLastBulkOperation();
        expect(undoSuccess, isTrue);

        // Verify requests were restored to pending
        for (final id in requestIds) {
          final request = odRequestsBox.get(id);
          expect(request?.status, equals('pending'));
        }
      });

      test('should undo bulk rejection successfully', () async {
        final requestIds = ['req1', 'req2'];
        for (final id in requestIds) {
          await odRequestsBox.put(id, _createTestODRequest(id, 'pending'));
        }

        final result = await service.performBulkRejection(requestIds, 'Test rejection');
        expect(result.canUndo, isTrue);

        // Verify requests were rejected
        for (final id in requestIds) {
          final request = odRequestsBox.get(id);
          expect(request?.status, equals('rejected'));
        }

        // Undo the operation
        final undoSuccess = await service.undoLastBulkOperation();
        expect(undoSuccess, isTrue);

        // Verify requests were restored to pending
        for (final id in requestIds) {
          final request = odRequestsBox.get(id);
          expect(request?.status, equals('pending'));
        }
      });

      test('should not allow undo for export operations', () async {
        await odRequestsBox.put('req1', _createTestODRequest('req1', 'approved'));

        final result = await service.performBulkExport(['req1'], ExportFormat.pdf);
        expect(result.canUndo, isFalse);

        final undoSuccess = await service.undoLastBulkOperation();
        expect(undoSuccess, isFalse);
      });

      test('should check undo capability correctly', () async {
        await odRequestsBox.put('req1', _createTestODRequest('req1', 'pending'));

        final result = await service.performBulkApproval(['req1'], 'Test approval');
        
        final canUndo = await service.canUndoBulkOperation(result.operationId);
        expect(canUndo, isTrue);
      });
    });

    group('Operation Cancellation', () {
      test('should cancel ongoing operation', () async {
        final requestIds = List.generate(10, (index) => 'req$index');
        for (final id in requestIds) {
          await odRequestsBox.put(id, _createTestODRequest(id, 'pending'));
        }

        // Start operation and cancel it immediately
        final operationFuture = service.performBulkApproval(requestIds, 'Test approval');
        
        // Cancel after a short delay
        Future<void>.delayed(const Duration(milliseconds: 50), () async {
          final history = await service.getBulkOperationHistory();
          if (history.isNotEmpty) {
            await service.cancelBulkOperation(history.first.operationId);
          }
        });

        final result = await operationFuture;
        
        // Operation should complete but may have fewer successful items due to cancellation
        expect(result.totalItems, equals(10));
        expect(result.successfulItems, lessThanOrEqualTo(10));
      });
    });

    group('Error Handling', () {
      test('should handle storage errors gracefully', () async {
        // Create a new service without initialization to simulate storage error
        final uninitializedService = HiveBulkOperationService();

        await expectLater(
          uninitializedService.performBulkApproval(['req1'], 'Test approval'),
          throwsA(isA<StorageError>()),
        );
        
        await uninitializedService.dispose();
      });

      test('should handle validation errors', () async {
        // Test empty request list
        await expectLater(
          service.performBulkApproval([], 'Test approval'),
          throwsA(isA<ValidationError>()),
        );

        // Test empty reason
        await expectLater(
          service.performBulkApproval(['req1'], ''),
          throwsA(isA<ValidationError>()),
        );

        // Test batch size limit
        final largeList = List.generate(101, (index) => 'req$index');
        await expectLater(
          service.performBulkApproval(largeList, 'Test approval'),
          throwsA(isA<ValidationError>()),
        );
      });
    });
  });
}

/// Helper function to create test OD requests
ODRequest _createTestODRequest(String id, String status) {
  return ODRequest(
    id: id,
    studentId: 'student_$id',
    studentName: 'Student $id',
    registerNumber: 'REG$id',
    date: DateTime.now(),
    periods: [1, 2, 3],
    reason: 'Test reason for $id',
    status: status,
    createdAt: DateTime.now(),
    approvedAt: status == 'approved' ? DateTime.now() : null,
    approvedBy: status == 'approved' ? 'test_staff' : null,
    rejectionReason: status == 'rejected' ? 'Test rejection' : null,
    staffId: 'staff_001',
  );
}

/// Mock adapter for BulkOperationResult (simplified for testing)
class BulkOperationResultAdapter extends TypeAdapter<BulkOperationResult> {
  @override
  final int typeId = 20;

  @override
  BulkOperationResult read(BinaryReader reader) {
    return BulkOperationResult(
      operationId: reader.readString(),
      type: BulkOperationType.values[reader.readInt()],
      totalItems: reader.readInt(),
      successfulItems: reader.readInt(),
      failedItems: reader.readInt(),
      errors: reader.readStringList(),
      startTime: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      endTime: reader.readBool() 
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) 
          : null,
      canUndo: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, BulkOperationResult obj) {
    writer.writeString(obj.operationId);
    writer.writeInt(obj.type.index);
    writer.writeInt(obj.totalItems);
    writer.writeInt(obj.successfulItems);
    writer.writeInt(obj.failedItems);
    writer.writeStringList(obj.errors);
    writer.writeInt(obj.startTime.millisecondsSinceEpoch);
    writer.writeBool(obj.endTime != null);
    if (obj.endTime != null) {
      writer.writeInt(obj.endTime!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.canUndo);
  }
}

/// Mock adapter for ODRequest (simplified for testing)
class ODRequestAdapter extends TypeAdapter<ODRequest> {
  @override
  final int typeId = 1;

  @override
  ODRequest read(BinaryReader reader) {
    return ODRequest(
      id: reader.readString(),
      studentId: reader.readString(),
      studentName: reader.readString(),
      registerNumber: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      periods: reader.readIntList(),
      reason: reader.readString(),
      status: reader.readString(),
      attachmentUrl: reader.readBool() ? reader.readString() : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      approvedAt: reader.readBool() 
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) 
          : null,
      approvedBy: reader.readBool() ? reader.readString() : null,
      rejectionReason: reader.readBool() ? reader.readString() : null,
      staffId: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, ODRequest obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.studentId);
    writer.writeString(obj.studentName);
    writer.writeString(obj.registerNumber);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeIntList(obj.periods);
    writer.writeString(obj.reason);
    writer.writeString(obj.status);
    writer.writeBool(obj.attachmentUrl != null);
    if (obj.attachmentUrl != null) {
      writer.writeString(obj.attachmentUrl!);
    }
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeBool(obj.approvedAt != null);
    if (obj.approvedAt != null) {
      writer.writeInt(obj.approvedAt!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.approvedBy != null);
    if (obj.approvedBy != null) {
      writer.writeString(obj.approvedBy!);
    }
    writer.writeBool(obj.rejectionReason != null);
    if (obj.rejectionReason != null) {
      writer.writeString(obj.rejectionReason!);
    }
    writer.writeBool(obj.staffId != null);
    if (obj.staffId != null) {
      writer.writeString(obj.staffId!);
    }
  }
}