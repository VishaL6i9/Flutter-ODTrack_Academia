import 'dart:async';
import '../../models/sync_models.dart';

/// Abstract interface for offline synchronization service
/// Handles data sync between local storage and server
abstract class SyncService {
  /// Initialize the sync service
  Future<void> initialize();
  
  /// Sync all data types
  Future<SyncResult> syncAll();
  
  /// Sync OD requests specifically
  Future<SyncResult> syncODRequests();
  
  /// Sync user data
  Future<SyncResult> syncUserData();
  
  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream;
  
  /// Queue an item for synchronization
  Future<void> queueForSync(SyncableItem item);
  
  /// Resolve sync conflicts
  Future<List<ConflictResolution>> resolveConflicts(List<SyncConflict> conflicts);
  
  /// Check if sync is in progress
  bool get isSyncing;
  
  /// Get last sync timestamp
  DateTime? get lastSyncTime;
  
  /// Force sync even if not needed
  Future<SyncResult> forcSync();
  
  /// Cancel ongoing sync operation
  Future<void> cancelSync();
}