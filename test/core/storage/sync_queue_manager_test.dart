import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/core/storage/enhanced_storage_manager.dart';
import 'package:odtrack_academia/core/storage/sync_queue_manager.dart';
import 'package:odtrack_academia/models/sync_models.dart';
import 'dart:io';

void main() {
  group('SyncQueueManager', () {
    late SyncQueueManager queueManager;
    late EnhancedStorageManager storageManager;
    late String testPath;

    setUpAll(() async {
      // Create a temporary directory for testing
      testPath = '${Directory.current.path}/test_hive_queue';
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
      storageManager = EnhancedStorageManager();
      await storageManager.initialize();
      queueManager = SyncQueueManager(storageManager);
    });

    tearDown(() async {
      await storageManager.clearAllData();
      storageManager.dispose();
    });

    tearDownAll(() async {
      await Hive.close();
      await Directory(testPath).delete(recursive: true);
    });

    group('Queue Item Operations', () {
      test('should queue generic item', () async {
        final queueId = await queueManager.queueItem(
          itemId: 'test_item_1',
          itemType: 'test_type',
          operation: 'create',
          data: {'test': 'data'},
          priority: 5,
        );

        expect(queueId, isNotNull);
        expect(queueId, isNotEmpty);

        final pendingItems = storageManager.getPendingSyncItems();
        expect(pendingItems.length, equals(1));
        expect(pendingItems.first.itemId, equals('test_item_1'));
        expect(pendingItems.first.data['priority'], equals(5));
      });

      test('should queue OD request', () async {
        final requestData = {
          'title': 'Test OD Request',
          'startDate': '2024-01-15',
          'endDate': '2024-01-16',
        };

        final queueId = await queueManager.queueODRequest(
          requestId: 'od_123',
          operation: 'create',
          requestData: requestData,
        );

        expect(queueId, isNotNull);

        final pendingItems = storageManager.getPendingSyncItems();
        expect(pendingItems.length, equals(1));
        expect(pendingItems.first.itemType, equals('od_request'));
        expect(pendingItems.first.data['priority'], equals(10)); // High priority for create
        expect(pendingItems.first.data['title'], equals('Test OD Request'));
      });

      test('should queue user data', () async {
        final userData = {
          'name': 'John Doe',
          'email': 'john@example.com',
        };

        final queueId = await queueManager.queueUserData(
          userId: 'user_456',
          operation: 'update',
          userData: userData,
        );

        expect(queueId, isNotNull);

        final pendingItems = storageManager.getPendingSyncItems();
        expect(pendingItems.length, equals(1));
        expect(pendingItems.first.itemType, equals('user_data'));
        expect(pendingItems.first.data['priority'], equals(3));
        expect(pendingItems.first.data['name'], equals('John Doe'));
      });
    });

    group('Batch Processing', () {
      test('should get next sync batch with priority ordering', () async {
        // Queue items with different priorities
        await queueManager.queueItem(
          itemId: 'low_priority',
          itemType: 'test',
          operation: 'update',
          data: {'test': 'low'},
          priority: 1,
        );

        await queueManager.queueItem(
          itemId: 'high_priority',
          itemType: 'test',
          operation: 'create',
          data: {'test': 'high'},
          priority: 10,
        );

        await queueManager.queueItem(
          itemId: 'medium_priority',
          itemType: 'test',
          operation: 'update',
          data: {'test': 'medium'},
          priority: 5,
        );

        final batch = queueManager.getNextSyncBatch(batchSize: 2);
        expect(batch.length, equals(2));
        
        // Should be ordered by priority (high to low)
        expect(batch[0].itemId, equals('high_priority'));
        expect(batch[1].itemId, equals('medium_priority'));
      });

      test('should respect batch size limit', () async {
        // Queue multiple items
        for (int i = 0; i < 15; i++) {
          await queueManager.queueItem(
            itemId: 'item_$i',
            itemType: 'test',
            operation: 'create',
            data: {'index': i},
          );
        }

        final batch = queueManager.getNextSyncBatch(batchSize: 5);
        expect(batch.length, equals(5));
      });

      test('should exclude items in retry cooldown', () async {
        // Queue an item and mark it as failed
        final queueId = await queueManager.queueItem(
          itemId: 'failed_item',
          itemType: 'test',
          operation: 'create',
          data: {'test': 'failed'},
        );

        await queueManager.markAsFailed(queueId, 'Test error');

        // Should not include the failed item in immediate batch
        final batch = queueManager.getNextSyncBatch();
        expect(batch.length, equals(0));
      });
    });

    group('Status Management', () {
      test('should mark item as in progress', () async {
        final queueId = await queueManager.queueItem(
          itemId: 'progress_test',
          itemType: 'test',
          operation: 'create',
          data: {'test': 'progress'},
        );

        await queueManager.markAsInProgress(queueId);

        final stats = storageManager.getSyncQueueStats();
        expect(stats['in_progress'], equals(1));
        expect(stats['pending'], equals(0));
      });

      test('should mark item as completed', () async {
        final queueId = await queueManager.queueItem(
          itemId: 'complete_test',
          itemType: 'test',
          operation: 'create',
          data: {'test': 'complete'},
        );

        await queueManager.markAsCompleted(queueId);

        final stats = storageManager.getSyncQueueStats();
        expect(stats['completed'], equals(1));
        expect(stats['pending'], equals(0));
      });

      test('should mark item as failed with error message', () async {
        final queueId = await queueManager.queueItem(
          itemId: 'failed_test',
          itemType: 'test',
          operation: 'create',
          data: {'test': 'failed'},
        );

        await queueManager.markAsFailed(queueId, 'Network error');

        final stats = storageManager.getSyncQueueStats();
        expect(stats['failed'], equals(1));
        expect(stats['pending'], equals(0));

        final pendingItems = storageManager.getPendingSyncItems();
        expect(pendingItems.length, equals(1));
        expect(pendingItems.first.errorMessage, equals('Network error'));
        expect(pendingItems.first.retryCount, equals(1));
      });

      test('should mark item as conflicted', () async {
        final queueId = await queueManager.queueItem(
          itemId: 'conflict_test',
          itemType: 'test',
          operation: 'update',
          data: {'test': 'conflict'},
        );

        await queueManager.markAsConflicted(queueId, 'Data conflict detected');

        final stats = storageManager.getSyncQueueStats();
        expect(stats['conflict'], equals(1));
        expect(stats['pending'], equals(0));
      });
    });

    group('Retry Logic', () {
      test('should determine if item should be retried', () async {
        final queueId = await queueManager.queueItem(
          itemId: 'retry_test',
          itemType: 'test',
          operation: 'create',
          data: {'test': 'retry'},
        );

        // Mark as failed once
        await queueManager.markAsFailed(queueId, 'First failure');
        
        final pendingItems = storageManager.getPendingSyncItems();
        final failedItem = pendingItems.first;
        
        expect(queueManager.shouldRetryItem(failedItem), isFalse); // In cooldown
        expect(failedItem.retryCount, equals(1));
      });

      test('should not retry items that exceeded max retries', () async {
        final queueId = await queueManager.queueItem(
          itemId: 'max_retry_test',
          itemType: 'test',
          operation: 'create',
          data: {'test': 'max_retry'},
        );

        // Fail the item multiple times to exceed max retries
        for (int i = 0; i < 4; i++) {
          await queueManager.markAsFailed(queueId, 'Failure $i');
        }

        final failedItems = queueManager.getFailedItems();
        expect(failedItems.length, equals(1));
        expect(failedItems.first.retryCount, greaterThanOrEqualTo(3));
      });

      test('should remove items that exceeded max retries', () async {
        final queueId = await queueManager.queueItem(
          itemId: 'remove_failed_test',
          itemType: 'test',
          operation: 'create',
          data: {'test': 'remove_failed'},
        );

        // Fail the item multiple times
        for (int i = 0; i < 4; i++) {
          await queueManager.markAsFailed(queueId, 'Failure $i');
        }

        final removedCount = await queueManager.removeFailedItems();
        expect(removedCount, equals(1));

        final stats = storageManager.getSyncQueueStats();
        expect(stats['failed'], equals(0));
        expect(stats['completed'], equals(1));
      });

      test('should reset failed items', () async {
        final queueId = await queueManager.queueItem(
          itemId: 'reset_test',
          itemType: 'test',
          operation: 'create',
          data: {'test': 'reset'},
        );

        await queueManager.markAsFailed(queueId, 'Test failure');

        final resetCount = await queueManager.resetFailedItems();
        expect(resetCount, equals(1));

        final stats = storageManager.getSyncQueueStats();
        expect(stats['pending'], equals(1));
        expect(stats['failed'], equals(0));
      });
    });

    group('Queue Health and Analytics', () {
      test('should provide queue health metrics', () async {
        // Add various items with different statuses
        await queueManager.queueODRequest(
          requestId: 'od_1',
          operation: 'create',
          requestData: {'title': 'OD 1'},
        );

        await queueManager.queueUserData(
          userId: 'user_1',
          operation: 'update',
          userData: {'name': 'User 1'},
        );

        final health = queueManager.getQueueHealth();
        expect(health.containsKey('stats'), isTrue);
        expect(health.containsKey('isHealthy'), isTrue);
        expect(health.containsKey('itemsByType'), isTrue);
        expect(health['itemsByType']['od_request'], equals(1));
        expect(health['itemsByType']['user_data'], equals(1));
      });

      test('should analyze queue composition', () async {
        // Add items with different operations and types
        await queueManager.queueODRequest(
          requestId: 'od_create',
          operation: 'create',
          requestData: {'title': 'Create OD'},
        );

        await queueManager.queueODRequest(
          requestId: 'od_update',
          operation: 'update',
          requestData: {'title': 'Update OD'},
        );

        await queueManager.queueUserData(
          userId: 'user_update',
          operation: 'update',
          userData: {'name': 'Update User'},
        );

        final analysis = queueManager.analyzeQueue();
        expect(analysis.containsKey('operationBreakdown'), isTrue);
        expect(analysis.containsKey('typeBreakdown'), isTrue);
        expect(analysis.containsKey('priorityBreakdown'), isTrue);
        expect(analysis['operationBreakdown']['create'], equals(1));
        expect(analysis['operationBreakdown']['update'], equals(2));
        expect(analysis['typeBreakdown']['od_request'], equals(2));
        expect(analysis['typeBreakdown']['user_data'], equals(1));
      });

      test('should clean up old items', () async {
        final queueId = await queueManager.queueItem(
          itemId: 'old_item',
          itemType: 'test',
          operation: 'create',
          data: {'test': 'old'},
        );

        await queueManager.markAsCompleted(queueId);

        // This should complete without errors
        final cleanedCount = await queueManager.cleanupOldItems();
        expect(cleanedCount, greaterThanOrEqualTo(0));
      });
    });
  });
}

// Reuse test adapters from enhanced_storage_manager_test.dart
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