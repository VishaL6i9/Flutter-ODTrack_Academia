import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:odtrack_academia/models/bulk_operation_models.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/bulk_operations/bulk_operation_service.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';
import 'package:odtrack_academia/core/errors/error_recovery_service.dart';

/// Concrete implementation of BulkOperationService using Hive storage
/// Handles bulk operations with progress tracking and error recovery
class HiveBulkOperationService implements BulkOperationService {
  static const String _bulkOperationHistoryBox = 'bulk_operation_history';
  static const String _undoDataBox = 'bulk_operation_undo_data';
  static const int _maxBatchSize = 100;
  static const Duration _undoTimeLimit = Duration(minutes: 5);

  final StreamController<BulkOperationProgress> _progressController = 
      StreamController<BulkOperationProgress>.broadcast();
  
  Box<BulkOperationResult>? _historyBox;
  Box<Map<String, dynamic>>? _undoBox;
  Box<ODRequest>? _odRequestsBox;
  
  String? _currentOperationId;
  bool _isOperationCancelled = false;

  @override
  Future<void> initialize() async {
    try {
      _historyBox = await Hive.openBox<BulkOperationResult>(_bulkOperationHistoryBox);
      _undoBox = await Hive.openBox<Map<String, dynamic>>(_undoDataBox);
      _odRequestsBox = await Hive.openBox<ODRequest>('od_requests');
      
      // Clean up old undo data on initialization
      await _cleanupOldUndoData();
    } catch (e) {
      throw StorageError(
        code: 'BULK_OPERATION_INIT_FAILED',
        message: 'Failed to initialize bulk operation service: $e',
        userMessage: 'Failed to initialize bulk operations. Please restart the app.',
        operation: 'initialize',
        severity: ErrorSeverity.high,
      );
    }
  }

  @override
  Stream<BulkOperationProgress> get progressStream => _progressController.stream;

  @override
  int get maxBatchSize => _maxBatchSize;

  @override
  Future<BulkOperationResult> performBulkApproval(
    List<String> requestIds,
    String reason,
  ) async {
    return _performBulkOperation(
      requestIds: requestIds,
      type: BulkOperationType.approval,
      reason: reason,
      operation: _approveRequest,
    );
  }

  @override
  Future<BulkOperationResult> performBulkRejection(
    List<String> requestIds,
    String reason,
  ) async {
    return _performBulkOperation(
      requestIds: requestIds,
      type: BulkOperationType.rejection,
      reason: reason,
      operation: _rejectRequest,
    );
  }

  @override
  Future<BulkOperationResult> performBulkExport(
    List<String> requestIds,
    ExportFormat format,
  ) async {
    return _performBulkOperation(
      requestIds: requestIds,
      type: BulkOperationType.export,
      reason: format.toString(),
      operation: _exportRequest,
    );
  }

  @override
  Future<void> cancelBulkOperation(String operationId) async {
    if (_currentOperationId == operationId) {
      _isOperationCancelled = true;
      debugPrint('Bulk operation cancelled: $operationId');
    }
  }

  @override
  Future<List<BulkOperationResult>> getBulkOperationHistory() async {
    if (_historyBox == null) {
      throw StorageError(
        code: 'BULK_OPERATION_NOT_INITIALIZED',
        message: 'Bulk operation service not initialized',
        userMessage: 'Service not ready. Please try again.',
        operation: 'getBulkOperationHistory',
      );
    }

    try {
      return _historyBox!.values.toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
    } catch (e) {
      throw StorageError(
        code: 'BULK_OPERATION_HISTORY_READ_FAILED',
        message: 'Failed to read bulk operation history: $e',
        userMessage: 'Failed to load operation history.',
        operation: 'getBulkOperationHistory',
      );
    }
  }

  @override
  Future<bool> undoLastBulkOperation() async {
    try {
      final history = await getBulkOperationHistory();
      if (history.isEmpty) return false;

      final lastOperation = history.first;
      return await _undoBulkOperation(lastOperation.operationId);
    } catch (e) {
      debugPrint('Failed to undo last bulk operation: $e');
      return false;
    }
  }

  @override
  Future<bool> canUndoBulkOperation(String operationId) async {
    if (_undoBox == null || _historyBox == null) return false;

    try {
      final undoData = _undoBox!.get(operationId);
      if (undoData == null) return false;

      final operation = _historyBox!.get(operationId);
      if (operation == null || !operation.canUndo) return false;

      // Check if undo time limit has passed
      final timeSinceOperation = DateTime.now().difference(operation.startTime);
      return timeSinceOperation <= _undoTimeLimit;
    } catch (e) {
      debugPrint('Error checking undo capability: $e');
      return false;
    }
  }

  /// Private method to perform bulk operations with common logic
  Future<BulkOperationResult> _performBulkOperation({
    required List<String> requestIds,
    required BulkOperationType type,
    required String reason,
    required Future<bool> Function(String requestId, String reason) operation,
  }) async {
    // Validate input first (before checking initialization)
    if (requestIds.isEmpty) {
      throw ValidationError.invalid(
        'requestIds',
        requestIds,
        'Request IDs list cannot be empty',
      );
    }

    if (requestIds.length > _maxBatchSize) {
      throw ValidationError.invalid(
        'requestIds',
        requestIds.length,
        'Batch size cannot exceed $_maxBatchSize items',
      );
    }

    if (reason.trim().isEmpty) {
      throw ValidationError.required('reason');
    }

    // Check initialization after validation
    if (_odRequestsBox == null) {
      throw StorageError(
        code: 'BULK_OPERATION_NOT_INITIALIZED',
        message: 'Bulk operation service not initialized',
        userMessage: 'Service not ready. Please try again.',
        operation: 'performBulkOperation',
      );
    }

    final operationId = _generateOperationId();
    _currentOperationId = operationId;
    _isOperationCancelled = false;

    final startTime = DateTime.now();
    final errors = <String>[];
    int successfulItems = 0;
    int processedItems = 0;

    // Store original data for undo functionality
    final undoData = <String, Map<String, dynamic>>{};
    
    try {
      // Collect original data for undo
      for (final requestId in requestIds) {
        final request = _odRequestsBox!.get(requestId);
        if (request != null) {
          undoData[requestId] = request.toJson();
        }
      }

      // Store undo data
      if (type != BulkOperationType.export) {
        await _undoBox!.put(operationId, {
          'type': type.toString(),
          'originalData': undoData,
          'timestamp': startTime.toIso8601String(),
        });
      }

      // Process each request
      for (int i = 0; i < requestIds.length; i++) {
        if (_isOperationCancelled) {
          break;
        }

        final requestId = requestIds[i];
        processedItems++;

        // Update progress
        final progress = BulkOperationProgress(
          operationId: operationId,
          progress: processedItems / requestIds.length,
          processedItems: processedItems,
          totalItems: requestIds.length,
          currentItem: requestId,
          message: 'Processing request $processedItems of ${requestIds.length}',
        );
        _progressController.add(progress);

        try {
          // Perform the operation with retry logic
          final success = await ErrorRecoveryService.instance.retryWithBackoff(
            () => operation(requestId, reason),
            maxRetries: 2,
            initialDelay: const Duration(milliseconds: 100),
          );

          if (success) {
            successfulItems++;
          } else {
            errors.add('Failed to process request: $requestId');
          }
        } catch (e) {
          errors.add('Error processing request $requestId: ${e.toString()}');
          debugPrint('Bulk operation error for $requestId: $e');
        }

        // Add small delay to prevent overwhelming the system
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      final endTime = DateTime.now();
      final result = BulkOperationResult(
        operationId: operationId,
        type: type,
        totalItems: requestIds.length,
        successfulItems: successfulItems,
        failedItems: processedItems - successfulItems,
        errors: errors,
        startTime: startTime,
        endTime: endTime,
        canUndo: type != BulkOperationType.export && !_isOperationCancelled,
      );

      // Store operation result in history
      await _historyBox!.put(operationId, result);

      // Send final progress update
      _progressController.add(BulkOperationProgress(
        operationId: operationId,
        progress: 1.0,
        processedItems: processedItems,
        totalItems: requestIds.length,
        currentItem: '',
        message: _isOperationCancelled ? 'Operation cancelled' : 'Operation completed',
      ));

      return result;
    } catch (e) {
      // Clean up undo data on failure
      await _undoBox!.delete(operationId);
      
      final endTime = DateTime.now();
      final result = BulkOperationResult(
        operationId: operationId,
        type: type,
        totalItems: requestIds.length,
        successfulItems: successfulItems,
        failedItems: requestIds.length - successfulItems,
        errors: [...errors, 'Operation failed: ${e.toString()}'],
        startTime: startTime,
        endTime: endTime,
        canUndo: false,
      );

      await _historyBox!.put(operationId, result);
      return result;
    } finally {
      _currentOperationId = null;
      _isOperationCancelled = false;
    }
  }

  /// Approve a single OD request
  Future<bool> _approveRequest(String requestId, String reason) async {
    try {
      final request = _odRequestsBox!.get(requestId);
      if (request == null) {
        throw ValidationError.invalid('requestId', requestId, 'Request not found');
      }

      if (request.status != 'pending') {
        throw ValidationError.invalid(
          'status',
          request.status,
          'Only pending requests can be approved',
        );
      }

      final updatedRequest = ODRequest(
        id: request.id,
        studentId: request.studentId,
        studentName: request.studentName,
        registerNumber: request.registerNumber,
        date: request.date,
        periods: request.periods,
        reason: request.reason,
        status: 'approved',
        attachmentUrl: request.attachmentUrl,
        createdAt: request.createdAt,
        approvedAt: DateTime.now(),
        approvedBy: 'bulk_operation', // In real app, this would be current user ID
        rejectionReason: null,
        staffId: request.staffId,
      );

      await _odRequestsBox!.put(requestId, updatedRequest);
      return true;
    } catch (e) {
      debugPrint('Failed to approve request $requestId: $e');
      return false;
    }
  }

  /// Reject a single OD request
  Future<bool> _rejectRequest(String requestId, String reason) async {
    try {
      final request = _odRequestsBox!.get(requestId);
      if (request == null) {
        throw ValidationError.invalid('requestId', requestId, 'Request not found');
      }

      if (request.status != 'pending') {
        throw ValidationError.invalid(
          'status',
          request.status,
          'Only pending requests can be rejected',
        );
      }

      final updatedRequest = ODRequest(
        id: request.id,
        studentId: request.studentId,
        studentName: request.studentName,
        registerNumber: request.registerNumber,
        date: request.date,
        periods: request.periods,
        reason: request.reason,
        status: 'rejected',
        attachmentUrl: request.attachmentUrl,
        createdAt: request.createdAt,
        approvedAt: null,
        approvedBy: null,
        rejectionReason: reason,
        staffId: request.staffId,
      );

      await _odRequestsBox!.put(requestId, updatedRequest);
      return true;
    } catch (e) {
      debugPrint('Failed to reject request $requestId: $e');
      return false;
    }
  }

  /// Export a single OD request (placeholder implementation)
  Future<bool> _exportRequest(String requestId, String format) async {
    try {
      final request = _odRequestsBox!.get(requestId);
      if (request == null) {
        throw ValidationError.invalid('requestId', requestId, 'Request not found');
      }

      // In a real implementation, this would add the request to an export queue
      // For now, we'll just simulate the export process
      await Future<void>.delayed(const Duration(milliseconds: 100));
      
      debugPrint('Exported request $requestId in format $format');
      return true;
    } catch (e) {
      debugPrint('Failed to export request $requestId: $e');
      return false;
    }
  }

  /// Undo a bulk operation
  Future<bool> _undoBulkOperation(String operationId) async {
    try {
      if (!await canUndoBulkOperation(operationId)) {
        return false;
      }

      final undoData = _undoBox!.get(operationId);
      if (undoData == null) return false;

      final originalData = undoData['originalData'] as Map<String, dynamic>?;
      if (originalData == null) return false;

      // Restore original data
      for (final entry in originalData.entries) {
        final requestId = entry.key;
        final originalRequestData = entry.value as Map<String, dynamic>;
        
        try {
          final originalRequest = ODRequest.fromJson(originalRequestData);
          await _odRequestsBox!.put(requestId, originalRequest);
        } catch (e) {
          debugPrint('Failed to restore request $requestId: $e');
        }
      }

      // Remove undo data after successful undo
      await _undoBox!.delete(operationId);
      
      // Update operation result to mark as undone
      final operation = _historyBox!.get(operationId);
      if (operation != null) {
        final updatedOperation = BulkOperationResult(
          operationId: operation.operationId,
          type: operation.type,
          totalItems: operation.totalItems,
          successfulItems: operation.successfulItems,
          failedItems: operation.failedItems,
          errors: [...operation.errors, 'Operation was undone'],
          startTime: operation.startTime,
          endTime: operation.endTime,
          canUndo: false,
        );
        await _historyBox!.put(operationId, updatedOperation);
      }

      return true;
    } catch (e) {
      debugPrint('Failed to undo bulk operation $operationId: $e');
      return false;
    }
  }

  /// Generate unique operation ID
  String _generateOperationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'bulk_op_${timestamp}_$random';
  }

  /// Clean up old undo data that has exceeded the time limit
  Future<void> _cleanupOldUndoData() async {
    if (_undoBox == null) return;

    try {
      final keysToDelete = <String>[];
      
      for (final key in _undoBox!.keys) {
        final undoData = _undoBox!.get(key);
        if (undoData != null) {
          final timestampStr = undoData['timestamp'] as String?;
          if (timestampStr != null) {
            final timestamp = DateTime.parse(timestampStr);
            final timeSinceOperation = DateTime.now().difference(timestamp);
            
            if (timeSinceOperation > _undoTimeLimit) {
              keysToDelete.add(key.toString());
            }
          }
        }
      }

      for (final key in keysToDelete) {
        await _undoBox!.delete(key);
      }

      if (keysToDelete.isNotEmpty) {
        debugPrint('Cleaned up ${keysToDelete.length} old undo data entries');
      }
    } catch (e) {
      debugPrint('Error during undo data cleanup: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _progressController.close();
  }
}