import 'package:json_annotation/json_annotation.dart';

part 'sync_models.g.dart';

/// Enumeration for sync status
enum SyncStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('conflict')
  conflict,
}

/// Abstract base class for syncable items
abstract class SyncableItem {
  String get id;
  DateTime get lastModified;
  SyncStatus get syncStatus;
  Map<String, dynamic> toJson();
  SyncableItem fromJson(Map<String, dynamic> json);
}

/// Model for sync operation results
@JsonSerializable()
class SyncResult {
  final bool success;
  final int itemsSynced;
  final int itemsFailed;
  final List<String> errors;
  final DateTime timestamp;
  final Duration duration;

  const SyncResult({
    required this.success,
    required this.itemsSynced,
    required this.itemsFailed,
    required this.errors,
    required this.timestamp,
    required this.duration,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) =>
      _$SyncResultFromJson(json);

  Map<String, dynamic> toJson() => _$SyncResultToJson(this);
}

/// Model for sync conflicts
@JsonSerializable()
class SyncConflict {
  final String itemId;
  final String itemType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final DateTime localTimestamp;
  final DateTime serverTimestamp;

  const SyncConflict({
    required this.itemId,
    required this.itemType,
    required this.localData,
    required this.serverData,
    required this.localTimestamp,
    required this.serverTimestamp,
  });

  factory SyncConflict.fromJson(Map<String, dynamic> json) =>
      _$SyncConflictFromJson(json);

  Map<String, dynamic> toJson() => _$SyncConflictToJson(this);
}

/// Model for conflict resolution
@JsonSerializable()
class ConflictResolution {
  final String conflictId;
  final String resolution; // 'use_local', 'use_server', 'merge'
  final Map<String, dynamic>? mergedData;

  const ConflictResolution({
    required this.conflictId,
    required this.resolution,
    this.mergedData,
  });

  factory ConflictResolution.fromJson(Map<String, dynamic> json) =>
      _$ConflictResolutionFromJson(json);

  Map<String, dynamic> toJson() => _$ConflictResolutionToJson(this);
}