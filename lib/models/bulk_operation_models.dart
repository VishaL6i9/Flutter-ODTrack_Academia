import 'package:json_annotation/json_annotation.dart';
import 'export_models.dart';

part 'bulk_operation_models.g.dart';

/// Bulk operation result model
@JsonSerializable()
class BulkOperationResult {
  final String operationId;
  final BulkOperationType type;
  final int totalItems;
  final int successfulItems;
  final int failedItems;
  final List<String> errors;
  final DateTime startTime;
  final DateTime? endTime;
  final bool canUndo;

  const BulkOperationResult({
    required this.operationId,
    required this.type,
    required this.totalItems,
    required this.successfulItems,
    required this.failedItems,
    required this.errors,
    required this.startTime,
    this.endTime,
    this.canUndo = false,
  });

  factory BulkOperationResult.fromJson(Map<String, dynamic> json) =>
      _$BulkOperationResultFromJson(json);

  Map<String, dynamic> toJson() => _$BulkOperationResultToJson(this);
}

/// Bulk operation progress model
@JsonSerializable()
class BulkOperationProgress {
  final String operationId;
  final double progress; // 0.0 to 1.0
  final int processedItems;
  final int totalItems;
  final String currentItem;
  final String? message;

  const BulkOperationProgress({
    required this.operationId,
    required this.progress,
    required this.processedItems,
    required this.totalItems,
    required this.currentItem,
    this.message,
  });

  factory BulkOperationProgress.fromJson(Map<String, dynamic> json) =>
      _$BulkOperationProgressFromJson(json);

  Map<String, dynamic> toJson() => _$BulkOperationProgressToJson(this);
}

/// Bulk operation type enumeration
enum BulkOperationType {
  @JsonValue('approval')
  approval,
  @JsonValue('rejection')
  rejection,
  @JsonValue('export')
  export,
}