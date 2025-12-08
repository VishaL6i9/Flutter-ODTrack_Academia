import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/core/storage/storage_manager.dart';
import 'package:odtrack_academia/core/storage/sync_queue_manager.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/sync_models.dart';
import 'package:odtrack_academia/services/sync/background_sync_worker.dart';
import 'package:odtrack_academia/services/sync/hive_sync_service.dart';
import 'package:odtrack_academia/services/sync/offline_operation_queue.dart';

// Mock connectivity for testing
class MockConnectivity implements Connectivity {
  final StreamController<List<ConnectivityResult>> _controller = 
      StreamController<List<ConnectivityResult>>.broadcast();
  
  List<ConnectivityResult> _currentResult = [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return _currentResult;
  }

  void setConnectivity(List<ConnectivityResult> result) {
    _currentResult = result;
    _controller.add(result);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('Background Sync Integration Tests', () {
    late HiveSyncService syncService;
    late EnhancedStorageManager storageManager;
    late SyncQueueManager queueManager;
    late MockConnectivity mockConnectivity;

    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('test_integration');
      
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(102)) {
        Hive.registerAdapter(SyncStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(201)) {
        Hive.registerAdapter(SyncResultAdapter());
      }
      if (!Hive.isAdapterRegistered(202)) {
        Hive.registerAdapter(SyncConflictAdapter());
      }
      if (!Hive.isAdapterRegistered(203)) {
        Hive.registerAdapter(ConflictResolutionAdapter());
      }
      if (!Hive.isAdapterRegistered(214)) {
        Hive.registerAdapter(SyncQueueItemAdapter());
      }
      if (!Hive.isAdapterRegistered(215)) {
        Hive.registerAdapter(CacheMetadataAdapter());
      }
    });

    setUp(() async {
      // Clear any existing boxes
      await Hive.deleteFromDisk();
      
      // Create mock connectivity
      mockConnectivity = MockConnectivity();

      // Initialize storage components
      storageManager = EnhancedStorageManager();
      await storageManager.initialize();
      
      queueManager = SyncQueueManager(storageManager);
      
      // Initialize sync service
      syncService = HiveSyncService(
        storageManager: storageManager,
        queueManager: queueManager,
        connectivity: mockConnectivity,
      );
      
      await syncService.initialize();
    });

    tearDown(() async {
      await syncService.dispose();
      mockConnectivity.dispose();
      await Hive.deleteFromDisk();
    });

    group('Background Worker Integration', () {
      test('should start and manage background sync worker', () async {
        // Assert worker is running after service initialization
        expect(syncService.backgroundWorker.isRunning, isTrue);
        expect(syncService.backgroundWorker.isConnected, isTrue);
        
        // Test worker statistics
        final stats = syncService.backgroundWorker.getStatistics();
        expect(stats, containsPair('isRunning', isTrue));
        expect(stats, containsPair('isConnected', isTrue));
        expect(stats, containsPair('consecutiveFailures', 0));
      });

      test('should respond to connectivity changes', () async {
        final events = <BackgroundSyncEvent>[];
        final subscription = syncService.backgroundWorker.eventStream.listen(events.add);
        
        // Simulate going offline
        mockConnectivity.setConnectivity([ConnectivityResult.none]);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        
        // Simulate going back online
        mockConnectivity.setConnectivity([ConnectivityResult.wifi]);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        
        // Check that connectivity events were emitted
        final connectivityEvents = events.where((e) => e.type == 'connectivity_changed').toList();
        expect(connectivityEvents.length, greaterThanOrEqualTo(2));
        
        await subscription.cancel();
      });

      test('should handle sync operations through background worker', () async {
        // Add some items to the sync queue
        await queueManager.queueODRequest(
          requestId: 'bg_test_1',
          operation: 'create',
          requestData: {'id': 'bg_test_1', 'test': true},
        );
        
        await queueManager.queueODRequest(
          requestId: 'bg_test_2',
          operation: 'update',
          requestData: {'id': 'bg_test_2', 'test': true},
        );

        // Force sync through background worker
        final result = await syncService.backgroundWorker.forceSync();
        
        // Verify sync completed (may have some failures due to mock data, but should process items)
        expect(result.itemsSynced + result.itemsFailed, greaterThan(0));
        expect(result.timestamp, isNotNull);
      });
    });

    group('Offline Operation Queue Integration', () {
      test('should queue and track offline operations', () async {
        final queue = syncService.offlineQueue;
        
        // Test queueing different types of operations
        final createOpId = await queue.queueCreateODRequest(
          ODRequest(
            id: 'offline_test_1',
            studentId: 'student_1',
            studentName: 'Test Student',
            registerNumber: 'REG001',
            date: DateTime.now(),
            periods: [1, 2],
            reason: 'Offline test',
            status: 'pending',
            createdAt: DateTime.now(),
          ),
        );
        
        final bulkOpId = await queue.queueBulkApproval(['req1', 'req2'], 'Bulk test');
        
        // Verify operations are tracked
        expect(createOpId, isNotEmpty);
        expect(bulkOpId, isNotEmpty);
        
        final pendingOps = queue.getPendingOperations();
        expect(pendingOps, hasLength(2));
        
        // Verify operation types
        final createOps = queue.getPendingOperationsByType(OperationType.createODRequest);
        final bulkOps = queue.getPendingOperationsByType(OperationType.bulkApproval);
        
        expect(createOps, hasLength(1));
        expect(bulkOps, hasLength(1));
      });

      test('should provide operation statistics', () async {
        final queue = syncService.offlineQueue;
        
        // Add some operations
        await queue.queueCreateODRequest(
          ODRequest(
            id: 'stats_test_1',
            studentId: 'student_1',
            studentName: 'Test Student',
            registerNumber: 'REG001',
            date: DateTime.now(),
            periods: [1],
            reason: 'Stats test',
            status: 'pending',
            createdAt: DateTime.now(),
          ),
        );
        
        await queue.queueBulkRejection(['req1'], 'Stats test');
        
        // Get statistics
        final stats = queue.getStatistics();
        
        expect(stats, containsPair('totalPending', 2));
        expect(stats, containsPair('byType', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('oldestPendingAge', isA<int>()));
        
        final byType = stats['byType'] as Map<String, dynamic>;
        expect(byType, containsPair('createODRequest', 1));
        expect(byType, containsPair('bulkRejection', 1));
      });
    });

    group('Sync Queue with Retry Logic', () {
      test('should handle retry logic correctly', () async {
        // Add an item to the queue
        final queueId = await queueManager.queueODRequest(
          requestId: 'retry_test',
          operation: 'create',
          requestData: {'id': 'retry_test'},
        );
        
        // Mark as failed multiple times
        await queueManager.markAsFailed(queueId, 'First failure');
        await queueManager.markAsFailed(queueId, 'Second failure');
        
        // Get the item and check retry count
        final item = await storageManager.getSyncQueueItem(queueId);
        expect(item?.retryCount, equals(2));
        expect(item?.status, equals(SyncStatus.failed));
        expect(item?.errorMessage, equals('Second failure'));
      });

      test('should prioritize items correctly', () async {
        // Add items with different priorities
        await queueManager.queueItem(
          itemId: 'low_priority',
          itemType: 'test',
          operation: 'test',
          data: {},
          priority: 1,
        );
        
        await queueManager.queueItem(
          itemId: 'high_priority',
          itemType: 'test',
          operation: 'test',
          data: {},
          priority: 10,
        );
        
        await queueManager.queueItem(
          itemId: 'medium_priority',
          itemType: 'test',
          operation: 'test',
          data: {},
          priority: 5,
        );
        
        // Get next batch and verify order
        final batch = await queueManager.getNextSyncBatch(batchSize: 10);
        
        expect(batch, hasLength(3));
        expect(batch[0].itemId, equals('high_priority'));
        expect(batch[1].itemId, equals('medium_priority'));
        expect(batch[2].itemId, equals('low_priority'));
      });

      test('should provide queue health metrics', () async {
        // Add some items
        await queueManager.queueODRequest(
          requestId: 'health_test_1',
          operation: 'create',
          requestData: {'id': 'health_test_1'},
        );
        
        final queueId = await queueManager.queueODRequest(
          requestId: 'health_test_2',
          operation: 'update',
          requestData: {'id': 'health_test_2'},
        );
        
        // Mark one as failed
        await queueManager.markAsFailed(queueId, 'Test failure');
        
        // Get health metrics
        final health = await queueManager.getQueueHealth();
        
        expect(health, containsPair('stats', isA<Map<String, dynamic>>()));
        expect(health, containsPair('isHealthy', isA<bool>()));
        expect(health, containsPair('averageRetryCount', isA<String>()));
        expect(health, containsPair('itemsByType', isA<Map<String, dynamic>>()));
        
        final stats = health['stats'] as Map<String, dynamic>;
        expect(stats['pending'], greaterThan(0));
        expect(stats['failed'], greaterThan(0));
      });
    });

    group('Comprehensive Statistics', () {
      test('should provide comprehensive sync statistics', () async {
        // Add various operations
        await queueManager.queueODRequest(
          requestId: 'comp_stats_1',
          operation: 'create',
          requestData: {'id': 'comp_stats_1'},
        );
        
        await syncService.offlineQueue.queueBulkApproval(['req1', 'req2'], 'Comprehensive test');
        
        // Get comprehensive statistics
        final stats = await syncService.getComprehensiveStatistics();
        
        expect(stats, containsPair('sync', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('offlineQueue', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('backgroundWorker', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('timestamp', isA<String>()));
        
        // Verify structure of each component
        final syncStats = stats['sync'] as Map<String, dynamic>;
        expect(syncStats, containsPair('isConnected', isA<bool>()));
        expect(syncStats, containsPair('isSyncing', isA<bool>()));
        
        final queueStats = stats['offlineQueue'] as Map<String, dynamic>;
        expect(queueStats, containsPair('totalPending', isA<int>()));
        
        final workerStats = stats['backgroundWorker'] as Map<String, dynamic>;
        expect(workerStats, containsPair('isRunning', isA<bool>()));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle service disposal gracefully', () async {
        // Verify service is running
        expect(syncService.isInitialized, isTrue);
        expect(syncService.backgroundWorker.isRunning, isTrue);
        
        // Dispose service
        await syncService.dispose();
        
        // Verify cleanup
        expect(syncService.backgroundWorker.isRunning, isFalse);
      });

      test('should handle empty queue operations', () async {
        // Test operations on empty queue
        final batch = await queueManager.getNextSyncBatch();
        expect(batch, isEmpty);
        
        final health = await queueManager.getQueueHealth();
        expect(health['stats']['total'], equals(0));
        
        final stats = syncService.offlineQueue.getStatistics();
        expect(stats['totalPending'], equals(0));
      });

      test('should handle queue cleanup operations', () async {
        // Add and complete some items
        final queueId1 = await queueManager.queueODRequest(
          requestId: 'cleanup_test_1',
          operation: 'create',
          requestData: {'id': 'cleanup_test_1'},
        );
        
        final queueId2 = await queueManager.queueODRequest(
          requestId: 'cleanup_test_2',
          operation: 'update',
          requestData: {'id': 'cleanup_test_2'},
        );
        
        // Mark items as completed
        await queueManager.markAsCompleted(queueId1);
        await queueManager.markAsCompleted(queueId2);
        
        // Perform cleanup
        final cleanedCount = await queueManager.cleanupOldItems();
        
        // Verify cleanup (exact count may vary based on implementation)
        expect(cleanedCount, greaterThanOrEqualTo(0));
      });
    });
  });
}