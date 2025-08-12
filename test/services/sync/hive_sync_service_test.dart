import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';
import 'package:odtrack_academia/core/storage/enhanced_storage_manager.dart';
import 'package:odtrack_academia/core/storage/sync_queue_manager.dart';
import 'package:odtrack_academia/models/sync_models.dart';
import 'package:odtrack_academia/models/syncable_od_request.dart';
import 'package:odtrack_academia/models/syncable_user.dart';
import 'package:odtrack_academia/services/sync/hive_sync_service.dart';

import 'hive_sync_service_test.mocks.dart';

@GenerateMocks([
  EnhancedStorageManager,
  SyncQueueManager,
  Connectivity,
])
void main() {
  group('HiveSyncService', () {
    late HiveSyncService syncService;
    late MockEnhancedStorageManager mockStorageManager;
    late MockSyncQueueManager mockQueueManager;
    late MockConnectivity mockConnectivity;
    late StreamController<List<ConnectivityResult>> connectivityController;

    setUp(() {
      mockStorageManager = MockEnhancedStorageManager();
      mockQueueManager = MockSyncQueueManager();
      mockConnectivity = MockConnectivity();
      connectivityController = StreamController<List<ConnectivityResult>>.broadcast();

      // Setup connectivity mocks
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => connectivityController.stream);

      // Setup storage manager mocks
      when(mockStorageManager.initialize()).thenAnswer((_) async {});
      when(mockStorageManager.getStorageStats()).thenAnswer((_) async => {
        'totalBoxes': 4,
        'syncQueue': {'total': 0, 'pending': 0, 'failed': 0},
        'cache': {'totalItems': 0},
        'conflicts': 0,
      });

      // Setup queue manager mocks
      when(mockQueueManager.getQueueHealth()).thenAnswer((_) async => {
        'isHealthy': true,
        'stats': {'total': 0, 'pending': 0, 'failed': 0},
      });
      when(mockQueueManager.getNextSyncBatch(batchSize: anyNamed('batchSize')))
          .thenAnswer((_) async => []);
      when(mockQueueManager.cleanupOldItems()).thenAnswer((_) async => 0);

      syncService = HiveSyncService(
        storageManager: mockStorageManager,
        queueManager: mockQueueManager,
        connectivity: mockConnectivity,
      );
    });

    tearDown(() {
      connectivityController.close();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await syncService.initialize();

        expect(syncService.isInitialized, isTrue);
        expect(syncService.serviceName, equals('HiveSyncService'));
        verify(mockStorageManager.initialize()).called(1);
        verify(mockConnectivity.checkConnectivity()).called(1);
      });

      test('should handle initialization failure', () async {
        when(mockStorageManager.initialize())
            .thenThrow(Exception('Storage initialization failed'));

        expect(() => syncService.initialize(), throwsException);
        expect(syncService.isInitialized, isFalse);
      });

      test('should monitor connectivity changes', () async {
        await syncService.initialize();

        // Simulate connectivity loss and restoration
        connectivityController.add([ConnectivityResult.none]);
        connectivityController.add([ConnectivityResult.wifi]);

        // Allow time for async operations
        await Future<void>.delayed(const Duration(milliseconds: 100));

        verify(mockConnectivity.onConnectivityChanged).called(1);
      });
    });

    group('Health Check', () {
      test('should return healthy when all components are working', () async {
        await syncService.initialize();

        final isHealthy = await syncService.isHealthy();

        expect(isHealthy, isTrue);
        verify(mockStorageManager.getStorageStats()).called(1);
        verify(mockQueueManager.getQueueHealth()).called(1);
      });

      test('should return unhealthy when storage is not accessible', () async {
        await syncService.initialize();
        when(mockStorageManager.getStorageStats())
            .thenThrow(Exception('Storage error'));

        final isHealthy = await syncService.isHealthy();

        expect(isHealthy, isFalse);
      });

      test('should return unhealthy when queue is overwhelmed', () async {
        await syncService.initialize();
        when(mockQueueManager.getQueueHealth()).thenAnswer((_) async => {
          'isHealthy': false,
          'stats': {'total': 1000, 'pending': 500, 'failed': 100},
        });

        final isHealthy = await syncService.isHealthy();

        expect(isHealthy, isFalse);
      });
    });

    group('Sync Operations', () {
      setUp(() async {
        await syncService.initialize();
      });

      test('should sync all data successfully', () async {
        // Setup successful sync scenario
        when(mockQueueManager.getNextSyncBatch(batchSize: anyNamed('batchSize')))
            .thenAnswer((_) async => []);

        final result = await syncService.syncAll();

        expect(result.success, isTrue);
        expect(result.itemsSynced, equals(0));
        expect(result.itemsFailed, equals(0));
        expect(result.errors, isEmpty);
        expect(syncService.lastSyncTime, isNotNull);
      });

      test('should fail sync when not connected', () async {
        // Simulate no connectivity
        connectivityController.add([ConnectivityResult.none]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(
          () => syncService.syncAll(),
          throwsA(isA<NetworkError>()),
        );
      });

      test('should prevent concurrent sync operations', () async {
        // Start first sync
        final firstSync = syncService.syncAll();

        // Try to start second sync
        expect(
          () => syncService.syncAll(),
          throwsA(isA<SyncError>()),
        );

        await firstSync;
      });

      test('should sync OD requests with proper error handling', () async {
        final mockQueueItem = SyncQueueItem(
          id: 'queue_1',
          itemId: 'od_1',
          itemType: 'od_request',
          operation: 'create',
          data: {'test': 'data'},
          queuedAt: DateTime.now(),
        );

        when(mockQueueManager.getNextSyncBatch(batchSize: anyNamed('batchSize')))
            .thenAnswer((_) async => [mockQueueItem]);
        when(mockQueueManager.markAsInProgress(any)).thenAnswer((_) async {});
        when(mockQueueManager.markAsCompleted(any)).thenAnswer((_) async {});

        final result = await syncService.syncODRequests();

        expect(result.success, isTrue);
        expect(result.itemsSynced, equals(1));
        verify(mockQueueManager.markAsInProgress('queue_1')).called(1);
        verify(mockQueueManager.markAsCompleted('queue_1')).called(1);
      });

      test('should handle sync failures gracefully', () async {
        final mockQueueItem = SyncQueueItem(
          id: 'queue_1',
          itemId: 'od_1',
          itemType: 'od_request',
          operation: 'invalid_operation',
          data: {'test': 'data'},
          queuedAt: DateTime.now(),
        );

        when(mockQueueManager.getNextSyncBatch(batchSize: anyNamed('batchSize')))
            .thenAnswer((_) async => [mockQueueItem]);
        when(mockQueueManager.markAsInProgress(any)).thenAnswer((_) async {});
        when(mockQueueManager.markAsFailed(any, any)).thenAnswer((_) async {});

        final result = await syncService.syncODRequests();

        expect(result.success, isFalse);
        expect(result.itemsFailed, equals(1));
        verify(mockQueueManager.markAsFailed('queue_1', any)).called(1);
      });
    });

    group('Queue Management', () {
      setUp(() async {
        await syncService.initialize();
      });

      test('should queue OD request for sync', () async {
        final odRequest = SyncableODRequest(
          id: 'od_1',
          studentId: 'student_1',
          studentName: 'John Doe',
          registerNumber: 'REG001',
          date: DateTime.now(),
          periods: [1, 2],
          reason: 'Medical appointment',
          status: 'pending',
          createdAt: DateTime.now(),
        );

        when(mockQueueManager.queueODRequest(
          requestId: anyNamed('requestId'),
          operation: anyNamed('operation'),
          requestData: anyNamed('requestData'),
        )).thenAnswer((_) async => 'queue_1');

        await syncService.queueForSync(odRequest);

        verify(mockQueueManager.queueODRequest(
          requestId: 'od_1',
          operation: 'create',
          requestData: anyNamed('requestData'),
        )).called(1);
      });

      test('should queue user data for sync', () async {
        final user = SyncableUser(
          id: 'user_1',
          name: 'John Doe',
          email: 'john@example.com',
          role: 'student',
          syncStatus: SyncStatus.pending,
        );

        when(mockQueueManager.queueUserData(
          userId: anyNamed('userId'),
          operation: anyNamed('operation'),
          userData: anyNamed('userData'),
        )).thenAnswer((_) async => 'queue_1');

        await syncService.queueForSync(user);

        verify(mockQueueManager.queueUserData(
          userId: 'user_1',
          operation: 'create',
          userData: anyNamed('userData'),
        )).called(1);
      });

      test('should reject unsupported item types', () async {
        final unsupportedItem = _MockSyncableItem();

        expect(
          () => syncService.queueForSync(unsupportedItem),
          throwsA(isA<SyncError>()),
        );
      });
    });

    group('Conflict Resolution', () {
      setUp(() async {
        await syncService.initialize();
      });

      test('should resolve conflicts using server-side timestamps', () async {
        final conflict = SyncConflict(
          itemId: 'od_1',
          itemType: 'od_request',
          localData: {'version': 1, 'status': 'pending'},
          serverData: {'version': 2, 'status': 'approved'},
          localTimestamp: DateTime.now().subtract(const Duration(hours: 1)),
          serverTimestamp: DateTime.now(),
        );

        when(mockStorageManager.removeResolvedConflict(any))
            .thenAnswer((_) async {});
        when(mockQueueManager.queueItem(
          itemId: anyNamed('itemId'),
          itemType: anyNamed('itemType'),
          operation: anyNamed('operation'),
          data: anyNamed('data'),
          priority: anyNamed('priority'),
        )).thenAnswer((_) async => 'queue_1');

        final resolutions = await syncService.resolveConflicts([conflict]);

        expect(resolutions, hasLength(1));
        expect(resolutions.first.resolution, equals('use_server'));
        expect(resolutions.first.mergedData, equals(conflict.serverData));

        verify(mockStorageManager.removeResolvedConflict('od_1')).called(1);
        verify(mockQueueManager.queueItem(
          itemId: 'od_1',
          itemType: 'od_request',
          operation: 'update',
          data: conflict.serverData,
          priority: 8,
        )).called(1);
      });

      test('should use local data when local timestamp is newer', () async {
        final conflict = SyncConflict(
          itemId: 'od_1',
          itemType: 'od_request',
          localData: {'version': 2, 'status': 'approved'},
          serverData: {'version': 1, 'status': 'pending'},
          localTimestamp: DateTime.now(),
          serverTimestamp: DateTime.now().subtract(const Duration(hours: 1)),
        );

        when(mockStorageManager.removeResolvedConflict(any))
            .thenAnswer((_) async {});
        when(mockQueueManager.queueItem(
          itemId: anyNamed('itemId'),
          itemType: anyNamed('itemType'),
          operation: anyNamed('operation'),
          data: anyNamed('data'),
          priority: anyNamed('priority'),
        )).thenAnswer((_) async => 'queue_1');

        final resolutions = await syncService.resolveConflicts([conflict]);

        expect(resolutions, hasLength(1));
        expect(resolutions.first.resolution, equals('use_local'));
        expect(resolutions.first.mergedData, equals(conflict.localData));
      });

      test('should handle conflict resolution failures', () async {
        final conflict = SyncConflict(
          itemId: 'od_1',
          itemType: 'od_request',
          localData: {'version': 1},
          serverData: {'version': 2},
          localTimestamp: DateTime.now().subtract(const Duration(hours: 1)),
          serverTimestamp: DateTime.now(),
        );

        when(mockStorageManager.removeResolvedConflict(any))
            .thenThrow(Exception('Storage error'));

        final resolutions = await syncService.resolveConflicts([conflict]);

        // Should still return empty list when storage operations fail
        expect(resolutions, isEmpty);
        verify(mockStorageManager.removeResolvedConflict('od_1')).called(1);
      });
    });

    group('Force Sync and Cancellation', () {
      setUp(() async {
        await syncService.initialize();
      });

      test('should reset failed items and force sync', () async {
        when(mockQueueManager.resetFailedItems()).thenAnswer((_) async => 5);

        final result = await syncService.forcSync();

        expect(result.success, isTrue);
        verify(mockQueueManager.resetFailedItems()).called(1);
      });

      test('should cancel ongoing sync operation', () async {
        // Start sync but don't await, and catch any errors
        unawaited(syncService.syncAll().catchError((error) {
          // Expected to throw when cancelled, return a dummy result
          return SyncResult(
            success: false,
            itemsSynced: 0,
            itemsFailed: 0,
            errors: ['Cancelled'],
            timestamp: DateTime.now(),
            duration: Duration.zero,
          );
        }));
        
        // Cancel it
        await syncService.cancelSync();

        expect(syncService.isSyncing, isFalse);
      });

      test('should handle cancel when no sync is running', () async {
        await syncService.cancelSync();
        expect(syncService.isSyncing, isFalse);
      });
    });

    group('Statistics and Monitoring', () {
      setUp(() async {
        await syncService.initialize();
      });

      test('should provide comprehensive sync statistics', () async {
        when(mockQueueManager.getQueueHealth()).thenAnswer((_) async => {
          'isHealthy': true,
          'stats': {'total': 10, 'pending': 2, 'failed': 1},
        });

        final stats = await syncService.getSyncStatistics();

        expect(stats['isConnected'], isTrue);
        expect(stats['isSyncing'], isFalse);
        expect(stats['queueHealth'], isNotNull);
        expect(stats['storageStats'], isNotNull);
        expect(stats['autoSyncEnabled'], isTrue);
      });

      test('should get unresolved conflicts', () {
        final conflicts = [
          SyncConflict(
            itemId: 'od_1',
            itemType: 'od_request',
            localData: {'version': 1},
            serverData: {'version': 2},
            localTimestamp: DateTime.now().subtract(const Duration(hours: 1)),
            serverTimestamp: DateTime.now(),
          ),
        ];

        when(mockStorageManager.getUnresolvedConflicts()).thenReturn(conflicts);

        final result = syncService.getUnresolvedConflicts();

        expect(result, hasLength(1));
        expect(result.first.itemId, equals('od_1'));
      });

      test('should resolve all conflicts automatically', () async {
        final conflicts = [
          SyncConflict(
            itemId: 'od_1',
            itemType: 'od_request',
            localData: {'version': 1},
            serverData: {'version': 2},
            localTimestamp: DateTime.now().subtract(const Duration(hours: 1)),
            serverTimestamp: DateTime.now(),
          ),
        ];

        when(mockStorageManager.getUnresolvedConflicts()).thenReturn(conflicts);
        when(mockStorageManager.removeResolvedConflict(any))
            .thenAnswer((_) async {});
        when(mockQueueManager.queueItem(
          itemId: anyNamed('itemId'),
          itemType: anyNamed('itemType'),
          operation: anyNamed('operation'),
          data: anyNamed('data'),
          priority: anyNamed('priority'),
        )).thenAnswer((_) async => 'queue_1');

        final resolvedCount = await syncService.resolveAllConflicts();

        expect(resolvedCount, equals(1));
        verify(mockStorageManager.getUnresolvedConflicts()).called(1);
      });
    });

    group('Sync Status Stream', () {
      setUp(() async {
        await syncService.initialize();
      });

      test('should emit sync status updates', () async {
        final statusUpdates = <SyncStatus>[];
        final subscription = syncService.syncStatusStream.listen(statusUpdates.add);

        await syncService.syncAll();
        
        // Allow time for all status updates to be processed
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();

        expect(statusUpdates, contains(SyncStatus.inProgress));
        expect(statusUpdates, contains(SyncStatus.completed));
      });

      test('should emit failed status on sync error', () async {
        final statusUpdates = <SyncStatus>[];
        final subscription = syncService.syncStatusStream.listen(statusUpdates.add);

        // Force a sync failure by making queue manager throw an error
        when(mockQueueManager.getNextSyncBatch(batchSize: anyNamed('batchSize')))
            .thenThrow(Exception('Queue error'));

        try {
          await syncService.syncAll();
        } catch (e) {
          // Expected to fail
        }
        
        // Allow time for status updates to be processed
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();

        expect(statusUpdates, contains(SyncStatus.inProgress));
        expect(statusUpdates, contains(SyncStatus.failed));
      });
    });
  });
}

/// Mock implementation of SyncableItem for testing unsupported types
class _MockSyncableItem implements SyncableItem {
  @override
  String get id => 'mock_id';

  @override
  DateTime get lastModified => DateTime.now();

  @override
  SyncStatus get syncStatus => SyncStatus.pending;

  @override
  SyncableItem fromJson(Map<String, dynamic> json) => this;

  @override
  Map<String, dynamic> toJson() => {'id': id};
}