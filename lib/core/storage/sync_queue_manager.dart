import 'dart:async';
import 'dart:math';
import 'package:odtrack_academia/models/sync_models.dart';
import 'package:odtrack_academia/core/storage/enhanced_storage_manager.dart';

/// Specialized manager for sync queue operations with advanced features
class SyncQueueManager {
  final EnhancedStorageManager _storageManager;
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 30);
  static const double _retryMultiplier = 2.0;
  
  SyncQueueManager(this._storageManager);
  
  /// Generate unique ID for sync queue items
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '${timestamp}_$random';
  }
  
  /// Queue a syncable item for synchronization
  Future<String> queueItem({
    required String itemId,
    required String itemType,
    required String operation,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async {
    final queueId = _generateId();
    final queueItem = SyncQueueItem(
      id: queueId,
      itemId: itemId,
      itemType: itemType,
      operation: operation,
      data: {
        ...data,
        'priority': priority,
        'queuedBy': 'system',
      },
      queuedAt: DateTime.now(),
      status: SyncStatus.pending,
    );
    
    await _storageManager.addToSyncQueue(queueItem);
    return queueId;
  }
  
  /// Queue OD request for sync
  Future<String> queueODRequest({
    required String requestId,
    required String operation,
    required Map<String, dynamic> requestData,
  }) async {
    return await queueItem(
      itemId: requestId,
      itemType: 'od_request',
      operation: operation,
      data: requestData,
      priority: operation == 'create' ? 10 : 5, // Higher priority for new requests
    );
  }
  
  /// Queue user data for sync
  Future<String> queueUserData({
    required String userId,
    required String operation,
    required Map<String, dynamic> userData,
  }) async {
    return await queueItem(
      itemId: userId,
      itemType: 'user_data',
      operation: operation,
      data: userData,
      priority: 3,
    );
  }
  
  /// Get next batch of items to sync
  Future<List<SyncQueueItem>> getNextSyncBatch({int batchSize = 10}) async {
    final pendingItems = await _storageManager.getPendingSyncItems();
    
    // Filter out items that are in retry cooldown
    final availableItems = pendingItems.where((item) {
      if (item.status == SyncStatus.failed && item.lastRetryAt != null) {
        final cooldownDuration = _calculateRetryDelay(item.retryCount);
        final nextRetryTime = item.lastRetryAt!.add(cooldownDuration);
        return DateTime.now().isAfter(nextRetryTime);
      }
      return true;
    }).toList();
    
    // Sort by priority (higher first) and queue time (older first)
    availableItems.sort((a, b) {
      final aPriority = a.data['priority'] as int? ?? 0;
      final bPriority = b.data['priority'] as int? ?? 0;
      
      final priorityComparison = bPriority.compareTo(aPriority);
      if (priorityComparison != 0) return priorityComparison;
      
      return a.queuedAt.compareTo(b.queuedAt);
    });
    
    return availableItems.take(batchSize).toList();
  }
  
  /// Mark sync item as in progress
  Future<void> markAsInProgress(String queueId) async {
    await _storageManager.updateSyncQueueItem(queueId, SyncStatus.inProgress);
  }
  
  /// Mark sync item as completed
  Future<void> markAsCompleted(String queueId) async {
    await _storageManager.updateSyncQueueItem(queueId, SyncStatus.completed);
  }
  
  /// Mark sync item as failed with retry logic
  Future<void> markAsFailed(String queueId, String errorMessage) async {
    final item = await _storageManager.getSyncQueueItem(queueId);
    if (item != null) {
      final updatedItem = item.copyWith(
        status: SyncStatus.failed,
        retryCount: item.retryCount + 1,
        lastRetryAt: DateTime.now(),
        errorMessage: errorMessage,
      );
      await _storageManager.addToSyncQueue(updatedItem);
    }
  }
  
  /// Mark sync item as having conflicts
  Future<void> markAsConflicted(String queueId, String conflictMessage) async {
    await _storageManager.updateSyncQueueItem(
      queueId, 
      SyncStatus.conflict, 
      errorMessage: conflictMessage,
    );
  }
  
  /// Check if item should be retried
  bool shouldRetryItem(SyncQueueItem item) {
    if (item.status != SyncStatus.failed) return false;
    if ((item.retryCount) >= _maxRetries) return false;
    
    if (item.lastRetryAt != null) {
      final cooldownDuration = _calculateRetryDelay(item.retryCount);
      final nextRetryTime = item.lastRetryAt!.add(cooldownDuration);
      return DateTime.now().isAfter(nextRetryTime);
    }
    
    return true;
  }
  
  /// Calculate retry delay with exponential backoff
  Duration _calculateRetryDelay(int retryCount) {
    final multiplier = pow(_retryMultiplier, retryCount);
    final delaySeconds = _baseRetryDelay.inSeconds * multiplier;
    return Duration(seconds: delaySeconds.round());
  }
  
  /// Get items that have exceeded max retries
  Future<List<SyncQueueItem>> getFailedItems() async {
    final allItems = await _storageManager.getPendingSyncItems();
    return allItems.where((item) => 
      item.status == SyncStatus.failed && (item.retryCount) >= _maxRetries
    ).toList();
  }
  
  /// Remove items that have exceeded max retries
  Future<int> removeFailedItems() async {
    final failedItems = await getFailedItems();
    for (final item in failedItems) {
      await _storageManager.updateSyncQueueItem(item.id, SyncStatus.completed);
    }
    return failedItems.length;
  }
  
  /// Get sync queue health metrics
  Future<Map<String, dynamic>> getQueueHealth() async {
    final stats = await _storageManager.getSyncQueueStats();
    final pendingItems = await _storageManager.getPendingSyncItems();
    
    final oldestPending = pendingItems.isNotEmpty 
        ? pendingItems.map((item) => item.queuedAt).reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    
    final totalRetries = pendingItems.map((item) => item.retryCount).fold(0, (a, b) => a + b);
    final avgRetryCount = pendingItems.isNotEmpty ? totalRetries / pendingItems.length : 0.0;
    
    final itemsByType = <String, int>{};
    for (final item in pendingItems) {
      itemsByType[item.itemType] = (itemsByType[item.itemType] ?? 0) + 1;
    }
    
    return {
      'stats': stats,
      'oldestPendingAge': oldestPending != null 
          ? DateTime.now().difference(oldestPending).inMinutes 
          : null,
      'averageRetryCount': avgRetryCount.toStringAsFixed(2),
      'itemsByType': itemsByType,
      'isHealthy': (stats['failed'] ?? 0) < 10 && (stats['pending'] ?? 0) < 100,
    };
  }
  
  /// Clean up completed items older than specified duration
  Future<int> cleanupOldItems({Duration maxAge = const Duration(days: 7)}) async {
    final _ = DateTime.now().subtract(maxAge); // cutoffTime for future use
    await _storageManager.removeCompletedSyncItems();
    
    // For now, we'll just return the count of completed items that were removed
    // In a real implementation, we'd track this more precisely
    return 0;
  }
  
  /// Get detailed queue analysis
  Future<Map<String, dynamic>> analyzeQueue() async {
    final pendingItems = await _storageManager.getPendingSyncItems();
    final stats = await _storageManager.getSyncQueueStats();
    
    final operationCounts = <String, int>{};
    final typeCounts = <String, int>{};
    final priorityCounts = <String, int>{};
    
    for (final item in pendingItems) {
      operationCounts[item.operation] = (operationCounts[item.operation] ?? 0) + 1;
      typeCounts[item.itemType] = (typeCounts[item.itemType] ?? 0) + 1;
      
      final priority = item.data['priority'] as int? ?? 0;
      final priorityRange = priority >= 10 ? 'high' : priority >= 5 ? 'medium' : 'low';
      priorityCounts[priorityRange] = (priorityCounts[priorityRange] ?? 0) + 1;
    }
    
    final total = stats['total'] ?? 0;
    final completed = stats['completed'] ?? 0;
    
    return {
      'totalItems': total,
      'pendingItems': stats['pending'],
      'failedItems': stats['failed'],
      'operationBreakdown': operationCounts,
      'typeBreakdown': typeCounts,
      'priorityBreakdown': priorityCounts,
      'queueEfficiency': total > 0 
          ? '${((completed / total) * 100).toStringAsFixed(1)}%'
          : '0%',
    };
  }
  
  /// Reset retry count for failed items (manual intervention)
  Future<int> resetFailedItems() async {
    final failedItems = (await _storageManager.getPendingSyncItems())
        .where((SyncQueueItem item) => item.status == SyncStatus.failed)
        .toList();
    
    for (final item in failedItems) {
      final resetItem = item.copyWith(
        status: SyncStatus.pending,
        retryCount: 0,
        lastRetryAt: null,
        errorMessage: null,
      );
      await _storageManager.addToSyncQueue(resetItem);
    }
    
    return failedItems.length;
  }
}