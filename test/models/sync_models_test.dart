import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/models/sync_models.dart';

void main() {
  group('SyncResult', () {
    test('should create sync result with all fields', () {
      final timestamp = DateTime.now();
      const duration = Duration(seconds: 30);
      const errors = ['Error 1', 'Error 2'];
      
      final result = SyncResult(
        success: true,
        itemsSynced: 10,
        itemsFailed: 2,
        errors: errors,
        timestamp: timestamp,
        duration: duration,
      );

      expect(result.success, true);
      expect(result.itemsSynced, 10);
      expect(result.itemsFailed, 2);
      expect(result.errors, errors);
      expect(result.timestamp, timestamp);
      expect(result.duration, duration);
    });

    test('should serialize to and from JSON', () {
      final timestamp = DateTime.now();
      const duration = Duration(minutes: 2);
      
      final result = SyncResult(
        success: false,
        itemsSynced: 5,
        itemsFailed: 3,
        errors: const ['Network error', 'Timeout'],
        timestamp: timestamp,
        duration: duration,
      );

      final json = result.toJson();
      final deserialized = SyncResult.fromJson(json);

      expect(deserialized.success, result.success);
      expect(deserialized.itemsSynced, result.itemsSynced);
      expect(deserialized.itemsFailed, result.itemsFailed);
      expect(deserialized.errors, result.errors);
      expect(deserialized.timestamp, result.timestamp);
      expect(deserialized.duration, result.duration);
    });
  });

  group('SyncConflict', () {
    test('should create sync conflict with all fields', () {
      final localTimestamp = DateTime.now().subtract(const Duration(minutes: 5));
      final serverTimestamp = DateTime.now();
      const localData = {'name': 'Local Name', 'version': 1};
      const serverData = {'name': 'Server Name', 'version': 2};
      
      final conflict = SyncConflict(
        itemId: '123',
        itemType: 'ODRequest',
        localData: localData,
        serverData: serverData,
        localTimestamp: localTimestamp,
        serverTimestamp: serverTimestamp,
      );

      expect(conflict.itemId, '123');
      expect(conflict.itemType, 'ODRequest');
      expect(conflict.localData, localData);
      expect(conflict.serverData, serverData);
      expect(conflict.localTimestamp, localTimestamp);
      expect(conflict.serverTimestamp, serverTimestamp);
    });

    test('should serialize to and from JSON', () {
      final localTimestamp = DateTime.now().subtract(const Duration(hours: 1));
      final serverTimestamp = DateTime.now();
      
      final conflict = SyncConflict(
        itemId: '456',
        itemType: 'User',
        localData: const {'email': 'local@example.com'},
        serverData: const {'email': 'server@example.com'},
        localTimestamp: localTimestamp,
        serverTimestamp: serverTimestamp,
      );

      final json = conflict.toJson();
      final deserialized = SyncConflict.fromJson(json);

      expect(deserialized.itemId, conflict.itemId);
      expect(deserialized.itemType, conflict.itemType);
      expect(deserialized.localData, conflict.localData);
      expect(deserialized.serverData, conflict.serverData);
      expect(deserialized.localTimestamp, conflict.localTimestamp);
      expect(deserialized.serverTimestamp, conflict.serverTimestamp);
    });
  });

  group('ConflictResolution', () {
    test('should create conflict resolution with required fields', () {
      const resolution = ConflictResolution(
        conflictId: '123',
        resolution: 'use_server',
      );

      expect(resolution.conflictId, '123');
      expect(resolution.resolution, 'use_server');
      expect(resolution.mergedData, isNull);
    });

    test('should create conflict resolution with merged data', () {
      const mergedData = {'name': 'Merged Name', 'version': 3};
      const resolution = ConflictResolution(
        conflictId: '456',
        resolution: 'merge',
        mergedData: mergedData,
      );

      expect(resolution.conflictId, '456');
      expect(resolution.resolution, 'merge');
      expect(resolution.mergedData, mergedData);
    });

    test('should serialize to and from JSON', () {
      const resolution = ConflictResolution(
        conflictId: '789',
        resolution: 'use_local',
        mergedData: {'status': 'resolved'},
      );

      final json = resolution.toJson();
      final deserialized = ConflictResolution.fromJson(json);

      expect(deserialized.conflictId, resolution.conflictId);
      expect(deserialized.resolution, resolution.resolution);
      expect(deserialized.mergedData, resolution.mergedData);
    });
  });

  group('SyncQueueItem', () {
    test('should create sync queue item with required fields', () {
      final queuedAt = DateTime.now();
      const data = {'field': 'value'};
      
      final item = SyncQueueItem(
        id: 'queue_123',
        itemId: 'item_456',
        itemType: 'ODRequest',
        operation: 'create',
        data: data,
        queuedAt: queuedAt,
      );

      expect(item.id, 'queue_123');
      expect(item.itemId, 'item_456');
      expect(item.itemType, 'ODRequest');
      expect(item.operation, 'create');
      expect(item.data, data);
      expect(item.queuedAt, queuedAt);
      expect(item.retryCount, 0);
      expect(item.lastRetryAt, isNull);
      expect(item.status, SyncStatus.pending);
      expect(item.errorMessage, isNull);
    });

    test('should create sync queue item with all fields', () {
      final queuedAt = DateTime.now().subtract(const Duration(minutes: 10));
      final lastRetryAt = DateTime.now().subtract(const Duration(minutes: 5));
      const data = {'name': 'Test Item'};
      
      final item = SyncQueueItem(
        id: 'queue_789',
        itemId: 'item_101',
        itemType: 'User',
        operation: 'update',
        data: data,
        queuedAt: queuedAt,
        retryCount: 2,
        lastRetryAt: lastRetryAt,
        status: SyncStatus.failed,
        errorMessage: 'Network timeout',
      );

      expect(item.id, 'queue_789');
      expect(item.itemId, 'item_101');
      expect(item.itemType, 'User');
      expect(item.operation, 'update');
      expect(item.data, data);
      expect(item.queuedAt, queuedAt);
      expect(item.retryCount, 2);
      expect(item.lastRetryAt, lastRetryAt);
      expect(item.status, SyncStatus.failed);
      expect(item.errorMessage, 'Network timeout');
    });

    test('should create copy with updated fields', () {
      final original = SyncQueueItem(
        id: 'queue_123',
        itemId: 'item_456',
        itemType: 'ODRequest',
        operation: 'create',
        data: const {'field': 'value'},
        queuedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        retryCount: 1,
        status: SyncStatus.inProgress,
        errorMessage: 'Retry attempt',
      );

      expect(updated.id, 'queue_123');
      expect(updated.itemId, 'item_456');
      expect(updated.itemType, 'ODRequest');
      expect(updated.operation, 'create');
      expect(updated.retryCount, 1);
      expect(updated.status, SyncStatus.inProgress);
      expect(updated.errorMessage, 'Retry attempt');
    });

    test('should serialize to and from JSON', () {
      final queuedAt = DateTime.now();
      final lastRetryAt = DateTime.now().add(const Duration(minutes: 5));
      
      final item = SyncQueueItem(
        id: 'queue_test',
        itemId: 'item_test',
        itemType: 'TestType',
        operation: 'delete',
        data: const {'deleted': true},
        queuedAt: queuedAt,
        retryCount: 3,
        lastRetryAt: lastRetryAt,
        status: SyncStatus.completed,
        errorMessage: 'No error',
      );

      final json = item.toJson();
      final deserialized = SyncQueueItem.fromJson(json);

      expect(deserialized.id, item.id);
      expect(deserialized.itemId, item.itemId);
      expect(deserialized.itemType, item.itemType);
      expect(deserialized.operation, item.operation);
      expect(deserialized.data, item.data);
      expect(deserialized.queuedAt, item.queuedAt);
      expect(deserialized.retryCount, item.retryCount);
      expect(deserialized.lastRetryAt, item.lastRetryAt);
      expect(deserialized.status, item.status);
      expect(deserialized.errorMessage, item.errorMessage);
    });
  });

  group('CacheMetadata', () {
    test('should create cache metadata with required fields', () {
      final createdAt = DateTime.now().subtract(const Duration(hours: 1));
      final lastAccessedAt = DateTime.now();
      
      final metadata = CacheMetadata(
        key: 'cache_key_123',
        createdAt: createdAt,
        lastAccessedAt: lastAccessedAt,
      );

      expect(metadata.key, 'cache_key_123');
      expect(metadata.createdAt, createdAt);
      expect(metadata.lastAccessedAt, lastAccessedAt);
      expect(metadata.expiresAt, isNull);
      expect(metadata.accessCount, 1);
      expect(metadata.sizeBytes, 0);
      expect(metadata.etag, isNull);
      expect(metadata.metadata, isNull);
    });

    test('should create cache metadata with all fields', () {
      final createdAt = DateTime.now().subtract(const Duration(hours: 2));
      final lastAccessedAt = DateTime.now().subtract(const Duration(minutes: 30));
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      const customMetadata = {'type': 'image', 'compressed': true};
      
      final metadata = CacheMetadata(
        key: 'image_cache_456',
        createdAt: createdAt,
        lastAccessedAt: lastAccessedAt,
        expiresAt: expiresAt,
        accessCount: 5,
        sizeBytes: 1024,
        etag: 'etag_123',
        metadata: customMetadata,
      );

      expect(metadata.key, 'image_cache_456');
      expect(metadata.createdAt, createdAt);
      expect(metadata.lastAccessedAt, lastAccessedAt);
      expect(metadata.expiresAt, expiresAt);
      expect(metadata.accessCount, 5);
      expect(metadata.sizeBytes, 1024);
      expect(metadata.etag, 'etag_123');
      expect(metadata.metadata, customMetadata);
    });

    test('should create copy with updated fields', () {
      final original = CacheMetadata(
        key: 'test_key',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        lastAccessedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      final updated = original.copyWith(
        accessCount: 3,
        sizeBytes: 512,
        etag: 'new_etag',
      );

      expect(updated.key, 'test_key');
      expect(updated.accessCount, 3);
      expect(updated.sizeBytes, 512);
      expect(updated.etag, 'new_etag');
      expect(updated.createdAt, original.createdAt);
      expect(updated.lastAccessedAt, original.lastAccessedAt);
    });

    test('should serialize to and from JSON', () {
      final createdAt = DateTime.now().subtract(const Duration(days: 1));
      final lastAccessedAt = DateTime.now();
      final expiresAt = DateTime.now().add(const Duration(hours: 12));
      
      final metadata = CacheMetadata(
        key: 'json_test_key',
        createdAt: createdAt,
        lastAccessedAt: lastAccessedAt,
        expiresAt: expiresAt,
        accessCount: 10,
        sizeBytes: 2048,
        etag: 'json_etag',
        metadata: const {'format': 'json'},
      );

      final json = metadata.toJson();
      final deserialized = CacheMetadata.fromJson(json);

      expect(deserialized.key, metadata.key);
      expect(deserialized.createdAt, metadata.createdAt);
      expect(deserialized.lastAccessedAt, metadata.lastAccessedAt);
      expect(deserialized.expiresAt, metadata.expiresAt);
      expect(deserialized.accessCount, metadata.accessCount);
      expect(deserialized.sizeBytes, metadata.sizeBytes);
      expect(deserialized.etag, metadata.etag);
      expect(deserialized.metadata, metadata.metadata);
    });

    group('isExpired', () {
      test('should return false when expiresAt is null', () {
        final metadata = CacheMetadata(
          key: 'test_key',
          createdAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
        );

        expect(metadata.isExpired, false);
      });

      test('should return false when not expired', () {
        final metadata = CacheMetadata(
          key: 'test_key',
          createdAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(metadata.isExpired, false);
      });

      test('should return true when expired', () {
        final metadata = CacheMetadata(
          key: 'test_key',
          createdAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(metadata.isExpired, true);
      });
    });

    group('priority', () {
      test('should calculate priority based on access patterns', () {
        final now = DateTime.now();
        final metadata = CacheMetadata(
          key: 'test_key',
          createdAt: now.subtract(const Duration(hours: 2)),
          lastAccessedAt: now.subtract(const Duration(hours: 1)),
          accessCount: 10,
        );

        final priority = metadata.priority;
        expect(priority, isA<int>());
        expect(priority, greaterThan(0));
      });

      test('should handle zero age gracefully', () {
        final now = DateTime.now();
        final metadata = CacheMetadata(
          key: 'test_key',
          createdAt: now,
          lastAccessedAt: now,
          accessCount: 5,
        );

        final priority = metadata.priority;
        expect(priority, isA<int>());
        expect(priority, greaterThanOrEqualTo(0));
      });
    });
  });

  group('SyncStatistics', () {
    test('should create sync statistics with all fields', () {
      final lastSyncTime = DateTime.now();
      const averageSyncDuration = Duration(seconds: 45);
      const syncsByType = {'ODRequest': 10, 'User': 5};
      
      final statistics = SyncStatistics(
        totalItemsSynced: 15,
        itemsSucceeded: 12,
        itemsFailed: 3,
        conflictsResolved: 2,
        lastSyncTime: lastSyncTime,
        averageSyncDuration: averageSyncDuration,
        syncsByType: syncsByType,
      );

      expect(statistics.totalItemsSynced, 15);
      expect(statistics.itemsSucceeded, 12);
      expect(statistics.itemsFailed, 3);
      expect(statistics.conflictsResolved, 2);
      expect(statistics.lastSyncTime, lastSyncTime);
      expect(statistics.averageSyncDuration, averageSyncDuration);
      expect(statistics.syncsByType, syncsByType);
    });

    test('should serialize to and from JSON', () {
      final lastSyncTime = DateTime.now();
      
      final statistics = SyncStatistics(
        totalItemsSynced: 20,
        itemsSucceeded: 18,
        itemsFailed: 2,
        conflictsResolved: 1,
        lastSyncTime: lastSyncTime,
        averageSyncDuration: const Duration(minutes: 1),
        syncsByType: const {'ODRequest': 15, 'User': 5},
      );

      final json = statistics.toJson();
      final deserialized = SyncStatistics.fromJson(json);

      expect(deserialized.totalItemsSynced, statistics.totalItemsSynced);
      expect(deserialized.itemsSucceeded, statistics.itemsSucceeded);
      expect(deserialized.itemsFailed, statistics.itemsFailed);
      expect(deserialized.conflictsResolved, statistics.conflictsResolved);
      expect(deserialized.lastSyncTime, statistics.lastSyncTime);
      expect(deserialized.averageSyncDuration, statistics.averageSyncDuration);
      expect(deserialized.syncsByType, statistics.syncsByType);
    });

    group('successRate', () {
      test('should calculate success rate correctly', () {
        final statistics = SyncStatistics(
          totalItemsSynced: 100,
          itemsSucceeded: 80,
          itemsFailed: 20,
          conflictsResolved: 5,
          lastSyncTime: DateTime.now(),
          averageSyncDuration: const Duration(seconds: 30),
          syncsByType: const {'ODRequest': 100},
        );

        expect(statistics.successRate, 0.8);
      });

      test('should return 0 when no items synced', () {
        final statistics = SyncStatistics(
          totalItemsSynced: 0,
          itemsSucceeded: 0,
          itemsFailed: 0,
          conflictsResolved: 0,
          lastSyncTime: DateTime.now(),
          averageSyncDuration: Duration.zero,
          syncsByType: const <String, int>{},
        );

        expect(statistics.successRate, 0.0);
      });
    });
  });

  group('SyncStatus', () {
    test('should have all expected values', () {
      expect(SyncStatus.values, contains(SyncStatus.pending));
      expect(SyncStatus.values, contains(SyncStatus.inProgress));
      expect(SyncStatus.values, contains(SyncStatus.completed));
      expect(SyncStatus.values, contains(SyncStatus.failed));
      expect(SyncStatus.values, contains(SyncStatus.conflict));
    });
  });
}