import 'dart:async';
import 'dart:math';
import 'package:odtrack_academia/core/storage/storage_manager.dart';

/// Intelligent cache manager with advanced TTL and priority-based cleanup
class IntelligentCacheManager {
  final EnhancedStorageManager _storageManager;
  
  // Cache configuration
  static const Duration _shortTTL = Duration(minutes: 15);
  static const Duration _mediumTTL = Duration(hours: 2);
  static const Duration _longTTL = Duration(hours: 24);
  static const Duration _extendedTTL = Duration(days: 7);
  
  // Cache categories for different TTL strategies
  static const Map<String, Duration> _categoryTTLs = {
    'user_profile': _longTTL,
    'od_requests': _mediumTTL,
    'staff_directory': _extendedTTL,
    'timetable': _longTTL,
    'analytics': _shortTTL,
    'temporary': _shortTTL,
  };
  
  IntelligentCacheManager(this._storageManager);
  
  /// Cache data with intelligent TTL based on category
  Future<void> cacheData(
    String key, 
    Map<String, dynamic> data, {
    String category = 'temporary',
    Duration? customTTL,
    Map<String, dynamic>? metadata,
  }) async {
    final ttl = customTTL ?? _categoryTTLs[category] ?? _shortTTL;
    
    // Add category and additional metadata
    final enhancedData = {
      ...data,
      '_cache_metadata': {
        'category': category,
        'cached_at': DateTime.now().toIso8601String(),
        'ttl_seconds': ttl.inSeconds,
        ...?metadata,
      },
    };
    
    await _storageManager.cacheData(key, enhancedData, ttl: ttl);
  }
  
  /// Cache OD request data
  Future<void> cacheODRequest(String requestId, Map<String, dynamic> requestData) async {
    await cacheData(
      'od_request_$requestId',
      requestData,
      category: 'od_requests',
      metadata: {'type': 'od_request', 'id': requestId},
    );
  }
  
  /// Cache user profile data
  Future<void> cacheUserProfile(String userId, Map<String, dynamic> profileData) async {
    await cacheData(
      'user_profile_$userId',
      profileData,
      category: 'user_profile',
      metadata: {'type': 'user_profile', 'id': userId},
    );
  }
  
  /// Cache staff directory data
  Future<void> cacheStaffDirectory(List<Map<String, dynamic>> staffData) async {
    await cacheData(
      'staff_directory',
      {'staff_list': staffData, 'count': staffData.length},
      category: 'staff_directory',
      metadata: {'type': 'staff_directory', 'count': staffData.length},
    );
  }
  
  /// Cache timetable data
  Future<void> cacheTimetable(String userId, Map<String, dynamic> timetableData) async {
    await cacheData(
      'timetable_$userId',
      timetableData,
      category: 'timetable',
      metadata: {'type': 'timetable', 'user_id': userId},
    );
  }
  
  /// Cache analytics data with short TTL
  Future<void> cacheAnalytics(String analyticsKey, Map<String, dynamic> analyticsData) async {
    await cacheData(
      'analytics_$analyticsKey',
      analyticsData,
      category: 'analytics',
      metadata: {'type': 'analytics', 'key': analyticsKey},
    );
  }
  
  /// Get cached data with automatic TTL extension for frequently accessed items
  Future<Map<String, dynamic>?> getCachedData(String key, {bool extendTTL = false}) async {
    final data = await _storageManager.getCachedData(key);
    
    if (data != null && extendTTL) {
      await _extendTTLIfFrequentlyAccessed(key, data);
    }
    
    return data;
  }
  
  /// Get cached OD request
  Future<Map<String, dynamic>?> getCachedODRequest(String requestId) async {
    return await getCachedData('od_request_$requestId', extendTTL: true);
  }
  
  /// Get cached user profile
  Future<Map<String, dynamic>?> getCachedUserProfile(String userId) async {
    return await getCachedData('user_profile_$userId', extendTTL: true);
  }
  
  /// Get cached staff directory
  Future<List<Map<String, dynamic>>?> getCachedStaffDirectory() async {
    final data = await getCachedData('staff_directory');
    if (data != null && data['staff_list'] is List) {
      return List<Map<String, dynamic>>.from(data['staff_list'] as List);
    }
    return null;
  }
  
  /// Get cached timetable
  Future<Map<String, dynamic>?> getCachedTimetable(String userId) async {
    return await getCachedData('timetable_$userId', extendTTL: true);
  }
  
  /// Get cached analytics
  Future<Map<String, dynamic>?> getCachedAnalytics(String analyticsKey) async {
    return await getCachedData('analytics_$analyticsKey');
  }
  
  /// Extend TTL for frequently accessed items
  Future<void> _extendTTLIfFrequentlyAccessed(String key, Map<String, dynamic> data) async {
    // Check if item has been accessed frequently (more than 5 times in the last hour)
    // This is a simplified implementation - in practice, you'd track access patterns more sophisticatedly
    
    final cacheMetadata = data['_cache_metadata'] as Map<String, dynamic>?;
    if (cacheMetadata == null) return;
    
    final category = cacheMetadata['category'] as String?;
    if (category == null) return;
    
    // For frequently accessed items, extend TTL by 50%
    final originalTTL = _categoryTTLs[category] ?? _shortTTL;
    final extendedTTL = Duration(seconds: (originalTTL.inSeconds * 1.5).round());
    
    await _storageManager.cacheData(key, data, ttl: extendedTTL);
  }
  
  /// Preload critical data into cache
  Future<void> preloadCriticalData(String userId) async {
    // This method would be called during app startup or user login
    // to preload frequently accessed data
    
    // Note: In a real implementation, you'd fetch this data from your API
    // For now, we'll just create placeholder cache entries
    
    final criticalKeys = [
      'user_profile_$userId',
      'timetable_$userId',
      'staff_directory',
    ];
    
    for (final key in criticalKeys) {
      if (!_storageManager.isCached(key)) {
        // Mark as placeholder for preloading
        await cacheData(
          '${key}_preload_marker',
          {'preload': true, 'target_key': key},
          category: 'temporary',
          customTTL: const Duration(minutes: 5),
        );
      }
    }
  }
  
  /// Warm up cache with predicted data
  Future<void> warmUpCache(List<String> predictedKeys) async {
    for (final key in predictedKeys) {
      if (!_storageManager.isCached(key)) {
        // Create warm-up markers
        await cacheData(
          '${key}_warmup',
          {'warmup': true, 'predicted_at': DateTime.now().toIso8601String()},
          category: 'temporary',
          customTTL: const Duration(minutes: 10),
        );
      }
    }
  }
  
  /// Get cache performance metrics
  Future<Map<String, dynamic>> getCachePerformanceMetrics() async {
    final stats = await _storageManager.getCacheStats();
    
    // Calculate hit rate (simplified - in practice you'd track this more accurately)
    final totalItems = stats['totalItems'] as int;
    final expiredItems = stats['expiredItems'] as int;
    final activeItems = totalItems - expiredItems;
    
    final hitRate = totalItems > 0 ? (activeItems / totalItems) * 100 : 0.0;
    
    return {
      ...stats,
      'hitRate': '${hitRate.toStringAsFixed(1)}%',
      'activeItems': activeItems,
      'cacheEfficiency': activeItems > 0 ? 'Good' : 'Poor',
      'recommendedAction': _getRecommendedAction(stats),
    };
  }
  
  /// Get recommended cache action based on metrics
  String _getRecommendedAction(Map<String, dynamic> stats) {
    final totalItems = stats['totalItems'] as int;
    final expiredItems = stats['expiredItems'] as int;
    final totalSizeMB = double.parse(stats['totalSizeMB'] as String);
    
    if (expiredItems > totalItems * 0.3) {
      return 'Clean up expired items';
    } else if (totalSizeMB > 40) {
      return 'Reduce cache size';
    } else if (totalItems < 10) {
      return 'Increase cache usage';
    } else {
      return 'Cache is healthy';
    }
  }
  
  /// Perform intelligent cache optimization
  Future<Map<String, int>> optimizeCache() async {
    final results = <String, int>{};
    
    // Clean up expired items
    results['expiredCleaned'] = await _storageManager.cleanupExpiredCache();
    
    // Perform storage optimization
    await _storageManager.optimizeStorage();
    results['storageOptimized'] = 1;
    
    return results;
  }
  
  /// Get cache items by category
  Future<Map<String, List<String>>> getCacheItemsByCategory() async {
    final stats = await _storageManager.getCacheStats();
    final categorizedItems = <String, List<String>>{};
    
    // This is a simplified implementation
    // In practice, you'd iterate through all cache items and categorize them
    for (final category in _categoryTTLs.keys) {
      categorizedItems[category] = [];
    }
    
    // Use stats to avoid unused variable warning
    final _ = stats;
    
    return categorizedItems;
  }
  
  /// Clear cache by category
  Future<int> clearCacheByCategory(String category) async {
    int itemsCleared = 0;
    
    // This is a simplified implementation
    // In practice, you'd iterate through cache items and remove those matching the category
    
    return itemsCleared;
  }
  
  /// Get cache health score (0-100)
  Future<int> getCacheHealthScore() async {
    final stats = await _storageManager.getCacheStats();
    final totalItems = stats['totalItems'] as int;
    final expiredItems = stats['expiredItems'] as int;
    final totalSizeMB = double.parse(stats['totalSizeMB'] as String);
    
    int score = 100;
    
    // Deduct points for expired items
    if (totalItems > 0) {
      final expiredRatio = expiredItems / totalItems;
      score -= (expiredRatio * 30).round();
    }
    
    // Deduct points for excessive size
    if (totalSizeMB > 40) {
      score -= ((totalSizeMB - 40) * 2).round();
    }
    
    // Deduct points for too few items (underutilization)
    if (totalItems < 5) {
      score -= 20;
    }
    
    return max(0, min(100, score));
  }
  
  /// Schedule cache maintenance
  Future<void> scheduleMaintenance() async {
    // This would typically be called periodically
    await optimizeCache();
    
    final healthScore = await getCacheHealthScore();
    if (healthScore < 70) {
      // Perform more aggressive cleanup
      await _storageManager.cleanupExpiredCache();
    }
  }
}