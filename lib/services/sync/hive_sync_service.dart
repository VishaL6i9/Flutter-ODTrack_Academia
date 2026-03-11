import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';
import 'package:odtrack_academia/core/services/base_service.dart';
import 'package:odtrack_academia/core/storage/storage_manager.dart';
import 'package:odtrack_academia/core/storage/sync_queue_manager.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/sync_models.dart';
import 'package:odtrack_academia/models/user.dart';
import 'package:odtrack_academia/services/sync/sync_service.dart';
import 'package:odtrack_academia/services/sync/background_sync_worker.dart';
import 'package:odtrack_academia/services/sync/offline_operation_queue.dart';
import 'package:odtrack_academia/services/sync/sync_notification_service.dart';
import 'package:odtrack_academia/services/api/api_client.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';

/// Concrete implementation of SyncService using Hive storage
/// Handles offline synchronization with automatic conflict resolution
class HiveSyncService extends BaseServiceImpl implements SyncService {
  final EnhancedStorageManager _storageManager;
  final SyncQueueManager _queueManager;
  final Connectivity _connectivity;
  final ApiClient _apiClient;
  
  // Enhanced sync components
  late final BackgroundSyncWorker _backgroundWorker;
  late final OfflineOperationQueue _offlineQueue;
  
  // Sync state management
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  final StreamController<SyncStatus> _syncStatusController = 
      StreamController<SyncStatus>.broadcast();
  
  // Connectivity monitoring
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = false;
  
  // Auto-sync configuration
  Timer? _autoSyncTimer;
  
  HiveSyncService({
    required EnhancedStorageManager storageManager,
    required SyncQueueManager queueManager,
    Connectivity? connectivity,
    ApiClient? apiClient,
  }) : _storageManager = storageManager,
       _queueManager = queueManager,
       _connectivity = connectivity ?? Connectivity(),
       _apiClient = apiClient ?? ApiClient(baseUrl: AppConstants.baseUrl) {
    // Initialize enhanced sync components
    _backgroundWorker = BackgroundSyncWorker(
      syncService: this,
      connectivity: _connectivity,
    );
    _offlineQueue = OfflineOperationQueue(
      queueManager: _queueManager,
    );
  }

  @override
  String get serviceName => 'HiveSyncService';

  @override
  bool get isSyncing => _isSyncing;

  @override
  DateTime? get lastSyncTime => _lastSyncTime;

  @override
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  @override
  Future<void> onInitialize() async {
    await _storageManager.initialize();
    await _initializeConnectivityMonitoring();
    
    // Start background sync worker
    await _backgroundWorker.start();
    
    // Initialize notifications
    await SyncNotificationService().initialize();
    
    // Listen to background worker events
    _backgroundWorker.eventStream.listen((event) {
      debugPrint('HiveSyncService: Background worker event - ${event.type}');
      
      // Update sync status based on background worker events
      switch (event.type) {
        case 'sync_started':
          _syncStatusController.add(SyncStatus.inProgress);
          break;
        case 'sync_completed':
          _syncStatusController.add(SyncStatus.completed);
          final itemsSynced = (event.data['syncedCount'] as int?) ?? 1;
          SyncNotificationService().showSyncSuccessNotification(itemsSynced: itemsSynced);
          break;
        case 'sync_failed':
          _syncStatusController.add(SyncStatus.failed);
          final errorMsg = (event.data['error'] as String?) ?? 'Unknown error occurred.';
          SyncNotificationService().showSyncErrorNotification(errorMsg);
          break;
      }
    });
    
    // Listen to offline queue events
    _offlineQueue.eventStream.listen((event) {
      debugPrint('HiveSyncService: Offline queue event - ${event.type}');
    });
    
    _startAutoSync();
  }

  @override
  Future<void> onDispose() async {
    _autoSyncTimer?.cancel();
    await _connectivitySubscription?.cancel();
    await _backgroundWorker.dispose();
    await _offlineQueue.dispose();
    await _syncStatusController.close();
  }

  @override
  Future<bool> performHealthCheck() async {
    try {
      // Check storage health
      final storageStats = await _storageManager.getStorageStats();
      final queueHealth = await _queueManager.getQueueHealth();
      
      // Service is healthy if:
      // 1. Storage is accessible
      // 2. Queue is not overwhelmed
      // 3. No critical errors in recent sync attempts
      return (storageStats['totalBoxes'] as int? ?? 0) == 4 && 
             (queueHealth['isHealthy'] as bool? ?? false);
    } catch (e) {
      return false;
    }
  }

  /// Initialize connectivity monitoring for automatic sync
  Future<void> _initializeConnectivityMonitoring() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isConnected = !results.contains(ConnectivityResult.none);
    
    // Monitor connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasConnected = _isConnected;
        _isConnected = !results.contains(ConnectivityResult.none);
        
        // Trigger sync when connectivity is restored
        if (!wasConnected && _isConnected) {
          _triggerAutoSync();
        }
      },
    );
  }

  /// Start automatic sync timer
  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    // _autoSyncTimer = Timer.periodic(_autoSyncInterval, (_) {
    //   if (_isConnected && !_isSyncing) {
    //     _triggerAutoSync();
    //   }
    // });
    debugPrint('HiveSyncService: Periodic auto-sync disabled to save battery');
  }

  /// Trigger automatic sync
  void _triggerAutoSync() {
    unawaited(syncAll().catchError((Object error) {
      debugPrint('Auto-sync failed: $error');
      return SyncResult(
        success: false,
        itemsSynced: 0,
        itemsFailed: 0,
        errors: [error.toString()],
        timestamp: DateTime.now(),
        duration: Duration.zero,
      );
    }));
  }

  @override
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      throw SyncError(
        code: 'SYNC_IN_PROGRESS',
        message: 'Sync operation already in progress',
        userMessage: 'Sync is already running. Please wait for it to complete.',
      );
    }

    if (!_isConnected) {
      throw NetworkError.noConnection();
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.inProgress);
    
    final startTime = DateTime.now();
    int totalSynced = 0;
    int totalFailed = 0;
    final errors = <String>[];

    try {
      // Check for cancellation
      if (!_isSyncing) {
        throw SyncError(
          code: 'SYNC_CANCELLED',
          message: 'Sync operation was cancelled',
          userMessage: 'Sync was cancelled.',
        );
      }

      // Sync OD requests first (higher priority)
      final odResult = await syncODRequests();
      totalSynced += odResult.itemsSynced;
      totalFailed += odResult.itemsFailed;
      errors.addAll(odResult.errors);

      // Check for cancellation again
      if (!_isSyncing) {
        throw SyncError(
          code: 'SYNC_CANCELLED',
          message: 'Sync operation was cancelled',
          userMessage: 'Sync was cancelled.',
        );
      }

      // Sync user data
      final userResult = await syncUserData();
      totalSynced += userResult.itemsSynced;
      totalFailed += userResult.itemsFailed;
      errors.addAll(userResult.errors);

      // Clean up completed items
      await _queueManager.cleanupOldItems();
      
      _lastSyncTime = DateTime.now();
      
      final result = SyncResult(
        success: totalFailed == 0,
        itemsSynced: totalSynced,
        itemsFailed: totalFailed,
        errors: errors,
        timestamp: _lastSyncTime!,
        duration: _lastSyncTime!.difference(startTime),
      );

      _syncStatusController.add(totalFailed == 0 ? SyncStatus.completed : SyncStatus.failed);
      return result;

    } catch (error) {
      _syncStatusController.add(SyncStatus.failed);
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<SyncResult> syncODRequests() async {
    ensureInitialized();
    
    final startTime = DateTime.now();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    try {
      // Get OD request items from sync queue
      final queueItems = (await _queueManager.getNextSyncBatch(batchSize: 20))
          .where((item) => item.itemType == 'od_request')
          .toList();

      for (final queueItem in queueItems) {
        try {
          await _queueManager.markAsInProgress(queueItem.id);
          
          final success = await _syncODRequestItem(queueItem);
          if (success) {
            await _queueManager.markAsCompleted(queueItem.id);
            _offlineQueue.markOperationCompleted(queueItem.id, true);
            synced++;
          } else {
            await _queueManager.markAsFailed(queueItem.id, 'Sync operation failed');
            _offlineQueue.markOperationCompleted(queueItem.id, false);
            failed++;
          }
        } catch (error) {
          await _queueManager.markAsFailed(queueItem.id, error.toString());
          errors.add('Failed to sync OD request ${queueItem.itemId}: $error');
          failed++;
        }
      }

      return SyncResult(
        success: failed == 0,
        itemsSynced: synced,
        itemsFailed: failed,
        errors: errors,
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime),
      );

    } catch (error) {
      throw SyncError(
        code: 'OD_SYNC_FAILED',
        message: 'Failed to sync OD requests: $error',
        userMessage: 'Failed to sync OD requests. Will retry automatically.',
      );
    }
  }

  @override
  Future<SyncResult> syncUserData() async {
    ensureInitialized();
    
    final startTime = DateTime.now();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    try {
      // Get user data items from sync queue
      final queueItems = (await _queueManager.getNextSyncBatch(batchSize: 10))
          .where((item) => item.itemType == 'user_data')
          .toList();

      for (final queueItem in queueItems) {
        try {
          await _queueManager.markAsInProgress(queueItem.id);
          
          final success = await _syncUserDataItem(queueItem);
          if (success) {
            await _queueManager.markAsCompleted(queueItem.id);
            _offlineQueue.markOperationCompleted(queueItem.id, true);
            synced++;
          } else {
            await _queueManager.markAsFailed(queueItem.id, 'Sync operation failed');
            _offlineQueue.markOperationCompleted(queueItem.id, false);
            failed++;
          }
        } catch (error) {
          await _queueManager.markAsFailed(queueItem.id, error.toString());
          errors.add('Failed to sync user data ${queueItem.itemId}: $error');
          failed++;
        }
      }

      return SyncResult(
        success: failed == 0,
        itemsSynced: synced,
        itemsFailed: failed,
        errors: errors,
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime),
      );

    } catch (error) {
      throw SyncError(
        code: 'USER_SYNC_FAILED',
        message: 'Failed to sync user data: $error',
        userMessage: 'Failed to sync user data. Will retry automatically.',
      );
    }
  }

  /// Sync individual OD request item
  Future<bool> _syncODRequestItem(SyncQueueItem queueItem) async {
    try {
      // Simulate server API call based on operation
      switch (queueItem.operation) {
        case 'create':
          return await _createODRequestOnServer(queueItem);
        case 'update':
          return await _updateODRequestOnServer(queueItem);
        case 'delete':
          return await _deleteODRequestOnServer(queueItem);
        default:
          throw SyncError(
            code: 'UNKNOWN_OPERATION',
            message: 'Unknown sync operation: ${queueItem.operation}',
          );
      }
    } catch (error) {
      if (error is SyncError && error.code == 'SYNC_CONFLICT') {
        // Handle conflict by queuing for resolution
        await _handleSyncConflict(queueItem, error);
        return false;
      }
      rethrow;
    }
  }

  /// Sync individual user data item
  Future<bool> _syncUserDataItem(SyncQueueItem queueItem) async {
    try {
      // Simulate server API call based on operation
      switch (queueItem.operation) {
        case 'update':
          return await _updateUserDataOnServer(queueItem);
        default:
          throw SyncError(
            code: 'UNKNOWN_OPERATION',
            message: 'Unknown sync operation: ${queueItem.operation}',
          );
      }
    } catch (error) {
      if (error is SyncError && error.code == 'SYNC_CONFLICT') {
        // Handle conflict by queuing for resolution
        await _handleSyncConflict(queueItem, error);
        return false;
      }
      rethrow;
    }
  }

  /// Create OD request on server via API
  Future<bool> _createODRequestOnServer(SyncQueueItem queueItem) async {
    try {
      final response = await _apiClient.post(
        '/od-requests/',
        body: queueItem.data,
      );
      
      debugPrint('Created OD request ${queueItem.itemId} on server');
      return response['id'] != null;
    } on NetworkError catch (e) {
      if (e.code == 'SERVER_ERROR' && e.statusCode == 409) {
        throw SyncError.conflictDetected(queueItem.itemId, queueItem.itemType);
      }
      rethrow;
    }
  }

  /// Update OD request on server via API
  Future<bool> _updateODRequestOnServer(SyncQueueItem queueItem) async {
    try {
      await _apiClient.put(
        '/od-requests/${queueItem.itemId}',
        body: queueItem.data,
      );
      
      debugPrint('Updated OD request ${queueItem.itemId} on server');
      return true;
    } on NetworkError catch (e) {
      if (e.code == 'SERVER_ERROR' && e.statusCode == 409) {
        throw SyncError.conflictDetected(queueItem.itemId, queueItem.itemType);
      }
      rethrow;
    }
  }

  /// Delete OD request on server via API
  Future<bool> _deleteODRequestOnServer(SyncQueueItem queueItem) async {
    try {
      await _apiClient.delete('/od-requests/${queueItem.itemId}');
      
      debugPrint('Deleted OD request ${queueItem.itemId} on server');
      return true;
    } catch (e) {
      debugPrint('Error deleting OD request: $e');
      rethrow;
    }
  }

  /// Update user data on server via API
  Future<bool> _updateUserDataOnServer(SyncQueueItem queueItem) async {
    try {
      await _apiClient.put(
        '/users/${queueItem.itemId}',
        body: queueItem.data,
      );
      
      debugPrint('Updated user data ${queueItem.itemId} on server');
      return true;
    } on NetworkError catch (e) {
      if (e.code == 'SERVER_ERROR' && e.statusCode == 409) {
        throw SyncError.conflictDetected(queueItem.itemId, queueItem.itemType);
      }
      rethrow;
    }
  }

  /// Handle sync conflict by storing it for resolution
  Future<void> _handleSyncConflict(SyncQueueItem queueItem, SyncError error) async {
    // Fetch server data to compare
    final serverData = await _fetchServerData(queueItem.itemId, queueItem.itemType);
    
    final conflict = SyncConflict(
      itemId: queueItem.itemId,
      itemType: queueItem.itemType,
      localData: queueItem.data,
      serverData: serverData,
      localTimestamp: queueItem.queuedAt,
      serverTimestamp: DateTime.parse(
        (serverData['updated_at'] as String?) ?? DateTime.now().toIso8601String()
      ),
    );
    
    await _storageManager.storeSyncConflict(conflict);
    await _queueManager.markAsConflicted(queueItem.id, error.message);
  }

  /// Fetch server data for conflict resolution
  Future<Map<String, dynamic>> _fetchServerData(String itemId, String itemType) async {
    try {
      String endpoint;
      switch (itemType) {
        case 'od_request':
          endpoint = '/od-requests/$itemId';
          break;
        case 'user':
          endpoint = '/users/$itemId';
          break;
        default:
          throw ArgumentError('Unknown item type: $itemType');
      }
      
      final response = await _apiClient.get(endpoint);
      return response;
    } catch (e) {
      debugPrint('Error fetching server data: $e');
      rethrow;
    }
  }

  @override
  Future<void> queueForSync(SyncableItem item) async {
    ensureInitialized();
    
    String operation;
    if (item.syncStatus == SyncStatus.pending) {
      operation = 'create';
    } else {
      operation = 'update';
    }
    
    if (item is ODRequest) {
      await _queueManager.queueODRequest(
        requestId: item.id,
        operation: operation,
        requestData: item.toJson(),
      );
    } else if (item is User) {
      await _queueManager.queueUserData(
        userId: item.id,
        operation: operation,
        userData: item.toJson(),
      );
    } else {
      throw SyncError(
        code: 'UNSUPPORTED_ITEM_TYPE',
        message: 'Unsupported syncable item type: ${item.runtimeType}',
      );
    }
  }

  @override
  Future<List<ConflictResolution>> resolveConflicts(List<SyncConflict> conflicts) async {
    ensureInitialized();
    
    final resolutions = <ConflictResolution>[];
    
    for (final conflict in conflicts) {
      try {
        final resolution = await _resolveConflictUsingTimestamp(conflict);
        
        // Remove resolved conflict from storage
        await _storageManager.removeResolvedConflict(conflict.itemId);
        
        // Re-queue the resolved item for sync
        await _requeueResolvedItem(conflict, resolution);
        
        // Only add to resolutions if all operations succeeded
        resolutions.add(resolution);
        
      } catch (error) {
        debugPrint('Failed to resolve conflict for ${conflict.itemId}: $error');
        // Keep conflict in storage for manual resolution
      }
    }
    
    return resolutions;
  }

  /// Resolve conflict using server-side timestamp (server wins)
  Future<ConflictResolution> _resolveConflictUsingTimestamp(SyncConflict conflict) async {
    // Server-side timestamp resolution: server data wins if it's newer
    final useServerData = conflict.serverTimestamp.isAfter(conflict.localTimestamp);
    
    if (useServerData) {
      return ConflictResolution(
        conflictId: conflict.itemId,
        resolution: 'use_server',
        mergedData: conflict.serverData,
      );
    } else {
      return ConflictResolution(
        conflictId: conflict.itemId,
        resolution: 'use_local',
        mergedData: conflict.localData,
      );
    }
  }

  /// Re-queue resolved item for sync
  Future<void> _requeueResolvedItem(SyncConflict conflict, ConflictResolution resolution) async {
    final data = resolution.mergedData ?? 
                 (resolution.resolution == 'use_server' ? conflict.serverData : conflict.localData);
    
    await _queueManager.queueItem(
      itemId: conflict.itemId,
      itemType: conflict.itemType,
      operation: 'update',
      data: data,
      priority: 8, // High priority for resolved conflicts
    );
  }

  @override
  Future<SyncResult> forceSync() async {
    // Reset any failed items and force sync
    await _queueManager.resetFailedItems();
    return await syncAll();
  }

  @override
  Future<void> cancelSync() async {
    if (!_isSyncing) {
      return;
    }
    
    // In a real implementation, we would cancel ongoing HTTP requests
    _isSyncing = false;
    _syncStatusController.add(SyncStatus.failed);
  }

  /// Get sync statistics for monitoring
  Future<Map<String, dynamic>> getSyncStatistics() async {
    final queueHealth = await _queueManager.getQueueHealth();
    final storageStats = await _storageManager.getStorageStats();
    
    return {
      'isConnected': _isConnected,
      'isSyncing': _isSyncing,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'queueHealth': queueHealth,
      'storageStats': storageStats,
      'autoSyncEnabled': _autoSyncTimer?.isActive ?? false,
    };
  }

  /// Get all unresolved conflicts
  List<SyncConflict> getUnresolvedConflicts() {
    return _storageManager.getUnresolvedConflicts();
  }

  /// Manually resolve all conflicts using server-side timestamps
  Future<int> resolveAllConflicts() async {
    final conflicts = getUnresolvedConflicts();
    if (conflicts.isEmpty) return 0;
    
    final resolutions = await resolveConflicts(conflicts);
    return resolutions.length;
  }

  /// Get offline operation queue for managing offline operations
  OfflineOperationQueue get offlineQueue => _offlineQueue;

  /// Get background sync worker for monitoring sync status
  BackgroundSyncWorker get backgroundWorker => _backgroundWorker;

  /// Queue OD request for offline sync
  Future<String> queueODRequestOffline(ODRequest request, String operation) async {
    switch (operation) {
      case 'create':
        return await _offlineQueue.queueCreateODRequest(request);
      case 'update':
        return await _offlineQueue.queueUpdateODRequest(request);
      case 'delete':
        return await _offlineQueue.queueDeleteODRequest(request.id);
      default:
        throw ArgumentError('Unsupported operation: $operation');
    }
  }

  /// Queue user data for offline sync
  Future<String> queueUserDataOffline(User user) async {
    return await _offlineQueue.queueUpdateUserData(user);
  }

  /// Queue bulk operations for offline sync
  Future<String> queueBulkOperationOffline(
    List<String> requestIds, 
    String reason, 
    String action
  ) async {
    switch (action) {
      case 'approve':
        return await _offlineQueue.queueBulkApproval(requestIds, reason);
      case 'reject':
        return await _offlineQueue.queueBulkRejection(requestIds, reason);
      default:
        throw ArgumentError('Unsupported bulk action: $action');
    }
  }

  /// Force immediate sync through background worker
  Future<SyncResult> forceImmediateSync() async {
    return await _backgroundWorker.forceSync();
  }

  /// Get comprehensive sync and queue statistics
  Future<Map<String, dynamic>> getComprehensiveStatistics() async {
    final syncStats = await getSyncStatistics();
    final queueStats = _offlineQueue.getStatistics();
    final workerStats = _backgroundWorker.getStatistics();
    
    return {
      'sync': syncStats,
      'offlineQueue': queueStats,
      'backgroundWorker': workerStats,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}