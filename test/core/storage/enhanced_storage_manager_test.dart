import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/core/storage/storage_manager.dart';
import 'package:odtrack_academia/models/sync_models.dart';
import 'dart:io';

void main() {
  group('EnhancedStorageManager', () {
    late EnhancedStorageManager storageManager;
    late String testPath;

    setUpAll(() async {
      // Create a temporary directory for testing
      testPath = '${Directory.current.path}/test_hive';
      await Directory(testPath).create(recursive: true);
      
      // Initialize Hive with test path
      Hive.init(testPath);
      
      // Register test adapters (simplified for testing)
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
      storageManager = EnhancedStorageManager();
      await storageManager.initialize();
    });

    tearDown(() async {
      await storageManager.clearAllData();
      storageManager.dispose();
    });

    tearDownAll(() async {
      await Hive.close();
      await Directory(testPath).delete(recursive: true);
    });

    group('Sync Queue Operations', () {
      test('should add item to sync queue', () async {
        final item = SyncQueueItem(
          id: 'test_1',
          itemId: 'od_request_1',
          itemType: 'od_request',
          operation: 'create',
          data: {'title': 'Test OD Request'},
          queuedAt: DateTime.now(),
        );

        await storageManager.addToSyncQueue(item);
        final pendingItems = await storageManager.getPendingSyncItems();

        expect(pendingItems.length, equals(1));
        expect(pendingItems.first.id, equals('test_1'));
        expect(pendingItems.first.itemType, equals('od_request'));
      });

      test('should update sync queue item status', () async {
        final item = SyncQueueItem(
          id: 'test_2',
          itemId: 'od_request_2',
          itemType: 'od_request',
          operation: 'update',
          data: {'title': 'Updated OD Request'},
          queuedAt: DateTime.now(),
        );

        await storageManager.addToSyncQueue(item);
        await storageManager.updateSyncQueueItem('test_2', SyncStatus.completed);

        final pendingItems = await storageManager.getPendingSyncItems();
        expect(pendingItems.length, equals(0));
      });

      test('should get sync queue statistics', () async {
        final items = [
          SyncQueueItem(
            id: 'test_3',
            itemId: 'od_request_3',
            itemType: 'od_request',
            operation: 'create',
            data: {'title': 'Test 3'},
            queuedAt: DateTime.now(),
            status: SyncStatus.pending,
          ),
          SyncQueueItem(
            id: 'test_4',
            itemId: 'od_request_4',
            itemType: 'od_request',
            operation: 'update',
            data: {'title': 'Test 4'},
            queuedAt: DateTime.now(),
            status: SyncStatus.failed,
          ),
        ];

        for (final item in items) {
          await storageManager.addToSyncQueue(item);
        }

        final stats = await storageManager.getSyncQueueStats();
        expect(stats['total'], equals(2));
        expect(stats['pending'], equals(1));
        expect(stats['failed'], equals(1));
      });

      test('should remove completed sync items', () async {
        final items = [
          SyncQueueItem(
            id: 'test_5',
            itemId: 'od_request_5',
            itemType: 'od_request',
            operation: 'create',
            data: {'title': 'Test 5'},
            queuedAt: DateTime.now(),
            status: SyncStatus.completed,
          ),
          SyncQueueItem(
            id: 'test_6',
            itemId: 'od_request_6',
            itemType: 'od_request',
            operation: 'create',
            data: {'title': 'Test 6'},
            queuedAt: DateTime.now(),
            status: SyncStatus.pending,
          ),
        ];

        for (final item in items) {
          await storageManager.addToSyncQueue(item);
        }

        await storageManager.removeCompletedSyncItems();
        final stats = await storageManager.getSyncQueueStats();
        expect(stats['total'], equals(1));
        expect(stats['pending'], equals(1));
      });
    });

    group('Cache Management Operations', () {
      test('should cache and retrieve data', () async {
        final testData = {'key': 'value', 'number': 42};
        await storageManager.cacheData('test_key', testData);

        final retrievedData = await storageManager.getCachedData('test_key');
        expect(retrievedData, isNotNull);
        expect(retrievedData!['key'], equals('value'));
        expect(retrievedData['number'], equals(42));
      });

      test('should check if data is cached', () async {
        final testData = {'cached': true};
        await storageManager.cacheData('cached_key', testData);

        expect(storageManager.isCached('cached_key'), isTrue);
        expect(storageManager.isCached('non_existent_key'), isFalse);
      });

      test('should remove cache item', () async {
        final testData = {'to_remove': true};
        await storageManager.cacheData('remove_key', testData);

        expect(storageManager.isCached('remove_key'), isTrue);
        await storageManager.removeCacheItem('remove_key');
        expect(storageManager.isCached('remove_key'), isFalse);
      });

      test('should clean up expired cache items', () async {
        final testData = {'expired': true};
        await storageManager.cacheData(
          'expired_key', 
          testData, 
          ttl: const Duration(milliseconds: 1),
        );

        // Wait for expiration
        await Future<void>.delayed(const Duration(milliseconds: 10));
        
        final cleanedCount = await storageManager.cleanupExpiredCache();
        expect(cleanedCount, greaterThan(0));
        expect(storageManager.isCached('expired_key'), isFalse);
      });

      test('should get cache statistics', () async {
        final testData = {'stats_test': true};
        await storageManager.cacheData('stats_key', testData);

        final stats = await storageManager.getCacheStats();
        expect(stats['totalItems'], greaterThan(0));
        expect(stats['totalSizeBytes'], greaterThan(0));
        expect(stats.containsKey('totalSizeMB'), isTrue);
      });

      test('should handle cache capacity limits', () async {
        // This test would be more complex in a real scenario
        // For now, we'll just verify that large data can be cached
        final largeData = <String, dynamic>{};
        for (int i = 0; i < 100; i++) {
          largeData['key_$i'] = 'value_$i' * 100;
        }

        await storageManager.cacheData('large_data', largeData);
        final retrieved = await storageManager.getCachedData('large_data');
        expect(retrieved, isNotNull);
        expect(retrieved!.length, equals(largeData.length));
      });
    });

    group('Conflict Resolution Operations', () {
      test('should store and retrieve sync conflicts', () async {
        final conflict = SyncConflict(
          itemId: 'conflict_item_1',
          itemType: 'od_request',
          localData: {'local': 'data'},
          serverData: {'server': 'data'},
          localTimestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          serverTimestamp: DateTime.now(),
        );

        await storageManager.storeSyncConflict(conflict);
        final conflicts = storageManager.getUnresolvedConflicts();

        expect(conflicts.length, equals(1));
        expect(conflicts.first.itemId, equals('conflict_item_1'));
        expect(conflicts.first.itemType, equals('od_request'));
      });

      test('should remove resolved conflicts', () async {
        final conflict = SyncConflict(
          itemId: 'conflict_item_2',
          itemType: 'od_request',
          localData: {'local': 'data'},
          serverData: {'server': 'data'},
          localTimestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          serverTimestamp: DateTime.now(),
        );

        await storageManager.storeSyncConflict(conflict);
        expect(storageManager.getUnresolvedConflicts().length, equals(1));

        await storageManager.removeResolvedConflict('conflict_item_2');
        expect(storageManager.getUnresolvedConflicts().length, equals(0));
      });

      test('should clear all conflicts', () async {
        final conflicts = [
          SyncConflict(
            itemId: 'conflict_item_3',
            itemType: 'od_request',
            localData: {'local': 'data1'},
            serverData: {'server': 'data1'},
            localTimestamp: DateTime.now(),
            serverTimestamp: DateTime.now(),
          ),
          SyncConflict(
            itemId: 'conflict_item_4',
            itemType: 'user_data',
            localData: {'local': 'data2'},
            serverData: {'server': 'data2'},
            localTimestamp: DateTime.now(),
            serverTimestamp: DateTime.now(),
          ),
        ];

        for (final conflict in conflicts) {
          await storageManager.storeSyncConflict(conflict);
        }

        expect(storageManager.getUnresolvedConflicts().length, equals(2));
        await storageManager.clearAllConflicts();
        expect(storageManager.getUnresolvedConflicts().length, equals(0));
      });
    });

    group('Utility Operations', () {
      test('should get overall storage statistics', () async {
        // Add some test data
        await storageManager.addToSyncQueue(SyncQueueItem(
          id: 'stats_test',
          itemId: 'test_item',
          itemType: 'od_request',
          operation: 'create',
          data: {'test': 'data'},
          queuedAt: DateTime.now(),
        ));

        await storageManager.cacheData('stats_cache', {'cached': 'data'});

        final stats = await storageManager.getStorageStats();
        expect(stats.containsKey('syncQueue'), isTrue);
        expect(stats.containsKey('cache'), isTrue);
        expect(stats.containsKey('conflicts'), isTrue);
        expect(stats['totalBoxes'], equals(4));
      });

      test('should clear all data', () async {
        // Add test data to all storage types
        await storageManager.addToSyncQueue(SyncQueueItem(
          id: 'clear_test',
          itemId: 'test_item',
          itemType: 'od_request',
          operation: 'create',
          data: {'test': 'data'},
          queuedAt: DateTime.now(),
        ));

        await storageManager.cacheData('clear_cache', {'cached': 'data'});

        await storageManager.storeSyncConflict(SyncConflict(
          itemId: 'clear_conflict',
          itemType: 'od_request',
          localData: {'local': 'data'},
          serverData: {'server': 'data'},
          localTimestamp: DateTime.now(),
          serverTimestamp: DateTime.now(),
        ));

        // Verify data exists
        expect((await storageManager.getPendingSyncItems()).length, greaterThan(0));
        expect(storageManager.isCached('clear_cache'), isTrue);
        expect(storageManager.getUnresolvedConflicts().length, greaterThan(0));

        // Clear all data
        await storageManager.clearAllData();

        // Verify data is cleared
        expect((await storageManager.getPendingSyncItems()).length, equals(0));
        expect(storageManager.isCached('clear_cache'), isFalse);
        expect(storageManager.getUnresolvedConflicts().length, equals(0));
      });

      test('should optimize storage', () async {
        // Add some data first
        await storageManager.cacheData('optimize_test', {'data': 'test'});
        
        // This should complete without errors
        await storageManager.optimizeStorage();
        
        // Verify data is still accessible after optimization
        final data = await storageManager.getCachedData('optimize_test');
        expect(data, isNotNull);
        expect(data!['data'], equals('test'));
      });
    });
  });
}

// Test adapters (simplified versions for testing)
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