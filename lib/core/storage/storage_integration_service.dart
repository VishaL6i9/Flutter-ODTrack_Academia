import 'dart:async';
import 'package:odtrack_academia/core/storage/enhanced_storage_manager.dart';
import 'package:odtrack_academia/core/storage/sync_queue_manager.dart';
import 'package:odtrack_academia/core/storage/intelligent_cache_manager.dart';
import 'package:odtrack_academia/models/sync_models.dart';

/// Production-ready service demonstrating enhanced storage architecture integration
class StorageIntegrationService {
  late final EnhancedStorageManager _storageManager;
  late final SyncQueueManager _syncQueueManager;
  late final IntelligentCacheManager _cacheManager;
  
  bool _isInitialized = false;
  
  /// Initialize all storage components
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _storageManager = EnhancedStorageManager();
    await _storageManager.initialize();
    
    _syncQueueManager = SyncQueueManager(_storageManager);
    _cacheManager = IntelligentCacheManager(_storageManager);
    
    _isInitialized = true;
  }
  
  /// Create and cache an OD request, then queue for sync
  Future<String> createODRequest(Map<String, dynamic> requestData) async {
    await _ensureInitialized();
    
    final requestId = requestData['id'] as String;
    
    // Cache for immediate access
    await _cacheManager.cacheODRequest(requestId, requestData);
    
    // Queue for sync when online
    final queueId = await _syncQueueManager.queueODRequest(
      requestId: requestId,
      operation: 'create',
      requestData: requestData,
    );
    
    return queueId;
  }
  
  /// Update user profile with caching and sync
  Future<void> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    await _ensureInitialized();
    
    // Cache with intelligent TTL
    await _cacheManager.cacheUserProfile(userId, profileData);
    
    // Queue for sync
    await _syncQueueManager.queueUserData(
      userId: userId,
      operation: 'update',
      userData: profileData,
    );
  }
  
  /// Get cached OD request
  Future<Map<String, dynamic>?> getODRequest(String requestId) async {
    await _ensureInitialized();
    return await _cacheManager.getCachedODRequest(requestId);
  }
  
  /// Get cached user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    await _ensureInitialized();
    return await _cacheManager.getCachedUserProfile(userId);
  }
  
  /// Cache analytics data
  Future<void> cacheAnalytics(String key, Map<String, dynamic> analyticsData) async {
    await _ensureInitialized();
    await _cacheManager.cacheAnalytics(key, analyticsData);
  }
  
  /// Get cached analytics
  Future<Map<String, dynamic>?> getAnalytics(String key) async {
    await _ensureInitialized();
    return await _cacheManager.getCachedAnalytics(key);
  }
  
  /// Get next batch of items to sync
  List<SyncQueueItem> getNextSyncBatch({int batchSize = 10}) {
    _ensureInitializedSync();
    return _syncQueueManager.getNextSyncBatch(batchSize: batchSize);
  }
  
  /// Mark sync item as completed
  Future<void> markSyncCompleted(String queueId) async {
    await _ensureInitialized();
    await _syncQueueManager.markAsCompleted(queueId);
  }
  
  /// Mark sync item as failed
  Future<void> markSyncFailed(String queueId, String errorMessage) async {
    await _ensureInitialized();
    await _syncQueueManager.markAsFailed(queueId, errorMessage);
  }
  
  /// Store sync conflict
  Future<void> storeSyncConflict(SyncConflict conflict) async {
    await _ensureInitialized();
    await _storageManager.storeSyncConflict(conflict);
  }
  
  /// Get unresolved conflicts
  List<SyncConflict> getUnresolvedConflicts() {
    _ensureInitializedSync();
    return _storageManager.getUnresolvedConflicts();
  }
  
  /// Resolve conflict
  Future<void> resolveConflict(String itemId) async {
    await _ensureInitialized();
    await _storageManager.removeResolvedConflict(itemId);
  }
  
  /// Get sync queue health
  Map<String, dynamic> getSyncQueueHealth() {
    _ensureInitializedSync();
    return _syncQueueManager.getQueueHealth();
  }
  
  /// Get cache performance metrics
  Map<String, dynamic> getCachePerformanceMetrics() {
    _ensureInitializedSync();
    return _cacheManager.getCachePerformanceMetrics();
  }
  
  /// Get cache health score
  int getCacheHealthScore() {
    _ensureInitializedSync();
    return _cacheManager.getCacheHealthScore();
  }
  
  /// Optimize cache
  Future<Map<String, int>> optimizeCache() async {
    await _ensureInitialized();
    return await _cacheManager.optimizeCache();
  }
  
  /// Preload critical data for user
  Future<void> preloadCriticalData(String userId) async {
    await _ensureInitialized();
    await _cacheManager.preloadCriticalData(userId);
  }
  
  /// Get overall storage statistics
  Map<String, dynamic> getStorageStatistics() {
    _ensureInitializedSync();
    return _storageManager.getStorageStats();
  }
  
  /// Analyze sync queue
  Map<String, dynamic> analyzeSyncQueue() {
    _ensureInitializedSync();
    return _syncQueueManager.analyzeQueue();
  }
  
  /// Clean up old completed sync items
  Future<int> cleanupOldSyncItems({Duration maxAge = const Duration(days: 7)}) async {
    await _ensureInitialized();
    return await _syncQueueManager.cleanupOldItems(maxAge: maxAge);
  }
  
  /// Schedule cache maintenance
  Future<void> scheduleCacheMaintenance() async {
    await _ensureInitialized();
    await _cacheManager.scheduleMaintenance();
  }
  
  /// Clear all storage data
  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _storageManager.clearAllData();
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    if (_isInitialized) {
      _storageManager.dispose();
      _isInitialized = false;
    }
  }
  
  /// Ensure service is initialized (async)
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// Ensure service is initialized (sync)
  void _ensureInitializedSync() {
    if (!_isInitialized) {
      throw StateError('StorageIntegrationService must be initialized before use');
    }
  }
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}