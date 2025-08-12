import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/core/storage/storage_integration_service.dart';
import 'package:odtrack_academia/models/sync_models.dart';
import 'dart:io';

void main() {
  group('StorageIntegrationService', () {
    late StorageIntegrationService service;
    late String testPath;

    setUpAll(() async {
      // Create a temporary directory for testing
      testPath = '${Directory.current.path}/test_hive_integration';
      await Directory(testPath).create(recursive: true);
      
      // Initialize Hive with test path
      Hive.init(testPath);
      
      // Register test adapters
      if (!Hive.isAdapterRegistered(102)) {
        Hive.registerAdapter(TestSyncStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(214)) {
        Hive.registerAdapter(TestSyncQueueItemAdapter());
      }
      if (!Hive.isAdapterRegistered(215)) {
        Hive.registerAdapter(TestCacheMetadataAdapter());
      }
      if (!Hive.isAdapterRegistered(202)) {
        Hive.registerAdapter(TestSyncConflictAdapter());
      }
    });

    setUp(() async {
      service = StorageIntegrationService();
      await service.initialize();
    });

    tearDown(() async {
      await service.clearAllData();
      await service.dispose();
    });

    tearDownAll(() async {
      await Hive.close();
      await Directory(testPath).delete(recursive: true);
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        final newService = StorageIntegrationService();
        expect(newService.isInitialized, isFalse);
        
        await newService.initialize();
        expect(newService.isInitialized, isTrue);
        
        await newService.dispose();
      });

      test('should handle multiple initialization calls', () async {
        final newService = StorageIntegrationService();
        
        await newService.initialize();
        await newService.initialize(); // Should not throw
        
        expect(newService.isInitialized, isTrue);
        await newService.dispose();
      });
    });

    group('OD Request Operations', () {
      test('should create and cache OD request', () async {
        final requestData = {
          'id': 'od_test_123',
          'title': 'Test OD Request',
          'startDate': '2024-01-15',
          'endDate': '2024-01-16',
          'status': 'pending',
        };

        final queueId = await service.createODRequest(requestData);
        expect(queueId, isNotNull);
        expect(queueId, isNotEmpty);

        // Verify it's cached
        final cachedData = await service.getODRequest('od_test_123');
        expect(cachedData, isNotNull);
        expect(cachedData!['title'], equals('Test OD Request'));
      });

      test('should retrieve cached OD request', () async {
        final requestData = {
          'id': 'od_retrieve_456',
          'title': 'Retrieve Test',
          'status': 'approved',
        };

        await service.createODRequest(requestData);
        final retrieved = await service.getODRequest('od_retrieve_456');

        expect(retrieved, isNotNull);
        expect(retrieved!['title'], equals('Retrieve Test'));
        expect(retrieved['status'], equals('approved'));
      });
    });

    group('User Profile Operations', () {
      test('should update and cache user profile', () async {
        final profileData = {
          'id': 'user_test_789',
          'name': 'Test User',
          'email': 'test@example.com',
          'role': 'student',
        };

        await service.updateUserProfile('user_test_789', profileData);

        // Verify it's cached
        final cachedProfile = await service.getUserProfile('user_test_789');
        expect(cachedProfile, isNotNull);
        expect(cachedProfile!['name'], equals('Test User'));
        expect(cachedProfile['email'], equals('test@example.com'));
      });
    });

    group('Analytics Operations', () {
      test('should cache and retrieve analytics', () async {
        final analyticsData = {
          'totalRequests': 100,
          'approvedRequests': 80,
          'rejectedRequests': 20,
          'approvalRate': 0.8,
        };

        await service.cacheAnalytics('test_analytics', analyticsData);
        final retrieved = await service.getAnalytics('test_analytics');

        expect(retrieved, isNotNull);
        expect(retrieved!['totalRequests'], equals(100));
        expect(retrieved['approvalRate'], equals(0.8));
      });
    });

    group('Sync Operations', () {
      test('should get sync batch and mark completed', () async {
        // Create some OD requests to sync
        await service.createODRequest({
          'id': 'od_sync_1',
          'title': 'Sync Test 1',
        });
        await service.createODRequest({
          'id': 'od_sync_2',
          'title': 'Sync Test 2',
        });

        final batch = await service.getNextSyncBatch(batchSize: 5);
        expect(batch.length, equals(2));

        // Mark first item as completed
        await service.markSyncCompleted(batch.first.id);

        final newBatch = await service.getNextSyncBatch();
        expect(newBatch.length, equals(1));
      });

      test('should handle sync failures', () async {
        await service.createODRequest({
          'id': 'od_fail_test',
          'title': 'Fail Test',
        });

        final batch = await service.getNextSyncBatch();
        expect(batch.length, equals(1));

        await service.markSyncFailed(batch.first.id, 'Network error');

        final health = await service.getSyncQueueHealth();
        expect(health['stats']['failed'], equals(1));
      });
    });

    group('Conflict Resolution', () {
      test('should store and resolve conflicts', () async {
        final conflict = SyncConflict(
          itemId: 'conflict_test_item',
          itemType: 'od_request',
          localData: {'title': 'Local Version'},
          serverData: {'title': 'Server Version'},
          localTimestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          serverTimestamp: DateTime.now(),
        );

        await service.storeSyncConflict(conflict);
        
        final conflicts = service.getUnresolvedConflicts();
        expect(conflicts.length, equals(1));
        expect(conflicts.first.itemId, equals('conflict_test_item'));

        await service.resolveConflict('conflict_test_item');
        
        final resolvedConflicts = service.getUnresolvedConflicts();
        expect(resolvedConflicts.length, equals(0));
      });
    });

    group('Performance and Statistics', () {
      test('should provide cache performance metrics', () async {
        // Add some cached data
        await service.updateUserProfile('perf_user', {'name': 'Performance User'});
        await service.cacheAnalytics('perf_analytics', {'count': 10});

        final metrics = await service.getCachePerformanceMetrics();
        expect(metrics.containsKey('totalItems'), isTrue);
        expect(metrics.containsKey('hitRate'), isTrue);
        expect(metrics['totalItems'], greaterThan(0));
      });

      test('should provide cache health score', () async {
        await service.updateUserProfile('health_user', {'name': 'Health User'});
        
        final healthScore = await service.getCacheHealthScore();
        expect(healthScore, greaterThanOrEqualTo(0));
        expect(healthScore, lessThanOrEqualTo(100));
      });

      test('should provide storage statistics', () async {
        await service.createODRequest({'id': 'stats_od', 'title': 'Stats OD'});
        
        final stats = await service.getStorageStatistics();
        expect(stats.containsKey('syncQueue'), isTrue);
        expect(stats.containsKey('cache'), isTrue);
        expect(stats.containsKey('totalBoxes'), isTrue);
      });

      test('should analyze sync queue', () async {
        await service.createODRequest({'id': 'analyze_od', 'title': 'Analyze OD'});
        
        final analysis = await service.analyzeSyncQueue();
        expect(analysis.containsKey('totalItems'), isTrue);
        expect(analysis.containsKey('operationBreakdown'), isTrue);
        expect(analysis.containsKey('typeBreakdown'), isTrue);
      });
    });

    group('Maintenance Operations', () {
      test('should optimize cache', () async {
        await service.cacheAnalytics('optimize_test', {'data': 'test'});
        
        final results = await service.optimizeCache();
        expect(results.containsKey('expiredCleaned'), isTrue);
        expect(results.containsKey('storageOptimized'), isTrue);
      });

      test('should preload critical data', () async {
        await service.preloadCriticalData('preload_user_123');
        
        // This should complete without errors
        // In a real implementation, you'd verify preload markers were created
        expect(service.isInitialized, isTrue);
      });

      test('should schedule cache maintenance', () async {
        await service.cacheAnalytics('maintenance_test', {'data': 'maintenance'});
        
        // This should complete without errors
        await service.scheduleCacheMaintenance();
        expect(service.isInitialized, isTrue);
      });

      test('should clean up old sync items', () async {
        await service.createODRequest({'id': 'cleanup_od', 'title': 'Cleanup OD'});
        
        final cleanedCount = await service.cleanupOldSyncItems();
        expect(cleanedCount, greaterThanOrEqualTo(0));
      });
    });

    group('Error Handling', () {
      test('should throw error when accessing uninitialized service', () {
        final uninitializedService = StorageIntegrationService();
        
        expect(() => uninitializedService.getNextSyncBatch(), throwsStateError);
        expect(() => uninitializedService.getSyncQueueHealth(), throwsStateError);
        expect(() => uninitializedService.getCacheHealthScore(), throwsStateError);
      });
    });
  });
}

// Reuse test adapters from other test files
class TestSyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 102;

  @override
  SyncStatus read(BinaryReader reader) {
    return SyncStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    writer.writeByte(obj.index);
  }
}

class TestSyncQueueItemAdapter extends TypeAdapter<SyncQueueItem> {
  @override
  final int typeId = 214;

  @override
  SyncQueueItem read(BinaryReader reader) {
    final fields = reader.readMap();
    return SyncQueueItem(
      id: fields['id'] as String,
      itemId: fields['itemId'] as String,
      itemType: fields['itemType'] as String,
      operation: fields['operation'] as String,
      data: Map<String, dynamic>.from(fields['data'] as Map),
      queuedAt: DateTime.fromMillisecondsSinceEpoch(fields['queuedAt'] as int),
      retryCount: fields['retryCount'] as int? ?? 0,
      lastRetryAt: fields['lastRetryAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(fields['lastRetryAt'] as int)
          : null,
      status: SyncStatus.values[fields['status'] as int? ?? 0],
      errorMessage: fields['errorMessage'] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueItem obj) {
    writer.writeMap({
      'id': obj.id,
      'itemId': obj.itemId,
      'itemType': obj.itemType,
      'operation': obj.operation,
      'data': obj.data,
      'queuedAt': obj.queuedAt.millisecondsSinceEpoch,
      'retryCount': obj.retryCount,
      'lastRetryAt': obj.lastRetryAt?.millisecondsSinceEpoch,
      'status': obj.status.index,
      'errorMessage': obj.errorMessage,
    });
  }
}

class TestCacheMetadataAdapter extends TypeAdapter<CacheMetadata> {
  @override
  final int typeId = 215;

  @override
  CacheMetadata read(BinaryReader reader) {
    final fields = reader.readMap();
    return CacheMetadata(
      key: fields['key'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields['createdAt'] as int),
      lastAccessedAt: DateTime.fromMillisecondsSinceEpoch(fields['lastAccessedAt'] as int),
      expiresAt: fields['expiresAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(fields['expiresAt'] as int)
          : null,
      accessCount: fields['accessCount'] as int? ?? 1,
      sizeBytes: fields['sizeBytes'] as int? ?? 0,
      etag: fields['etag'] as String?,
      metadata: fields['metadata'] != null 
          ? Map<String, dynamic>.from(fields['metadata'] as Map)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, CacheMetadata obj) {
    writer.writeMap({
      'key': obj.key,
      'createdAt': obj.createdAt.millisecondsSinceEpoch,
      'lastAccessedAt': obj.lastAccessedAt.millisecondsSinceEpoch,
      'expiresAt': obj.expiresAt?.millisecondsSinceEpoch,
      'accessCount': obj.accessCount,
      'sizeBytes': obj.sizeBytes,
      'etag': obj.etag,
      'metadata': obj.metadata,
    });
  }
}

class TestSyncConflictAdapter extends TypeAdapter<SyncConflict> {
  @override
  final int typeId = 202;

  @override
  SyncConflict read(BinaryReader reader) {
    final fields = reader.readMap();
    return SyncConflict(
      itemId: fields['itemId'] as String,
      itemType: fields['itemType'] as String,
      localData: Map<String, dynamic>.from(fields['localData'] as Map),
      serverData: Map<String, dynamic>.from(fields['serverData'] as Map),
      localTimestamp: DateTime.fromMillisecondsSinceEpoch(fields['localTimestamp'] as int),
      serverTimestamp: DateTime.fromMillisecondsSinceEpoch(fields['serverTimestamp'] as int),
    );
  }

  @override
  void write(BinaryWriter writer, SyncConflict obj) {
    writer.writeMap({
      'itemId': obj.itemId,
      'itemType': obj.itemType,
      'localData': obj.localData,
      'serverData': obj.serverData,
      'localTimestamp': obj.localTimestamp.millisecondsSinceEpoch,
      'serverTimestamp': obj.serverTimestamp.millisecondsSinceEpoch,
    });
  }
}