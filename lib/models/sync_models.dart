import 'dart:math';
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

/// Enhanced sync queue item model
@JsonSerializable()
class SyncQueueItem {
  final String id;
  final String itemId;
  final String itemType;
  final String operation; // 'create', 'update', 'delete'
  final Map<String, dynamic> data;
  final DateTime queuedAt;
  final int retryCount;
  final DateTime? lastRetryAt;
  final SyncStatus status;
  final String? errorMessage;

  const SyncQueueItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.operation,
    required this.data,
    required this.queuedAt,
    this.retryCount = 0,
    this.lastRetryAt,
    this.status = SyncStatus.pending,
    this.errorMessage,
  });

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) =>
      _$SyncQueueItemFromJson(json);

  Map<String, dynamic> toJson() => _$SyncQueueItemToJson(this);

  SyncQueueItem copyWith({
    String? id,
    String? itemId,
    String? itemType,
    String? operation,
    Map<String, dynamic>? data,
    DateTime? queuedAt,
    int? retryCount,
    DateTime? lastRetryAt,
    SyncStatus? status,
    String? errorMessage,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Cache metadata model for intelligent cache management
@JsonSerializable()
class CacheMetadata {
  final String key;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final DateTime? expiresAt;
  final int accessCount;
  final int sizeBytes;
  final String? etag;
  final Map<String, dynamic>? metadata;

  const CacheMetadata({
    required this.key,
    required this.createdAt,
    required this.lastAccessedAt,
    this.expiresAt,
    this.accessCount = 1,
    this.sizeBytes = 0,
    this.etag,
    this.metadata,
  });

  factory CacheMetadata.fromJson(Map<String, dynamic> json) =>
      _$CacheMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$CacheMetadataToJson(this);

  CacheMetadata copyWith({
    String? key,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    DateTime? expiresAt,
    int? accessCount,
    int? sizeBytes,
    String? etag,
    Map<String, dynamic>? metadata,
  }) {
    return CacheMetadata(
      key: key ?? this.key,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      accessCount: accessCount ?? this.accessCount,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      etag: etag ?? this.etag,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if cache item has expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Get cache priority based on access patterns
  int get priority {
    final age = DateTime.now().difference(lastAccessedAt).inHours;
    final accessFrequency = accessCount / max(1, age);
    return (accessFrequency * 100).round();
  }
}

/// Sync statistics model
@JsonSerializable()
class SyncStatistics {
  final int totalItemsSynced;
  final int itemsSucceeded;
  final int itemsFailed;
  final int conflictsResolved;
  final DateTime lastSyncTime;
  final Duration averageSyncDuration;
  final Map<String, int> syncsByType;

  const SyncStatistics({
    required this.totalItemsSynced,
    required this.itemsSucceeded,
    required this.itemsFailed,
    required this.conflictsResolved,
    required this.lastSyncTime,
    required this.averageSyncDuration,
    required this.syncsByType,
  });

  factory SyncStatistics.fromJson(Map<String, dynamic> json) =>
      _$SyncStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$SyncStatisticsToJson(this);

  double get successRate => totalItemsSynced > 0 ? itemsSucceeded / totalItemsSynced : 0.0;
}
