import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'bulk_operation_models.g.dart';

/// Bulk operation result model
@JsonSerializable()
@HiveType(typeId: 10)
class BulkOperationResult {
  @HiveField(0)
  final String operationId;
  @HiveField(1)
  final BulkOperationType type;
  @HiveField(2)
  final int totalItems;
  @HiveField(3)
  final int successfulItems;
  @HiveField(4)
  final int failedItems;
  @HiveField(5)
  final List<String> errors;
  @HiveField(6)
  final DateTime startTime;
  @HiveField(7)
  final DateTime? endTime;
  @HiveField(8)
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
@HiveType(typeId: 11)
enum BulkOperationType {
  @JsonValue('approval')
  @HiveField(0)
  approval,
  @JsonValue('rejection')
  @HiveField(1)
  rejection,
  @JsonValue('export')
  @HiveField(2)
  export,
}
