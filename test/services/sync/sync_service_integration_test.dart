import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:odtrack_academia/core/storage/enhanced_storage_manager.dart';
import 'package:odtrack_academia/core/storage/sync_queue_manager.dart';
import 'package:odtrack_academia/models/syncable_od_request.dart';
import 'package:odtrack_academia/models/sync_models.dart';
import 'package:odtrack_academia/services/sync/hive_sync_service.dart';

import 'sync_service_integration_test.mocks.dart';

@GenerateMocks([
  EnhancedStorageManager,
  SyncQueueManager,
  Connectivity,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Sync Service Integration', () {
    late HiveSyncService syncService;
    late MockEnhancedStorageManager mockStorageManager;
    late MockSyncQueueManager mockQueueManager;
    late MockConnectivity mockConnectivity;

    setUp(() async {
      mockStorageManager = MockEnhancedStorageManager();
      mockQueueManager = MockSyncQueueManager();
      mockConnectivity = MockConnectivity();

      // Setup basic mocks
      when(mockStorageManager.initialize()).thenAnswer((_) async {});
      when(mockStorageManager.getStorageStats()).thenReturn({
        'totalBoxes': 4,
        'syncQueue': {'total': 0, 'pending': 0, 'failed': 0},
        'cache': {'totalItems': 0},
        'conflicts': 0,
      });
      when(mockQueueManager.getQueueHealth()).thenReturn({
        'isHealthy': true,
        'stats': {'total': 0, 'pending': 0, 'failed': 0},
      });
      
      // Setup connectivity mocks
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => Stream.value([ConnectivityResult.wifi]));

      syncService = HiveSyncService(
        storageManager: mockStorageManager,
        queueManager: mockQueueManager,
        connectivity: mockConnectivity,
      );
    });

    test('should initialize sync service', () async {
      await syncService.initialize();
      
      expect(syncService.isInitialized, isTrue);
      expect(syncService.serviceName, equals('HiveSyncService'));
    });

    test('should queue and sync OD request', () async {
      await syncService.initialize();

      // Setup queue manager mock
      when(mockQueueManager.queueODRequest(
        requestId: anyNamed('requestId'),
        operation: anyNamed('operation'),
        requestData: anyNamed('requestData'),
      )).thenAnswer((_) async => 'queue_1');

      // Create a test OD request
      final odRequest = SyncableODRequest(
        id: 'test_od_1',
        studentId: 'student_123',
        studentName: 'John Doe',
        registerNumber: 'REG001',
        date: DateTime.now().add(Duration(days: 1)),
        periods: [1, 2],
        reason: 'Medical appointment',
        status: 'pending',
        createdAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      // Queue for sync
      await syncService.queueForSync(odRequest);

      // Verify queue operation was called
      verify(mockQueueManager.queueODRequest(
        requestId: 'test_od_1',
        operation: 'create',
        requestData: anyNamed('requestData'),
      )).called(1);
    });

    test('should handle sync conflicts', () async {
      await syncService.initialize();

      // Setup storage manager mocks
      when(mockStorageManager.removeResolvedConflict(any)).thenAnswer((_) async {});
      when(mockQueueManager.queueItem(
        itemId: anyNamed('itemId'),
        itemType: anyNamed('itemType'),
        operation: anyNamed('operation'),
        data: anyNamed('data'),
        priority: anyNamed('priority'),
      )).thenAnswer((_) async => 'queue_1');

      // Create a test conflict
      final conflict = SyncConflict(
        itemId: 'conflict_item',
        itemType: 'od_request',
        localData: const {
          'id': 'conflict_item',
          'status': 'pending',
          'version': 1,
        },
        serverData: const {
          'id': 'conflict_item',
          'status': 'approved',
          'version': 2,
        },
        localTimestamp: DateTime.now().subtract(Duration(hours: 1)),
        serverTimestamp: DateTime.now(),
      );

      // Resolve conflicts
      final resolutions = await syncService.resolveConflicts([conflict]);
      
      expect(resolutions, hasLength(1));
      expect(resolutions.first.resolution, equals('use_server'));
    });

    test('should provide comprehensive sync statistics', () async {
      await syncService.initialize();

      final stats = syncService.getSyncStatistics();
      
      expect(stats, containsPair('isConnected', isA<bool>()));
      expect(stats, containsPair('isSyncing', isA<bool>()));
      expect(stats, containsPair('queueHealth', isA<Map<dynamic, dynamic>>()));
      expect(stats, containsPair('storageStats', isA<Map<dynamic, dynamic>>()));
      expect(stats, containsPair('autoSyncEnabled', isA<bool>()));
    });

    test('should handle service health checks', () async {
      await syncService.initialize();

      final isHealthy = await syncService.isHealthy();
      expect(isHealthy, isTrue);
    });
  });
}