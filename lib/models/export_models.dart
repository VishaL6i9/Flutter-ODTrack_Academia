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
}

/// Export progress model
@JsonSerializable()
class ExportProgress {
  final String exportId;
  final double progress; // 0.0 to 1.0
  final String currentStep;
  final String? message;

  const ExportProgress({
    required this.exportId,
    required this.progress,
    required this.currentStep,
    this.message,
  });

  factory ExportProgress.fromJson(Map<String, dynamic> json) =>
      _$ExportProgressFromJson(json);

  Map<String, dynamic> toJson() => _$ExportProgressToJson(this);
}