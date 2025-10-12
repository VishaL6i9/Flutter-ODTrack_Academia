import 'dart:io';
import 'package:json_annotation/json_annotation.dart';

part 'export_models.g.dart';

/// Export format enumeration
enum ExportFormat {
  @JsonValue('pdf')
  pdf,
  @JsonValue('csv')
  csv,
  @JsonValue('excel')
  excel,
}

/// Export options model
@JsonSerializable()
class ExportOptions {
  final ExportFormat format;
  final bool includeCharts;
  final bool includeMetadata;
  final String? customTitle;
  final Map<String, dynamic>? customData;

  const ExportOptions({
    required this.format,
    this.includeCharts = true,
    this.includeMetadata = true,
    this.customTitle,
    this.customData,
  });

  factory ExportOptions.fromJson(Map<String, dynamic> json) =>
      _$ExportOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$ExportOptionsToJson(this);
}

/// Export result model
@JsonSerializable()
class ExportResult {
  final String id;
  final String fileName;
  final String filePath;
  final ExportFormat format;
  final int fileSize;
  final DateTime createdAt;
  final bool success;
  final String? errorMessage;

  const ExportResult({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.format,
    required this.fileSize,
    required this.createdAt,
    required this.success,
    this.errorMessage,
  });

  factory ExportResult.fromJson(Map<String, dynamic> json) =>
      _$ExportResultFromJson(json);

  Map<String, dynamic> toJson() => _$ExportResultToJson(this);

  /// Create a copy with updated values
  ExportResult copyWith({
    String? id,
    String? fileName,
    String? filePath,
    ExportFormat? format,
    int? fileSize,
    DateTime? createdAt,
    bool? success,
    String? errorMessage,
  }) {
    return ExportResult(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      format: format ?? this.format,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if file exists
  Future<bool> get fileExists async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}

/// Export history filter model
@JsonSerializable()
class ExportHistoryFilter {
  final ExportFormat? format;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? successOnly;
  final String? searchQuery;

  const ExportHistoryFilter({
    this.format,
    this.startDate,
    this.endDate,
    this.successOnly,
    this.searchQuery,
  });

  factory ExportHistoryFilter.fromJson(Map<String, dynamic> json) =>
      _$ExportHistoryFilterFromJson(json);

  Map<String, dynamic> toJson() => _$ExportHistoryFilterToJson(this);

  /// Create a copy with updated values
  ExportHistoryFilter copyWith({
    ExportFormat? format,
    DateTime? startDate,
    DateTime? endDate,
    bool? successOnly,
    String? searchQuery,
  }) {
    return ExportHistoryFilter(
      format: format ?? this.format,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      successOnly: successOnly ?? this.successOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Check if any filters are applied
  bool get hasFilters =>
      format != null ||
      startDate != null ||
      endDate != null ||
      successOnly != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);
}

/// Export statistics model
@JsonSerializable()
class ExportStatistics {
  final int totalExports;
  final int successfulExports;
  final int failedExports;
  final Map<ExportFormat, int> exportsByFormat;
  final double averageFileSize;
  final DateTime? lastExportDate;
  final int exportsThisMonth;
  final int exportsThisWeek;

  const ExportStatistics({
    required this.totalExports,
    required this.successfulExports,
    required this.failedExports,
    required this.exportsByFormat,
    required this.averageFileSize,
    this.lastExportDate,
    required this.exportsThisMonth,
    required this.exportsThisWeek,
  });

  factory ExportStatistics.fromJson(Map<String, dynamic> json) =>
      _$ExportStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$ExportStatisticsToJson(this);

  /// Calculate success rate
  double get successRate =>
      totalExports > 0 ? (successfulExports / totalExports) * 100 : 0.0;

  /// Get formatted average file size
  String get formattedAverageFileSize {
    if (averageFileSize < 1024) return '${averageFileSize.toInt()} B';
    if (averageFileSize < 1024 * 1024) {
      return '${(averageFileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(averageFileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Export progress model
@JsonSerializable()
class ExportProgress {
  final String exportId;
  final double progress; // 0.0 to 1.0
  final String currentStep;
  final String? message;
  final DateTime timestamp;
  final int? totalItems;
  final int? processedItems;
  final Duration? estimatedTimeRemaining;
  final bool isCancellable;

  const ExportProgress({
    required this.exportId,
    required this.progress,
    required this.currentStep,
    this.message,
    required this.timestamp,
    this.totalItems,
    this.processedItems,
    this.estimatedTimeRemaining,
    this.isCancellable = true,
  });

  factory ExportProgress.fromJson(Map<String, dynamic> json) =>
      _$ExportProgressFromJson(json);

  Map<String, dynamic> toJson() => _$ExportProgressToJson(this);

  /// Create a copy with updated values
  ExportProgress copyWith({
    String? exportId,
    double? progress,
    String? currentStep,
    String? message,
    DateTime? timestamp,
    int? totalItems,
    int? processedItems,
    Duration? estimatedTimeRemaining,
    bool? isCancellable,
  }) {
    return ExportProgress(
      exportId: exportId ?? this.exportId,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
      estimatedTimeRemaining: estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      isCancellable: isCancellable ?? this.isCancellable,
    );
  }

  /// Calculate progress percentage as string
  String get progressPercentage => '${(progress * 100).toInt()}%';

  /// Check if export is completed
  bool get isCompleted => progress >= 1.0;

  /// Check if export is in progress
  bool get isInProgress => progress > 0.0 && progress < 1.0;
}
