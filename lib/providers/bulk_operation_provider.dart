import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/services/bulk_operations/bulk_operation_service.dart';
import 'package:odtrack_academia/services/bulk_operations/hive_bulk_operation_service.dart';
import 'package:odtrack_academia/models/bulk_operation_models.dart';
import 'package:odtrack_academia/models/export_models.dart';

/// Provider for bulk operation service
final bulkOperationServiceProvider = Provider<BulkOperationService>((ref) {
  return HiveBulkOperationService();
});

/// State class for bulk operation management
class BulkOperationState {
  final Set<String> selectedRequestIds;
  final bool isSelectionMode;
  final BulkOperationProgress? currentProgress;
  final BulkOperationResult? lastResult;
  final String? error;
  final bool isOperationInProgress;
  final List<String> failedRequestIds;

  const BulkOperationState({
    this.selectedRequestIds = const {},
    this.isSelectionMode = false,
    this.currentProgress,
    this.lastResult,
    this.error,
    this.isOperationInProgress = false,
    this.failedRequestIds = const [],
  });

  BulkOperationState copyWith({
    Set<String>? selectedRequestIds,
    bool? isSelectionMode,
    BulkOperationProgress? currentProgress,
    BulkOperationResult? lastResult,
    String? error,
    bool? isOperationInProgress,
    List<String>? failedRequestIds,
    bool clearError = false,
    bool clearProgress = false,
    bool clearLastResult = false,
    bool clearFailedRequestIds = false,
  }) {
    return BulkOperationState(
      selectedRequestIds: selectedRequestIds ?? this.selectedRequestIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      currentProgress: clearProgress ? null : (currentProgress ?? this.currentProgress),
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      error: clearError ? null : (error ?? this.error),
      isOperationInProgress: isOperationInProgress ?? this.isOperationInProgress,
      failedRequestIds: clearFailedRequestIds ? [] : (failedRequestIds ?? this.failedRequestIds),
    );
  }

  bool get hasSelection => selectedRequestIds.isNotEmpty;
  int get selectionCount => selectedRequestIds.length;
}

/// Provider for bulk operation state management
class BulkOperationNotifier extends StateNotifier<BulkOperationState> {
  final BulkOperationService _bulkOperationService;

  BulkOperationNotifier(this._bulkOperationService) : super(const BulkOperationState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _bulkOperationService.initialize();
    
    // Listen to progress updates
    _bulkOperationService.progressStream.listen(
      (progress) {
        state = state.copyWith(currentProgress: progress);
      },
      onError: (Object error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  /// Toggle selection mode
  void toggleSelectionMode() {
    if (state.isSelectionMode) {
      // Exit selection mode and clear selections
      state = state.copyWith(
        isSelectionMode: false,
        selectedRequestIds: {},
      );
    } else {
      // Enter selection mode
      state = state.copyWith(isSelectionMode: true);
    }
  }

  /// Toggle selection of a specific request
  void toggleRequestSelection(String requestId) {
    final newSelection = Set<String>.from(state.selectedRequestIds);
    
    if (newSelection.contains(requestId)) {
      newSelection.remove(requestId);
    } else {
      newSelection.add(requestId);
    }
    
    state = state.copyWith(selectedRequestIds: newSelection);
  }

  /// Select all requests from the provided list
  void selectAll(List<String> requestIds) {
    state = state.copyWith(
      selectedRequestIds: Set<String>.from(requestIds),
    );
  }

  /// Clear all selections
  void clearSelection() {
    state = state.copyWith(selectedRequestIds: {});
  }

  /// Check if a request is selected
  bool isRequestSelected(String requestId) {
    return state.selectedRequestIds.contains(requestId);
  }

  /// Perform bulk approval
  Future<void> performBulkApproval(String reason) async {
    if (state.selectedRequestIds.isEmpty) return;

    try {
      state = state.copyWith(
        clearError: true,
        isOperationInProgress: true,
        clearFailedRequestIds: true,
      );
      
      final result = await _bulkOperationService.performBulkApproval(
        state.selectedRequestIds.toList(),
        reason,
      );
      
      // Extract failed request IDs from errors
      final failedIds = _extractFailedRequestIds(result.errors);
      
      state = state.copyWith(
        lastResult: result,
        selectedRequestIds: {},
        isSelectionMode: false,
        isOperationInProgress: false,
        failedRequestIds: failedIds,
        clearProgress: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isOperationInProgress: false,
      );
    }
  }

  /// Perform bulk rejection
  Future<void> performBulkRejection(String reason) async {
    if (state.selectedRequestIds.isEmpty) return;

    try {
      state = state.copyWith(
        clearError: true,
        isOperationInProgress: true,
        clearFailedRequestIds: true,
      );
      
      final result = await _bulkOperationService.performBulkRejection(
        state.selectedRequestIds.toList(),
        reason,
      );
      
      // Extract failed request IDs from errors
      final failedIds = _extractFailedRequestIds(result.errors);
      
      state = state.copyWith(
        lastResult: result,
        selectedRequestIds: {},
        isSelectionMode: false,
        isOperationInProgress: false,
        failedRequestIds: failedIds,
        clearProgress: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isOperationInProgress: false,
      );
    }
  }

  /// Perform bulk export
  Future<void> performBulkExport(ExportFormat format) async {
    if (state.selectedRequestIds.isEmpty) return;

    try {
      state = state.copyWith(
        clearError: true,
        isOperationInProgress: true,
        clearFailedRequestIds: true,
      );
      
      final result = await _bulkOperationService.performBulkExport(
        state.selectedRequestIds.toList(),
        format,
      );
      
      // Extract failed request IDs from errors
      final failedIds = _extractFailedRequestIds(result.errors);
      
      state = state.copyWith(
        lastResult: result,
        selectedRequestIds: {},
        isSelectionMode: false,
        isOperationInProgress: false,
        failedRequestIds: failedIds,
        clearProgress: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isOperationInProgress: false,
      );
    }
  }

  /// Cancel current bulk operation
  Future<void> cancelCurrentOperation() async {
    if (state.currentProgress != null) {
      await _bulkOperationService.cancelBulkOperation(state.currentProgress!.operationId);
      state = state.copyWith(clearProgress: true);
    }
  }

  /// Undo last bulk operation
  Future<bool> undoLastOperation() async {
    try {
      final success = await _bulkOperationService.undoLastBulkOperation();
      if (success) {
        state = state.copyWith(clearLastResult: true);
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Retry failed requests from the last operation
  Future<void> retryFailedRequests() async {
    if (state.failedRequestIds.isEmpty || state.lastResult == null) return;

    final lastResult = state.lastResult!;
    
    // Determine the operation type and retry with the same parameters
    switch (lastResult.type) {
      case BulkOperationType.approval:
        // For retry, we'll use a generic approval reason
        await performBulkApproval('Retry bulk approval');
        break;
      case BulkOperationType.rejection:
        // For retry, we'll need to prompt for rejection reason again
        // This should be handled by the UI layer
        break;
      case BulkOperationType.export:
        // For retry, we'll use PDF format as default
        await performBulkExport(ExportFormat.pdf);
        break;
    }
  }

  /// Select only the failed requests from the last operation
  void selectFailedRequests() {
    if (state.failedRequestIds.isNotEmpty) {
      state = state.copyWith(
        selectedRequestIds: Set<String>.from(state.failedRequestIds),
        isSelectionMode: true,
      );
    }
  }

  /// Get operation history
  Future<List<BulkOperationResult>> getOperationHistory() async {
    try {
      return await _bulkOperationService.getBulkOperationHistory();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Check if an operation can be undone
  Future<bool> canUndoOperation(String operationId) async {
    try {
      return await _bulkOperationService.canUndoBulkOperation(operationId);
    } catch (e) {
      return false;
    }
  }

  /// Extract failed request IDs from error messages
  List<String> _extractFailedRequestIds(List<String> errors) {
    final failedIds = <String>[];
    
    for (final error in errors) {
      // Look for patterns like "Failed to process request: request_id"
      final match = RegExp(r'request[:\s]+([a-zA-Z0-9_-]+)').firstMatch(error);
      if (match != null && match.group(1) != null) {
        failedIds.add(match.group(1)!);
      }
    }
    
    return failedIds;
  }
}

/// Provider for bulk operation notifier
final bulkOperationProvider = StateNotifierProvider<BulkOperationNotifier, BulkOperationState>((ref) {
  final service = ref.watch(bulkOperationServiceProvider);
  return BulkOperationNotifier(service);
});