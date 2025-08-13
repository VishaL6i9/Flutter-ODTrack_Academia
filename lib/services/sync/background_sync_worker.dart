import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';
import 'package:odtrack_academia/models/sync_models.dart';
import 'package:odtrack_academia/services/sync/sync_service.dart';

/// Background sync worker that runs in a separate isolate
/// Handles automatic synchronization with connectivity monitoring and retry logic
class BackgroundSyncWorker {
  final SyncService _syncService;
  final Connectivity _connectivity;
  
  // Worker state
  bool _isRunning = false;
  bool _isConnected = false;
  Timer? _syncTimer;
  Timer? _retryTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Sync configuration
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _retryBaseDelay = Duration(seconds: 30);
  static const int _maxRetryAttempts = 5;
  static const double _retryMultiplier = 2.0;
  
  // Retry state
  int _consecutiveFailures = 0;
  DateTime? _lastFailureTime;
  
  // Event streams
  final StreamController<BackgroundSyncEvent> _eventController = 
      StreamController<BackgroundSyncEvent>.broadcast();
  
  BackgroundSyncWorker({
    required SyncService syncService,
    Connectivity? connectivity,
  }) : _syncService = syncService,
       _connectivity = connectivity ?? Connectivity();

  /// Stream of background sync events
  Stream<BackgroundSyncEvent> get eventStream => _eventController.stream;
  
  /// Check if worker is currently running
  bool get isRunning => _isRunning;
  
  /// Check if device is connected to network
  bool get isConnected => _isConnected;
  
  /// Get current retry attempt count
  int get consecutiveFailures => _consecutiveFailures;

  /// Start the background sync worker
  Future<void> start() async {
    if (_isRunning) {
      debugPrint('BackgroundSyncWorker: Already running');
      return;
    }
    
    debugPrint('BackgroundSyncWorker: Starting...');
    _isRunning = true;
    
    try {
      // Initialize connectivity monitoring
      await _initializeConnectivityMonitoring();
      
      // Start periodic sync timer
      _startPeriodicSync();
      
      // Emit started event
      _emitEvent(BackgroundSyncEvent.started());
      
      debugPrint('BackgroundSyncWorker: Started successfully');
    } catch (error) {
      debugPrint('BackgroundSyncWorker: Failed to start - $error');
      _isRunning = false;
      _emitEvent(BackgroundSyncEvent.error('Failed to start worker: $error'));
      rethrow;
    }
  }

  /// Stop the background sync worker
  Future<void> stop() async {
    if (!_isRunning) {
      debugPrint('BackgroundSyncWorker: Already stopped');
      return;
    }
    
    debugPrint('BackgroundSyncWorker: Stopping...');
    _isRunning = false;
    
    // Cancel timers
    _syncTimer?.cancel();
    _retryTimer?.cancel();
    
    // Cancel connectivity subscription
    await _connectivitySubscription?.cancel();
    
    // Emit stopped event
    _emitEvent(BackgroundSyncEvent.stopped());
    
    debugPrint('BackgroundSyncWorker: Stopped');
  }

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivityMonitoring() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isConnected = !results.contains(ConnectivityResult.none);
    
    debugPrint('BackgroundSyncWorker: Initial connectivity - $_isConnected');
    
    // Monitor connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasConnected = _isConnected;
        _isConnected = !results.contains(ConnectivityResult.none);
        
        debugPrint('BackgroundSyncWorker: Connectivity changed - $_isConnected');
        
        // Emit connectivity event
        _emitEvent(BackgroundSyncEvent.connectivityChanged(_isConnected));
        
        // Trigger immediate sync when connectivity is restored
        if (!wasConnected && _isConnected) {
          debugPrint('BackgroundSyncWorker: Connectivity restored, triggering sync');
          _triggerImmediateSync();
        }
      },
      onError: (dynamic error) {
        debugPrint('BackgroundSyncWorker: Connectivity monitoring error - $error');
        _emitEvent(BackgroundSyncEvent.error('Connectivity monitoring error: $error'));
      },
    );
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_isRunning && _isConnected && !_syncService.isSyncing) {
        _triggerSync();
      }
    });
    
    debugPrint('BackgroundSyncWorker: Periodic sync started (${_syncInterval.inMinutes} min intervals)');
  }

  /// Trigger immediate sync
  void _triggerImmediateSync() {
    if (!_isRunning || !_isConnected || _syncService.isSyncing) {
      return;
    }
    
    // Cancel any pending retry timer
    _retryTimer?.cancel();
    
    // Trigger sync
    _triggerSync();
  }

  /// Trigger sync operation
  void _triggerSync() {
    unawaited(_performSync().catchError((Object error) {
      debugPrint('BackgroundSyncWorker: Sync failed - $error');
      _handleSyncFailure(error);
    }));
  }

  /// Perform sync operation
  Future<void> _performSync() async {
    if (!_isRunning || !_isConnected) {
      return;
    }
    
    debugPrint('BackgroundSyncWorker: Starting sync...');
    _emitEvent(BackgroundSyncEvent.syncStarted());
    
    try {
      final result = await _syncService.syncAll();
      
      if (result.success) {
        _handleSyncSuccess(result);
      } else {
        _handleSyncFailure(SyncError(
          code: 'SYNC_PARTIAL_FAILURE',
          message: 'Sync completed with ${result.itemsFailed} failures',
          userMessage: 'Some items failed to sync. Will retry automatically.',
        ));
      }
    } catch (error) {
      _handleSyncFailure(error);
    }
  }

  /// Handle successful sync
  void _handleSyncSuccess(SyncResult result) {
    debugPrint('BackgroundSyncWorker: Sync completed successfully - ${result.itemsSynced} items');
    
    // Reset failure count on success
    _consecutiveFailures = 0;
    _lastFailureTime = null;
    
    // Cancel any pending retry timer
    _retryTimer?.cancel();
    
    // Emit success event
    _emitEvent(BackgroundSyncEvent.syncCompleted(result));
  }

  /// Handle sync failure with retry logic
  void _handleSyncFailure(dynamic error) {
    _consecutiveFailures++;
    _lastFailureTime = DateTime.now();
    
    debugPrint('BackgroundSyncWorker: Sync failed (attempt $_consecutiveFailures) - $error');
    
    // Emit failure event
    _emitEvent(BackgroundSyncEvent.syncFailed(error.toString(), _consecutiveFailures));
    
    // Schedule retry if we haven't exceeded max attempts
    if (_consecutiveFailures < _maxRetryAttempts && _isRunning) {
      _scheduleRetry();
    } else {
      debugPrint('BackgroundSyncWorker: Max retry attempts reached, giving up');
      _emitEvent(BackgroundSyncEvent.maxRetriesReached(_consecutiveFailures));
    }
  }

  /// Schedule retry with exponential backoff
  void _scheduleRetry() {
    _retryTimer?.cancel();
    
    final retryDelay = _calculateRetryDelay(_consecutiveFailures);
    
    debugPrint('BackgroundSyncWorker: Scheduling retry in ${retryDelay.inSeconds} seconds');
    
    _retryTimer = Timer(retryDelay, () {
      if (_isRunning && _isConnected) {
        debugPrint('BackgroundSyncWorker: Executing scheduled retry');
        _triggerSync();
      }
    });
    
    _emitEvent(BackgroundSyncEvent.retryScheduled(retryDelay, _consecutiveFailures));
  }

  /// Calculate retry delay with exponential backoff
  Duration _calculateRetryDelay(int attemptNumber) {
    final multiplier = pow(_retryMultiplier, attemptNumber - 1);
    final delaySeconds = (_retryBaseDelay.inSeconds * multiplier).round();
    
    // Cap maximum delay at 30 minutes
    final cappedDelaySeconds = min(delaySeconds, 1800);
    
    return Duration(seconds: cappedDelaySeconds);
  }

  /// Force immediate sync (ignores connectivity and running state)
  Future<SyncResult> forceSync() async {
    debugPrint('BackgroundSyncWorker: Force sync requested');
    
    try {
      _emitEvent(BackgroundSyncEvent.syncStarted());
      final result = await _syncService.forcSync();
      
      if (result.success) {
        _handleSyncSuccess(result);
      } else {
        _emitEvent(BackgroundSyncEvent.syncFailed(
          'Force sync completed with errors', 
          _consecutiveFailures
        ));
      }
      
      return result;
    } catch (error) {
      _emitEvent(BackgroundSyncEvent.syncFailed(error.toString(), _consecutiveFailures));
      rethrow;
    }
  }

  /// Get worker statistics
  Map<String, dynamic> getStatistics() {
    return {
      'isRunning': _isRunning,
      'isConnected': _isConnected,
      'consecutiveFailures': _consecutiveFailures,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'syncInterval': _syncInterval.inMinutes,
      'maxRetryAttempts': _maxRetryAttempts,
      'nextRetryIn': _retryTimer?.isActive == true 
          ? 'scheduled' 
          : 'none',
    };
  }

  /// Emit background sync event
  void _emitEvent(BackgroundSyncEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    await _eventController.close();
  }
}

/// Background sync event types
class BackgroundSyncEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  BackgroundSyncEvent._(this.type, this.data) : timestamp = DateTime.now();

  factory BackgroundSyncEvent.started() => 
      BackgroundSyncEvent._('started', {});

  factory BackgroundSyncEvent.stopped() => 
      BackgroundSyncEvent._('stopped', {});

  factory BackgroundSyncEvent.connectivityChanged(bool isConnected) => 
      BackgroundSyncEvent._('connectivity_changed', {'isConnected': isConnected});

  factory BackgroundSyncEvent.syncStarted() => 
      BackgroundSyncEvent._('sync_started', {});

  factory BackgroundSyncEvent.syncCompleted(SyncResult result) => 
      BackgroundSyncEvent._('sync_completed', {
        'itemsSynced': result.itemsSynced,
        'itemsFailed': result.itemsFailed,
        'duration': result.duration.inMilliseconds,
      });

  factory BackgroundSyncEvent.syncFailed(String error, int attemptNumber) => 
      BackgroundSyncEvent._('sync_failed', {
        'error': error,
        'attemptNumber': attemptNumber,
      });

  factory BackgroundSyncEvent.retryScheduled(Duration delay, int attemptNumber) => 
      BackgroundSyncEvent._('retry_scheduled', {
        'delaySeconds': delay.inSeconds,
        'attemptNumber': attemptNumber,
      });

  factory BackgroundSyncEvent.maxRetriesReached(int totalAttempts) => 
      BackgroundSyncEvent._('max_retries_reached', {
        'totalAttempts': totalAttempts,
      });

  factory BackgroundSyncEvent.error(String message) => 
      BackgroundSyncEvent._('error', {'message': message});

  @override
  String toString() => 'BackgroundSyncEvent(type: $type, data: $data, timestamp: $timestamp)';
}