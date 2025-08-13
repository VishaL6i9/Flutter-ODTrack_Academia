import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:odtrack_academia/core/storage/sync_queue_manager.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/user.dart';

/// Manages offline operations and queues them for synchronization
/// Handles user actions when device is offline
class OfflineOperationQueue {
  final SyncQueueManager _queueManager;
  
  // Operation tracking
  final Map<String, PendingOperation> _pendingOperations = {};
  final StreamController<OfflineOperationEvent> _eventController = 
      StreamController<OfflineOperationEvent>.broadcast();
  
  OfflineOperationQueue({
    required SyncQueueManager queueManager,
  }) : _queueManager = queueManager;

  /// Stream of offline operation events
  Stream<OfflineOperationEvent> get eventStream => _eventController.stream;

  /// Queue OD request creation for offline sync
  Future<String> queueCreateODRequest(ODRequest request) async {
    final operationId = _generateOperationId();
    
    try {
      // Queue the operation
      final queueId = await _queueManager.queueODRequest(
        requestId: request.id,
        operation: 'create',
        requestData: request.toJson(),
      );
      
      // Track pending operation
      final pendingOp = PendingOperation(
        id: operationId,
        type: OperationType.createODRequest,
        queueId: queueId,
        itemId: request.id,
        timestamp: DateTime.now(),
        data: request.toJson(),
      );
      
      _pendingOperations[operationId] = pendingOp;
      
      // Emit event
      _emitEvent(OfflineOperationEvent.queued(pendingOp));
      
      debugPrint('OfflineOperationQueue: Queued OD request creation - ${request.id}');
      return operationId;
      
    } catch (error) {
      debugPrint('OfflineOperationQueue: Failed to queue OD request creation - $error');
      _emitEvent(OfflineOperationEvent.error(operationId, error.toString()));
      rethrow;
    }
  }

  /// Queue OD request update for offline sync
  Future<String> queueUpdateODRequest(ODRequest request) async {
    final operationId = _generateOperationId();
    
    try {
      // Queue the operation
      final queueId = await _queueManager.queueODRequest(
        requestId: request.id,
        operation: 'update',
        requestData: request.toJson(),
      );
      
      // Track pending operation
      final pendingOp = PendingOperation(
        id: operationId,
        type: OperationType.updateODRequest,
        queueId: queueId,
        itemId: request.id,
        timestamp: DateTime.now(),
        data: request.toJson(),
      );
      
      _pendingOperations[operationId] = pendingOp;
      
      // Emit event
      _emitEvent(OfflineOperationEvent.queued(pendingOp));
      
      debugPrint('OfflineOperationQueue: Queued OD request update - ${request.id}');
      return operationId;
      
    } catch (error) {
      debugPrint('OfflineOperationQueue: Failed to queue OD request update - $error');
      _emitEvent(OfflineOperationEvent.error(operationId, error.toString()));
      rethrow;
    }
  }

  /// Queue OD request deletion for offline sync
  Future<String> queueDeleteODRequest(String requestId) async {
    final operationId = _generateOperationId();
    
    try {
      // Queue the operation
      final queueId = await _queueManager.queueODRequest(
        requestId: requestId,
        operation: 'delete',
        requestData: {'id': requestId, 'deleted': true},
      );
      
      // Track pending operation
      final pendingOp = PendingOperation(
        id: operationId,
        type: OperationType.deleteODRequest,
        queueId: queueId,
        itemId: requestId,
        timestamp: DateTime.now(),
        data: {'id': requestId, 'deleted': true},
      );
      
      _pendingOperations[operationId] = pendingOp;
      
      // Emit event
      _emitEvent(OfflineOperationEvent.queued(pendingOp));
      
      debugPrint('OfflineOperationQueue: Queued OD request deletion - $requestId');
      return operationId;
      
    } catch (error) {
      debugPrint('OfflineOperationQueue: Failed to queue OD request deletion - $error');
      _emitEvent(OfflineOperationEvent.error(operationId, error.toString()));
      rethrow;
    }
  }

  /// Queue user data update for offline sync
  Future<String> queueUpdateUserData(User user) async {
    final operationId = _generateOperationId();
    
    try {
      // Queue the operation
      final queueId = await _queueManager.queueUserData(
        userId: user.id,
        operation: 'update',
        userData: user.toJson(),
      );
      
      // Track pending operation
      final pendingOp = PendingOperation(
        id: operationId,
        type: OperationType.updateUserData,
        queueId: queueId,
        itemId: user.id,
        timestamp: DateTime.now(),
        data: user.toJson(),
      );
      
      _pendingOperations[operationId] = pendingOp;
      
      // Emit event
      _emitEvent(OfflineOperationEvent.queued(pendingOp));
      
      debugPrint('OfflineOperationQueue: Queued user data update - ${user.id}');
      return operationId;
      
    } catch (error) {
      debugPrint('OfflineOperationQueue: Failed to queue user data update - $error');
      _emitEvent(OfflineOperationEvent.error(operationId, error.toString()));
      rethrow;
    }
  }

  /// Queue bulk approval operation for offline sync
  Future<String> queueBulkApproval(List<String> requestIds, String reason) async {
    final operationId = _generateOperationId();
    
    try {
      final bulkData = {
        'requestIds': requestIds,
        'reason': reason,
        'action': 'bulk_approve',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Queue the operation
      final queueId = await _queueManager.queueItem(
        itemId: operationId,
        itemType: 'bulk_operation',
        operation: 'bulk_approve',
        data: bulkData,
        priority: 8, // High priority for bulk operations
      );
      
      // Track pending operation
      final pendingOp = PendingOperation(
        id: operationId,
        type: OperationType.bulkApproval,
        queueId: queueId,
        itemId: operationId,
        timestamp: DateTime.now(),
        data: bulkData,
      );
      
      _pendingOperations[operationId] = pendingOp;
      
      // Emit event
      _emitEvent(OfflineOperationEvent.queued(pendingOp));
      
      debugPrint('OfflineOperationQueue: Queued bulk approval - ${requestIds.length} requests');
      return operationId;
      
    } catch (error) {
      debugPrint('OfflineOperationQueue: Failed to queue bulk approval - $error');
      _emitEvent(OfflineOperationEvent.error(operationId, error.toString()));
      rethrow;
    }
  }

  /// Queue bulk rejection operation for offline sync
  Future<String> queueBulkRejection(List<String> requestIds, String reason) async {
    final operationId = _generateOperationId();
    
    try {
      final bulkData = {
        'requestIds': requestIds,
        'reason': reason,
        'action': 'bulk_reject',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Queue the operation
      final queueId = await _queueManager.queueItem(
        itemId: operationId,
        itemType: 'bulk_operation',
        operation: 'bulk_reject',
        data: bulkData,
        priority: 8, // High priority for bulk operations
      );
      
      // Track pending operation
      final pendingOp = PendingOperation(
        id: operationId,
        type: OperationType.bulkRejection,
        queueId: queueId,
        itemId: operationId,
        timestamp: DateTime.now(),
        data: bulkData,
      );
      
      _pendingOperations[operationId] = pendingOp;
      
      // Emit event
      _emitEvent(OfflineOperationEvent.queued(pendingOp));
      
      debugPrint('OfflineOperationQueue: Queued bulk rejection - ${requestIds.length} requests');
      return operationId;
      
    } catch (error) {
      debugPrint('OfflineOperationQueue: Failed to queue bulk rejection - $error');
      _emitEvent(OfflineOperationEvent.error(operationId, error.toString()));
      rethrow;
    }
  }

  /// Get all pending operations
  List<PendingOperation> getPendingOperations() {
    return _pendingOperations.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Get pending operations by type
  List<PendingOperation> getPendingOperationsByType(OperationType type) {
    return _pendingOperations.values
        .where((op) => op.type == type)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Cancel pending operation
  Future<bool> cancelOperation(String operationId) async {
    final operation = _pendingOperations[operationId];
    if (operation == null) {
      return false;
    }
    
    try {
      // Mark as completed in queue to prevent sync
      await _queueManager.markAsCompleted(operation.queueId);
      
      // Remove from pending operations
      _pendingOperations.remove(operationId);
      
      // Emit event
      _emitEvent(OfflineOperationEvent.cancelled(operation));
      
      debugPrint('OfflineOperationQueue: Cancelled operation - $operationId');
      return true;
      
    } catch (error) {
      debugPrint('OfflineOperationQueue: Failed to cancel operation - $error');
      _emitEvent(OfflineOperationEvent.error(operationId, error.toString()));
      return false;
    }
  }

  /// Mark operation as completed (called by sync service)
  void markOperationCompleted(String queueId, bool success) {
    final operation = _pendingOperations.values
        .where((op) => op.queueId == queueId)
        .firstOrNull;
    
    if (operation != null) {
      _pendingOperations.remove(operation.id);
      
      if (success) {
        _emitEvent(OfflineOperationEvent.completed(operation));
        debugPrint('OfflineOperationQueue: Operation completed - ${operation.id}');
      } else {
        _emitEvent(OfflineOperationEvent.failed(operation));
        debugPrint('OfflineOperationQueue: Operation failed - ${operation.id}');
      }
    }
  }

  /// Get operation statistics
  Map<String, dynamic> getStatistics() {
    final operations = _pendingOperations.values.toList();
    final typeCount = <OperationType, int>{};
    
    for (final op in operations) {
      typeCount[op.type] = (typeCount[op.type] ?? 0) + 1;
    }
    
    final oldestOperation = operations.isNotEmpty
        ? operations.map((op) => op.timestamp).reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    
    return {
      'totalPending': operations.length,
      'byType': typeCount.map((type, count) => MapEntry(type.name, count)),
      'oldestPendingAge': oldestOperation != null
          ? DateTime.now().difference(oldestOperation).inMinutes
          : null,
    };
  }

  /// Clear all completed operations from tracking
  void clearCompletedOperations() {
    // This is handled automatically when operations complete
    // But we can clean up any orphaned operations
    final currentTime = DateTime.now();
    final orphanedOperations = _pendingOperations.entries
        .where((entry) => currentTime.difference(entry.value.timestamp).inHours > 24)
        .map((entry) => entry.key)
        .toList();
    
    for (final operationId in orphanedOperations) {
      _pendingOperations.remove(operationId);
      debugPrint('OfflineOperationQueue: Cleaned up orphaned operation - $operationId');
    }
  }

  /// Generate unique operation ID
  String _generateOperationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString().padLeft(6, '0');
    return 'op_${timestamp}_$random';
  }

  /// Emit offline operation event
  void _emitEvent(OfflineOperationEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _eventController.close();
    _pendingOperations.clear();
  }
}

/// Represents a pending offline operation
class PendingOperation {
  final String id;
  final OperationType type;
  final String queueId;
  final String itemId;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const PendingOperation({
    required this.id,
    required this.type,
    required this.queueId,
    required this.itemId,
    required this.timestamp,
    required this.data,
  });

  @override
  String toString() => 'PendingOperation(id: $id, type: $type, itemId: $itemId)';
}

/// Types of offline operations
enum OperationType {
  createODRequest,
  updateODRequest,
  deleteODRequest,
  updateUserData,
  bulkApproval,
  bulkRejection,
}

/// Offline operation events
class OfflineOperationEvent {
  final String type;
  final PendingOperation? operation;
  final String? error;
  final DateTime timestamp;

  OfflineOperationEvent._(this.type, this.operation, this.error) 
      : timestamp = DateTime.now();

  factory OfflineOperationEvent.queued(PendingOperation operation) =>
      OfflineOperationEvent._('queued', operation, null);

  factory OfflineOperationEvent.completed(PendingOperation operation) =>
      OfflineOperationEvent._('completed', operation, null);

  factory OfflineOperationEvent.failed(PendingOperation operation) =>
      OfflineOperationEvent._('failed', operation, null);

  factory OfflineOperationEvent.cancelled(PendingOperation operation) =>
      OfflineOperationEvent._('cancelled', operation, null);

  factory OfflineOperationEvent.error(String operationId, String error) =>
      OfflineOperationEvent._('error', null, error);

  @override
  String toString() => 'OfflineOperationEvent(type: $type, operation: ${operation?.id}, error: $error)';
}

extension on Iterable<PendingOperation> {
  PendingOperation? get firstOrNull {
    return isEmpty ? null : first;
  }
}