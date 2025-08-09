import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'analytics_models.g.dart';

/// Date range model for analytics filtering
@JsonSerializable()
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({
    required this.startDate,
    required this.endDate,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFromJson(json);

  Map<String, dynamic> toJson() => _$DateRangeToJson(this);
}

/// Analytics filter model
@JsonSerializable()
class AnalyticsFilter {
  final DateRange? dateRange;
  final String? department;
  final String? year;
  final List<String>? statuses;
  final String? staffId;
  final String? studentId;

  const AnalyticsFilter({
    this.dateRange,
    this.department,
    this.year,
    this.statuses,
    this.staffId,
    this.studentId,
  });

  factory AnalyticsFilter.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsFilterFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsFilterToJson(this);
}

/// Main analytics data model
@JsonSerializable()
class AnalyticsData {
  final int totalRequests;
  final int approvedRequests;
  final int rejectedRequests;
  final int pendingRequests;
  final double approvalRate;
  final Map<String, int> requestsByMonth;
  final Map<String, int> requestsByDepartment;
  final List<RejectionReason> topRejectionReasons;
  final List<RequestPattern> patterns;

  const AnalyticsData({
    required this.totalRequests,
    required this.approvedRequests,
    required this.rejectedRequests,
    required this.pendingRequests,
    required this.approvalRate,
    required this.requestsByMonth,
    required this.requestsByDepartment,
    required this.topRejectionReasons,
    required this.patterns,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsDataFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsDataToJson(this);
}

/// Department analytics model
@JsonSerializable()
class DepartmentAnalytics {
  final String departmentName;
  final int totalRequests;
  final double approvalRate;
  final Map<String, int> requestsByStatus;
  final List<String> topStudents;

  const DepartmentAnalytics({
    required this.departmentName,
    required this.totalRequests,
    required this.approvalRate,
    required this.requestsByStatus,
    required this.topStudents,
  });

  factory DepartmentAnalytics.fromJson(Map<String, dynamic> json) =>
      _$DepartmentAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$DepartmentAnalyticsToJson(this);
}

/// Student analytics model
@JsonSerializable()
class StudentAnalytics {
  final String studentId;
  final String studentName;
  final int totalRequests;
  final int approvedRequests;
  final int rejectedRequests;
  final double approvalRate;
  final List<String> frequentReasons;

  const StudentAnalytics({
    required this.studentId,
    required this.studentName,
    required this.totalRequests,
    required this.approvedRequests,
    required this.rejectedRequests,
    required this.approvalRate,
    required this.frequentReasons,
  });

  factory StudentAnalytics.fromJson(Map<String, dynamic> json) =>
      _$StudentAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$StudentAnalyticsToJson(this);
}

/// Staff analytics model
@JsonSerializable()
class StaffAnalytics {
  final String staffId;
  final String staffName;
  final int requestsProcessed;
  final int requestsApproved;
  final int requestsRejected;
  final double averageProcessingTime;
  final List<String> commonRejectionReasons;

  const StaffAnalytics({
    required this.staffId,
    required this.staffName,
    required this.requestsProcessed,
    required this.requestsApproved,
    required this.requestsRejected,
    required this.averageProcessingTime,
    required this.commonRejectionReasons,
  });

  factory StaffAnalytics.fromJson(Map<String, dynamic> json) =>
      _$StaffAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$StaffAnalyticsToJson(this);
}

/// Chart data model for visualization
@JsonSerializable()
class ChartData {
  final String label;
  final double value;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Color? color;
  final DateTime? timestamp;

  const ChartData({
    required this.label,
    required this.value,
    this.color,
    this.timestamp,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) =>
      _$ChartDataFromJson(json);

  Map<String, dynamic> toJson() => _$ChartDataToJson(this);
}

/// Trend data model
@JsonSerializable()
class TrendData {
  final String label;
  final List<DataPoint> dataPoints;
  final TrendDirection direction;
  final double changePercentage;

  const TrendData({
    required this.label,
    required this.dataPoints,
    required this.direction,
    required this.changePercentage,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) =>
      _$TrendDataFromJson(json);

  Map<String, dynamic> toJson() => _$TrendDataToJson(this);
}

/// Data point model for trends
@JsonSerializable()
class DataPoint {
  final DateTime timestamp;
  final double value;

  const DataPoint({
    required this.timestamp,
    required this.value,
  });

  factory DataPoint.fromJson(Map<String, dynamic> json) =>
      _$DataPointFromJson(json);

  Map<String, dynamic> toJson() => _$DataPointToJson(this);
}

/// Rejection reason model
@JsonSerializable()
class RejectionReason {
  final String reason;
  final int count;
  final double percentage;

  const RejectionReason({
    required this.reason,
    required this.count,
    required this.percentage,
  });

  factory RejectionReason.fromJson(Map<String, dynamic> json) =>
      _$RejectionReasonFromJson(json);

  Map<String, dynamic> toJson() => _$RejectionReasonToJson(this);
}

/// Request pattern model
@JsonSerializable()
class RequestPattern {
  final String pattern;
  final String description;
  final double confidence;

  const RequestPattern({
    required this.pattern,
    required this.description,
    required this.confidence,
  });

  factory RequestPattern.fromJson(Map<String, dynamic> json) =>
      _$RequestPatternFromJson(json);

  Map<String, dynamic> toJson() => _$RequestPatternToJson(this);
}

/// Export data model
@JsonSerializable()
class ExportData {
  final String title;
  final Map<String, dynamic> data;
  final List<ChartData> chartData;
  final DateTime generatedAt;

  const ExportData({
    required this.title,
    required this.data,
    required this.chartData,
    required this.generatedAt,
  });

  factory ExportData.fromJson(Map<String, dynamic> json) =>
      _$ExportDataFromJson(json);

  Map<String, dynamic> toJson() => _$ExportDataToJson(this);
}

/// Enumerations
enum AnalyticsType {
  @JsonValue('requests')
  requests,
  @JsonValue('approvals')
  approvals,
  @JsonValue('departments')
  departments,
  @JsonValue('students')
  students,
}

enum ChartType {
  @JsonValue('bar')
  bar,
  @JsonValue('line')
  line,
  @JsonValue('pie')
  pie,
  @JsonValue('area')
  area,
}

enum TrendDirection {
  @JsonValue('up')
  up,
  @JsonValue('down')
  down,
  @JsonValue('stable')
  stable,
}
