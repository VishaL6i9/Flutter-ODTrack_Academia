import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/models/sync_models.dart';

/// Enhanced storage manager with intelligent cache management and sync queue
class EnhancedStorageManager {
  static const String _syncQueueBox = 'sync_queue_box';
  static const String _cacheMetadataBox = 'cache_metadata_box';
  static const String _conflictResolutionBox = 'conflict_resolution_box';
  static const String _cacheDataBox = 'cache_data_box';
  
  // Cache configuration
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxCacheItems = 1000;
  static const Duration _defaultTTL = Duration(hours: 24);
  static const Duration _cleanupInterval = Duration(minutes: 30);
  
  Timer? _cleanupTimer;
  
  /// Initialize enhanced storage
  Future<void> initialize() async {
    await _openBoxes();
    _startCleanupTimer();
  }
  
  /// Open all required Hive boxes
  Future<void> _openBoxes() async {
    final futures = <Future<void>>[];
    
    // Open all required boxes
    if (!Hive.isBoxOpen(_syncQueueBox)) {
      futures.add(Hive.openLazyBox<SyncQueueItem>(_syncQueueBox));
    }
    if (!Hive.isBoxOpen(_cacheMetadataBox)) {
      futures.add(Hive.openBox<CacheMetadata>(_cacheMetadataBox));
    }
    if (!Hive.isBoxOpen(_conflictResolutionBox)) {
      futures.add(Hive.openBox<SyncConflict>(_conflictResolutionBox));
    }
    if (!Hive.isBoxOpen(_cacheDataBox)) {
      futures.add(Hive.openBox<String>(_cacheDataBox));
    }
    
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }
  
  /// Start automatic cache cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) => cleanupExpiredCache());
  }
  
  /// Stop cleanup timer
  void dispose() {
    _cleanupTimer?.cancel();
  }
  
  // SYNC QUEUE OPERATIONS
  
  /// Add item to sync queue
  Future<void> addToSyncQueue(SyncQueueItem item) async {
    final box = Hive.lazyBox<SyncQueueItem>(_syncQueueBox);
    await box.put(item.id, item);
  }

  /// Get sync queue item by ID
  Future<SyncQueueItem?> getSyncQueueItem(String queueId) async {
    final box = Hive.lazyBox<SyncQueueItem>(_syncQueueBox);
    return await box.get(queueId);
  }
  
  /// Get all pending sync queue items
  Future<List<SyncQueueItem>> getPendingSyncItems() async {
    final box = Hive.lazyBox<SyncQueueItem>(_syncQueueBox);
    final items = await Future.wait(box.keys.map((k) => box.get(k)));
    return items
        .where((item) => item != null && (item.status == SyncStatus.pending || item.status == SyncStatus.failed))
        .cast<SyncQueueItem>()
        .toList()
      ..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
  }
  
  /// Update sync queue item status
  Future<void> updateSyncQueueItem(String id, SyncStatus status, {String? errorMessage}) async {
    final box = Hive.lazyBox<SyncQueueItem>(_syncQueueBox);
    final item = await box.get(id);
    if (item != null) {
      final updatedItem = item.copyWith(
        status: status,
        errorMessage: errorMessage,
        lastRetryAt: status == SyncStatus.failed ? DateTime.now() : item.lastRetryAt,
        retryCount: status == SyncStatus.failed ? item.retryCount + 1 : item.retryCount,
      );
      await box.put(id, updatedItem);
    }
  }
  
  /// Remove completed sync queue items
  Future<void> removeCompletedSyncItems() async {
    final box = Hive.lazyBox<SyncQueueItem>(_syncQueueBox);
    final items = await Future.wait(box.keys.map((k) => box.get(k)));
    final completedKeys = items
        .where((item) => item != null && item.status == SyncStatus.completed)
        .map((item) => item!.id)
        .toList();
    
    for (final key in completedKeys) {
      await box.delete(key);
    }
  }
  
  /// Get sync queue statistics
  Future<Map<String, int>> getSyncQueueStats() async {
    final box = Hive.lazyBox<SyncQueueItem>(_syncQueueBox);
    final items = await Future.wait(box.keys.map((k) => box.get(k)));
    final validItems = items.where((i) => i != null).cast<SyncQueueItem>().toList();
    
    return {
      'total': validItems.length,
      'pending': validItems.where((item) => item.status == SyncStatus.pending).length,
      'in_progress': validItems.where((item) => item.status == SyncStatus.inProgress).length,
      'completed': validItems.where((item) => item.status == SyncStatus.completed).length,
      'failed': validItems.where((item) => item.status == SyncStatus.failed).length,
      'conflict': validItems.where((item) => item.status == SyncStatus.conflict).length,
    };
  }
  
  // CACHE MANAGEMENT OPERATIONS
  
  /// Store data in cache with metadata
  Future<void> cacheData(String key, Map<String, dynamic> data, {Duration? ttl}) async {
    final cacheBox = Hive.box<String>(_cacheDataBox);
    final metadataBox = Hive.box<CacheMetadata>(_cacheMetadataBox);
    
    final jsonData = jsonEncode(data);
    final sizeBytes = utf8.encode(jsonData).length;
    final expiresAt = ttl != null ? DateTime.now().add(ttl) : DateTime.now().add(_defaultTTL);
    
    // Check if we need to cleanup before adding new data
    await _ensureCacheCapacity(sizeBytes);
    
    final metadata = CacheMetadata(
      key: key,
      createdAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      expiresAt: expiresAt,
      sizeBytes: sizeBytes,
    );
    
    await Future.wait([
      cacheBox.put(key, jsonData),
      metadataBox.put(key, metadata),
    ]);
  }
  
  /// Retrieve data from cache
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    final cacheBox = Hive.box<String>(_cacheDataBox);
    final metadataBox = Hive.box<CacheMetadata>(_cacheMetadataBox);
    
    final metadata = metadataBox.get(key);
    if (metadata == null) return null;
    
    // Check if expired
    if (metadata.isExpired) {
      await _removeCacheItem(key);
      return null;
    }
    
    final jsonData = cacheBox.get(key);
    if (jsonData == null) return null;
    
    // Update access metadata
    final updatedMetadata = metadata.copyWith(
      lastAccessedAt: DateTime.now(),
      accessCount: metadata.accessCount + 1,
    );
    await metadataBox.put(key, updatedMetadata);
    
    try {
      return jsonDecode(jsonData) as Map<String, dynamic>;
    } catch (e) {
      // Invalid JSON, remove from cache
      await _removeCacheItem(key);
      return null;
    }
  }
  
  /// Check if data exists in cache and is not expired
  bool isCached(String key) {
    final metadataBox = Hive.box<CacheMetadata>(_cacheMetadataBox);
    final metadata = metadataBox.get(key);
    return metadata != null && !metadata.isExpired;
  }
  
  /// Remove specific cache item
  Future<void> removeCacheItem(String key) async {
    await _removeCacheItem(key);
  }
  
  /// Internal method to remove cache item
  Future<void> _removeCacheItem(String key) async {
    final cacheBox = Hive.box<String>(_cacheDataBox);
    final metadataBox = Hive.box<CacheMetadata>(_cacheMetadataBox);
    
    await Future.wait([
      cacheBox.delete(key),
      metadataBox.delete(key),
    ]);
  }
  
  /// Clean up expired cache items
  Future<int> cleanupExpiredCache() async {
    final metadataBox = Hive.box<CacheMetadata>(_cacheMetadataBox);
    final expiredKeys = <String>[];
    
    for (final entry in metadataBox.toMap().entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key as String);
      }
    }
    
    for (final key in expiredKeys) {
      await _removeCacheItem(key);
    }
    
    return expiredKeys.length;
  }
  
  /// Ensure cache doesn't exceed capacity limits
  Future<void> _ensureCacheCapacity(int newItemSize) async {
    final metadataBox = Hive.box<CacheMetadata>(_cacheMetadataBox);
    final currentItems = metadataBox.values.toList();
    
    // Calculate current cache size
    final currentSize = currentItems.fold<int>(0, (sum, metadata) => sum + metadata.sizeBytes);
    
    // Check if we need to free up space
    if (currentItems.length >= _maxCacheItems || 
        (currentSize + newItemSize) > _maxCacheSize) {
      await _performPriorityBasedCleanup(newItemSize);
    }
  }
  
  /// Perform priority-based cache cleanup
  Future<void> _performPriorityBasedCleanup(int requiredSpace) async {
    final metadataBox = Hive.box<CacheMetadata>(_cacheMetadataBox);
    final items = metadataBox.values.toList();
    
    // Sort by priority (lowest first) and age (oldest first)
    items.sort((a, b) {
      final priorityComparison = a.priority.compareTo(b.priority);
      if (priorityComparison != 0) return priorityComparison;
      return a.createdAt.compareTo(b.createdAt);
    });
    
    int freedSpace = 0;
    int itemsRemoved = 0;
    
    for (final metadata in items) {
      if (freedSpace >= requiredSpace && itemsRemoved >= 10) break;
      
      await _removeCacheItem(metadata.key);
      freedSpace += metadata.sizeBytes;
      itemsRemoved++;
    }
  }
  
  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final metadataBox = Hive.box<CacheMetadata>(_cacheMetadataBox);
    final items = metadataBox.values.toList();
    
    final totalSize = items.fold<int>(0, (sum, metadata) => sum + metadata.sizeBytes);
    final expiredCount = items.where((metadata) => metadata.isExpired).length;
    
    return {
      'totalItems': items.length,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'expiredItems': expiredCount,
      'averageItemSize': items.isNotEmpty ? (totalSize / items.length).round() : 0,
      'oldestItem': items.isNotEmpty 
          ? items.map((m) => m.createdAt).reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String()
          : null,
      'newestItem': items.isNotEmpty 
          ? items.map((m) => m.createdAt).reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
          : null,
    };
  }
  
  // CONFLICT RESOLUTION OPERATIONS
  
  /// Store sync conflict
  Future<void> storeSyncConflict(SyncConflict conflict) async {
    final box = Hive.box<SyncConflict>(_conflictResolutionBox);
    await box.put(conflict.itemId, conflict);
  }
  
  /// Get all unresolved conflicts
  List<SyncConflict> getUnresolvedConflicts() {
    final box = Hive.box<SyncConflict>(_conflictResolutionBox);
    return box.values.toList();
  }
  
  /// Remove resolved conflict
  Future<void> removeResolvedConflict(String itemId) async {
    final box = Hive.box<SyncConflict>(_conflictResolutionBox);
    await box.delete(itemId);
  }
  
  /// Clear all conflicts
  Future<void> clearAllConflicts() async {
    final box = Hive.box<SyncConflict>(_conflictResolutionBox);
    await box.clear();
  }
  
  // UTILITY OPERATIONS
  
  /// Clear all enhanced storage data
  Future<void> clearAllData() async {
    // Use existing boxes if open, otherwise open them
    final syncQueueBox = Hive.isBoxOpen(_syncQueueBox) 
        ? Hive.lazyBox<SyncQueueItem>(_syncQueueBox)
        : await Hive.openLazyBox<SyncQueueItem>(_syncQueueBox);
    
    final cacheMetadataBox = Hive.isBoxOpen(_cacheMetadataBox) 
        ? Hive.box<CacheMetadata>(_cacheMetadataBox)
        : await Hive.openBox<CacheMetadata>(_cacheMetadataBox);
    
    final conflictResolutionBox = Hive.isBoxOpen(_conflictResolutionBox) 
        ? Hive.box<SyncConflict>(_conflictResolutionBox)
        : await Hive.openBox<SyncConflict>(_conflictResolutionBox);
    
    final cacheDataBox = Hive.isBoxOpen(_cacheDataBox) 
        ? Hive.box<String>(_cacheDataBox)
        : await Hive.openBox<String>(_cacheDataBox);

    await Future.wait([
      syncQueueBox.clear(),
      cacheMetadataBox.clear(),
      conflictResolutionBox.clear(),
      cacheDataBox.clear(),
    ]);
  }
  
  /// Get overall storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final syncStats = await getSyncQueueStats();
    final cacheStats = await getCacheStats();
    final conflictBox = Hive.box<SyncConflict>(_conflictResolutionBox);
    
    return {
      'syncQueue': syncStats,
      'cache': cacheStats,
      'conflicts': conflictBox.length,
      'totalBoxes': 4,
    };
  }
  
  /// Optimize storage by compacting boxes
  Future<void> optimizeStorage() async {
    // Use existing boxes if open, otherwise open them
    final syncQueueBox = Hive.isBoxOpen(_syncQueueBox) 
        ? Hive.lazyBox<SyncQueueItem>(_syncQueueBox)
        : await Hive.openLazyBox<SyncQueueItem>(_syncQueueBox);
    
    final cacheMetadataBox = Hive.isBoxOpen(_cacheMetadataBox) 
        ? Hive.box<CacheMetadata>(_cacheMetadataBox)
        : await Hive.openBox<CacheMetadata>(_cacheMetadataBox);
    
    final conflictResolutionBox = Hive.isBoxOpen(_conflictResolutionBox) 
        ? Hive.box<SyncConflict>(_conflictResolutionBox)
        : await Hive.openBox<SyncConflict>(_conflictResolutionBox);
    
    final cacheDataBox = Hive.isBoxOpen(_cacheDataBox) 
        ? Hive.box<String>(_cacheDataBox)
        : await Hive.openBox<String>(_cacheDataBox);

    await Future.wait([
      syncQueueBox.compact(),
      cacheMetadataBox.compact(),
      conflictResolutionBox.compact(),
      cacheDataBox.compact(),
    ]);
  }
}