import 'package:odtrack_academia/core/errors/base_error.dart';

/// Bulk operation specific errors
class BulkOperationError extends BaseError {
  final String? operationId;
  final int? processedItems;
  final int? totalItems;

  BulkOperationError({
    required super.code,
    required super.message,
    super.userMessage,
    super.context,
    super.timestamp,
    super.isRetryable = false,
    super.severity = ErrorSeverity.medium,
    super.stackTrace,
    this.operationId,
    this.processedItems,
    this.totalItems,
  }) : super(
          category: ErrorCategory.unknown, // Using unknown as bulk operations span multiple categories
        );

  factory BulkOperationError.operationCancelled(String operationId) {
    return BulkOperationError(
      code: 'BULK_OPERATION_CANCELLED',
      message: 'Bulk operation was cancelled: $operationId',
      userMessage: 'Operation was cancelled by user.',
      operationId: operationId,
      isRetryable: false,
      severity: ErrorSeverity.low,
    );
  }

  factory BulkOperationError.batchSizeExceeded(int requestedSize, int maxSize) {
    return BulkOperationError(
      code: 'BATCH_SIZE_EXCEEDED',
      message: 'Batch size $requestedSize exceeds maximum allowed size $maxSize',
      userMessage: 'Too many items selected. Maximum allowed is $maxSize items.',
      isRetryable: false,
      severity: ErrorSeverity.medium,
    );
  }

  factory BulkOperationError.operationInProgress(String operationId) {
    return BulkOperationError(
      code: 'OPERATION_IN_PROGRESS',
      message: 'Another bulk operation is already in progress: $operationId',
      userMessage: 'Another operation is in progress. Please wait for it to complete.',
      operationId: operationId,
      isRetryable: true,
      severity: ErrorSeverity.medium,
    );
  }

  factory BulkOperationError.partialFailure(
    String operationId,
    int successfulItems,
    int failedItems,
    List<String> errors,
  ) {
    return BulkOperationError(
      code: 'PARTIAL_FAILURE',
      message: 'Bulk operation partially failed: $successfulItems successful, $failedItems failed',
      userMessage: 'Operation completed with some failures. $successfulItems items processed successfully, $failedItems failed.',
      operationId: operationId,
      processedItems: successfulItems,
      totalItems: successfulItems + failedItems,
      context: {'errors': errors},
      isRetryable: false,
      severity: ErrorSeverity.medium,
    );
  }

  factory BulkOperationError.undoNotAvailable(String operationId, String reason) {
    return BulkOperationError(
      code: 'UNDO_NOT_AVAILABLE',
      message: 'Undo not available for operation $operationId: $reason',
      userMessage: 'Cannot undo this operation. $reason',
      operationId: operationId,
      isRetryable: false,
      severity: ErrorSeverity.low,
    );
  }

  factory BulkOperationError.undoTimeLimitExceeded(String operationId) {
    return BulkOperationError(
      code: 'UNDO_TIME_LIMIT_EXCEEDED',
      message: 'Undo time limit exceeded for operation: $operationId',
      userMessage: 'Cannot undo this operation. Time limit exceeded.',
      operationId: operationId,
      isRetryable: false,
      severity: ErrorSeverity.low,
    );
  }

  factory BulkOperationError.invalidRequestState(
    String requestId,
    String currentState,
    String requiredState,
  ) {
    return BulkOperationError(
      code: 'INVALID_REQUEST_STATE',
      message: 'Request $requestId is in state $currentState, but $requiredState is required',
      userMessage: 'Some requests cannot be processed due to their current state.',
      context: {
        'requestId': requestId,
        'currentState': currentState,
        'requiredState': requiredState,
      },
      isRetryable: false,
      severity: ErrorSeverity.low,
    );
  }

  factory BulkOperationError.exportFailed(String operationId, String reason) {
    return BulkOperationError(
      code: 'EXPORT_FAILED',
      message: 'Export operation failed: $reason',
      userMessage: 'Export failed. Please try again or check available storage.',
      operationId: operationId,
      isRetryable: true,
      severity: ErrorSeverity.medium,
    );
  }

  factory BulkOperationError.storageError(String operationId, String operation) {
    return BulkOperationError(
      code: 'BULK_STORAGE_ERROR',
      message: 'Storage error during bulk operation: $operation',
      userMessage: 'Storage error occurred. Please check available space and try again.',
      operationId: operationId,
      isRetryable: true,
      severity: ErrorSeverity.high,
    );
  }
}