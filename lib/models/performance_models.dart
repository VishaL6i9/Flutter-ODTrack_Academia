import 'package:json_annotation/json_annotation.dart';

part 'performance_models.g.dart';

/// Performance metrics model
@JsonSerializable()
class PerformanceMetrics {
  final Duration appLaunchTime;
  final Duration screenTransitionTime;
  final double memoryUsage; // in MB
  final double cpuUsage; // percentage
  final int frameDropCount;
  final Duration networkResponseTime;
  final DateTime timestamp;

  const PerformanceMetrics({
    required this.appLaunchTime,
    required this.screenTransitionTime,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.frameDropCount,
    required this.networkResponseTime,
    required this.timestamp,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$PerformanceMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceMetricsToJson(this);
}

/// Performance alert model
@JsonSerializable()
class PerformanceAlert {
  final String id;
  final PerformanceAlertType type;
  final String message;
  final double threshold;
  final double currentValue;
  final DateTime timestamp;
  final bool isResolved;

  const PerformanceAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.threshold,
    required this.currentValue,
    required this.timestamp,
    this.isResolved = false,
  });

  factory PerformanceAlert.fromJson(Map<String, dynamic> json) =>
      _$PerformanceAlertFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceAlertToJson(this);
}

/// Performance alert type enumeration
enum PerformanceAlertType {
  @JsonValue('memory_high')
  memoryHigh,
  @JsonValue('cpu_high')
  cpuHigh,
  @JsonValue('frame_drops')
  frameDrops,
  @JsonValue('slow_network')
  slowNetwork,
  @JsonValue('slow_launch')
  slowLaunch,
}
