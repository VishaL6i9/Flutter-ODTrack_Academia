import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:odtrack_academia/providers/bulk_operation_provider.dart';
import 'package:odtrack_academia/services/bulk_operations/bulk_operation_service.dart';
import 'package:odtrack_academia/models/bulk_operation_models.dart';
import 'package:odtrack_academia/models/export_models.dart';

import 'bulk_operation_provider_test.mocks.dart';

@GenerateMocks([BulkOperationService])
void main() {
  group('BulkOperationProvider Tests', () {
    late MockBulkOperationService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockBulkOperationService();
      when(mockService.initialize()).thenAnswer((_) async {});
      when(mockService.progressStream).thenAnswer((_) => const Stream.empty());
      
      container = ProviderContainer(
        overrides: [
          bulkOperationServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Selection State Management', () {
      test('initial state should be empty', () {
        final state = container.read(bulkOperationProvider);
        
        expect(state.selectedRequestIds, isEmpty);
        expect(state.isSelectionMode, false);
        expect(state.hasSelection, false);
        expect(state.selectionCount, 0);
      });

      test('toggleSelectionMode should enter selection mode', () {
        final notifier = container.read(bulkOperationProvider.notifier);
        
        notifier.toggleSelectionMode();
        
        final state = container.read(bulkOperationProvider);
        expect(state.isSelectionMode, true);
      });

      test('toggleSelectionMode should exit selection mode and clear selections', () {
        final notifier = container.read(bulkOperationProvider.notifier);
        
        // Enter selection mode and select some items
        notifier.toggleSelectionMode();
        notifier.toggleRequestSelection('request1');
        notifier.toggleRequestSelection('request2');
        
        // Exit selection mode
        notifier.toggleSelectionMode();
        
        final state = container.read(bulkOperationProvider);
        expect(state.isSelectionMode, false);
        expect(state.selectedRequestIds, isEmpty);
      });

      test('toggleRequestSelection should add request to selection', () {
        final notifier = container.read(bulkOperationProvider.notifier);
        
        notifier.toggleRequestSelection('request1');
        
        final state = container.read(bulkOperationProvider);
        expect(state.selectedRequestIds, contains('request1'));
        expect(state.selectionCount, 1);
        expect(state.hasSelection, true);
      });

      test('toggleRequestSelection should remove request from selection', () {
        final notifier = container.read(bulkOperationProvider.notifier);
        
        // Add request
        notifier.toggleRequestSelection('request1');
        expect(container.read(bulkOperationProvider).selectedRequestIds, contains('request1'));
        
        // Remove request
        notifier.toggleRequestSelection('request1');
        
        final state = container.read(bulkOperationProvider);
        expect(state.selectedRequestIds, isNot(contains('request1')));
        expect(state.selectionCount, 0);
        expect(state.hasSelection, false);
      });

      test('selectAll should select all provided request IDs', () {
        final notifier = container.read(bulkOperationProvider.notifier);
        final requestIds = ['request1', 'request2', 'request3'];
        
        notifier.selectAll(requestIds);
        
        final state = container.read(bulkOperationProvider);
        expect(state.selectedRequestIds, containsAll(requestIds));
        expect(state.selectionCount, 3);
      });

      test('clearSelection should remove all selections', () {
        final notifier = container.read(bulkOperationProvider.notifier);
        
        // Add some selections
        notifier.toggleRequestSelection('request1');
        notifier.toggleRequestSelection('request2');
        
        // Clear selections
        notifier.clearSelection();
        
        final state = container.read(bulkOperationProvider);
        expect(state.selectedRequestIds, isEmpty);
        expect(state.selectionCount, 0);
        expect(state.hasSelection, false);
      });

      test('isRequestSelected should return correct selection status', () {
        final notifier = container.read(bulkOperationProvider.notifier);
        
        expect(notifier.isRequestSelected('request1'), false);
        
        notifier.toggleRequestSelection('request1');
        expect(notifier.isRequestSelected('request1'), true);
        
        notifier.toggleRequestSelection('request1');
        expect(notifier.isRequestSelected('request1'), false);
      });
    });

    group('Bulk Operations', () {
      test('performBulkApproval should call service and update state', () async {
        final notifier = container.read(bulkOperationProvider.notifier);
        final mockResult = BulkOperationResult(
          operationId: 'op1',
          type: BulkOperationType.approval,
          totalItems: 2,
          successfulItems: 2,
          failedItems: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          canUndo: true,
        );
        
        when(mockService.performBulkApproval(['request1', 'request2'], 'Test reason'))
            .thenAnswer((_) async => mockResult);
        
        // Select some requests
        notifier.toggleRequestSelection('request1');
        notifier.toggleRequestSelection('request2');
        notifier.toggleSelectionMode();
        
        await notifier.performBulkApproval('Test reason');
        
        verify(mockService.performBulkApproval(['request1', 'request2'], 'Test reason')).called(1);
        
        final state = container.read(bulkOperationProvider);
        expect(state.lastResult, equals(mockResult));
        expect(state.selectedRequestIds, isEmpty);
        expect(state.isSelectionMode, false);
      });

      test('performBulkRejection should call service and update state', () async {
        final notifier = container.read(bulkOperationProvider.notifier);
        final mockResult = BulkOperationResult(
          operationId: 'op2',
          type: BulkOperationType.rejection,
          totalItems: 1,
          successfulItems: 1,
          failedItems: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          canUndo: true,
        );
        
        when(mockService.performBulkRejection(['request1'], 'Test rejection'))
            .thenAnswer((_) async => mockResult);
        
        // Select a request
        notifier.toggleRequestSelection('request1');
        notifier.toggleSelectionMode();
        
        await notifier.performBulkRejection('Test rejection');
        
        verify(mockService.performBulkRejection(['request1'], 'Test rejection')).called(1);
        
        final state = container.read(bulkOperationProvider);
        expect(state.lastResult, equals(mockResult));
        expect(state.selectedRequestIds, isEmpty);
        expect(state.isSelectionMode, false);
      });

      test('performBulkExport should call service and update state', () async {
        final notifier = container.read(bulkOperationProvider.notifier);
        final mockResult = BulkOperationResult(
          operationId: 'op3',
          type: BulkOperationType.export,
          totalItems: 3,
          successfulItems: 3,
          failedItems: 0,
          errors: [],
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          canUndo: false,
        );
        
        when(mockService.performBulkExport(['request1', 'request2', 'request3'], ExportFormat.pdf))
            .thenAnswer((_) async => mockResult);
        
        // Select requests
        notifier.selectAll(['request1', 'request2', 'request3']);
        notifier.toggleSelectionMode();
        
        await notifier.performBulkExport(ExportFormat.pdf);
        
        verify(mockService.performBulkExport(['request1', 'request2', 'request3'], ExportFormat.pdf)).called(1);
        
        final state = container.read(bulkOperationProvider);
        expect(state.lastResult, equals(mockResult));
        expect(state.selectedRequestIds, isEmpty);
        expect(state.isSelectionMode, false);
      });

      test('should not perform bulk operations with empty selection', () async {
        final notifier = container.read(bulkOperationProvider.notifier);
        
        await notifier.performBulkApproval('Test reason');
        await notifier.performBulkRejection('Test reason');
        await notifier.performBulkExport(ExportFormat.pdf);
        
        verifyNever(mockService.performBulkApproval(any, any));
        verifyNever(mockService.performBulkRejection(any, any));
        verifyNever(mockService.performBulkExport(any, any));
      });

      test('should handle bulk operation errors', () async {
        final notifier = container.read(bulkOperationProvider.notifier);
        
        when(mockService.performBulkApproval(any, any))
            .thenThrow(Exception('Network error'));
        
        notifier.toggleRequestSelection('request1');
        
        await notifier.performBulkApproval('Test reason');
        
        final state = container.read(bulkOperationProvider);
        expect(state.error, contains('Network error'));
      });
    });

    group('Progress Tracking', () {
      test('should update progress from stream', () async {
        final progressController = StreamController<BulkOperationProgress>();
        when(mockService.progressStream).thenAnswer((_) => progressController.stream);
        
        // Create a new container to get the stream subscription
        final newContainer = ProviderContainer(
          overrides: [
            bulkOperationServiceProvider.overrideWithValue(mockService),
          ],
        );
        
        // Access the provider to initialize it
        newContainer.read(bulkOperationProvider);
        
        const progress = BulkOperationProgress(
          operationId: 'op1',
          progress: 0.5,
          processedItems: 5,
          totalItems: 10,
          currentItem: 'request5',
          message: 'Processing...',
        );
        
        progressController.add(progress);
        
        // Wait for the stream to be processed
        await Future<void>.delayed(const Duration(milliseconds: 10));
        
        final state = newContainer.read(bulkOperationProvider);
        expect(state.currentProgress, equals(progress));
        
        progressController.close();
        newContainer.dispose();
      });

      test('cancelCurrentOperation should call service when progress exists', () async {
        final notifier = container.read(bulkOperationProvider.notifier);
        
        when(mockService.cancelBulkOperation(any)).thenAnswer((_) async {});
        
        // Call cancel when no progress exists - should not call service
        await notifier.cancelCurrentOperation();
        verifyNever(mockService.cancelBulkOperation(any));
      });
    });

    group('Undo Operations', () {
      test('undoLastOperation should call service and return success', () async {
        final notifier = container.read(bulkOperationProvider.notifier);
        
        when(mockService.undoLastBulkOperation()).thenAnswer((_) async => true);
        
        final success = await notifier.undoLastOperation();
        
        expect(success, true);
        verify(mockService.undoLastBulkOperation()).called(1);
      });

      test('undoLastOperation should handle errors', () async {
        final notifier = container.read(bulkOperationProvider.notifier);
        
        when(mockService.undoLastBulkOperation()).thenThrow(Exception('Undo failed'));
        
        final success = await notifier.undoLastOperation();
        
        expect(success, false);
        
        final state = container.read(bulkOperationProvider);
        expect(state.error, contains('Undo failed'));
      });
    });

    group('Error Handling', () {
      test('clearError should remove error from state', () async {
        final notifier = container.read(bulkOperationProvider.notifier);
        
        // Cause an error by making a service call fail
        when(mockService.performBulkApproval(any, any))
            .thenThrow(Exception('Test error'));
        
        notifier.toggleRequestSelection('request1');
        await notifier.performBulkApproval('Test reason');
        
        // Verify error exists
        final stateWithError = container.read(bulkOperationProvider);
        expect(stateWithError.error, isNotNull);
        
        notifier.clearError();
        
        final state = container.read(bulkOperationProvider);
        expect(state.error, isNull);
      });
    });
  });
}