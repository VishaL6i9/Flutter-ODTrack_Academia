import 'dart:async';
import '../../models/bulk_operation_models.dart';
import '../../models/export_models.dart';

/// Abstract interface for bulk operations service
/// Handles bulk approval, rejection, and export operations
abstract class BulkOperationService {
  /// Initialize the bulk operation service
  Future<void> initialize();
  
  /// Perform bulk approval of OD requests
  Future<BulkOperationResult> performBulkApproval(
    List<String> requestIds,
    String reason,
  );
  
  /// Perform bulk rejection of OD requests
  Future<BulkOperationResult> performBulkRejection(
    List<String> requestIds,
    String reason,
  );
  
  /// Perform bulk export of OD requests
  Future<BulkOperationResult> performBulkExport(
    List<String> requestIds,
    ExportFormat format,
  );
  
  /// Stream of bulk operation progress updates
  Stream<BulkOperationProgress> get progressStream;
  
  /// Cancel ongoing bulk operation
  Future<void> cancelBulkOperation(String operationId);
  
  /// Get bulk operation history
  Future<List<BulkOperationResult>> getBulkOperationHistory();
  
  /// Undo last bulk operation (if possible)
  Future<bool> undoLastBulkOperation();
  
  /// Check if bulk operation can be undone
  Future<bool> canUndoBulkOperation(String operationId);
  
  /// Get maximum batch size for bulk operations
  int get maxBatchSize;
}