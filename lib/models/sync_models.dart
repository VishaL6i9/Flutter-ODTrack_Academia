import 'dart:math';
import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'sync_models.g.dart';

/// Enumeration for sync status
@HiveType(typeId: 102)
enum SyncStatus {
  @JsonValue('pending')
  @HiveField(0)
  pending,
  @JsonValue('in_progress')
  @HiveField(1)
  inProgress,
  @JsonValue('completed')
  @HiveField(2)
  completed,
  @JsonValue('failed')
  @HiveField(3)
  failed,
  @JsonValue('conflict')
  @HiveField(4)
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
@HiveType(typeId: 201)
class SyncResult {
  @HiveField(0)
  final bool success;
  @HiveField(1)
  final int itemsSynced;
  @HiveField(2)
  final int itemsFailed;
  @HiveField(3)
  final List<String> errors;
  @HiveField(4)
  final DateTime timestamp;
  @HiveField(5)
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
@HiveType(typeId: 202)
class SyncConflict {
  @HiveField(0)
  final String itemId;
  @HiveField(1)
  final String itemType;
  @HiveField(2)
  final Map<String, dynamic> localData;
  @HiveField(3)
  final Map<String, dynamic> serverData;
  @HiveField(4)
  final DateTime localTimestamp;
  @HiveField(5)
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
@HiveType(typeId: 203)
class ConflictResolution {
  @HiveField(0)
  final String conflictId;
  @HiveField(1)
  final String resolution; // 'use_local', 'use_server', 'merge'
  @HiveField(2)
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
@HiveType(typeId: 214)
class SyncQueueItem {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String itemId;
  @HiveField(2)
  final String itemType;
  @HiveField(3)
  final String operation; // 'create', 'update', 'delete'
  @HiveField(4)
  final Map<String, dynamic> data;
  @HiveField(5)
  final DateTime queuedAt;
  @HiveField(6)
  final int retryCount;
  @HiveField(7)
  final DateTime? lastRetryAt;
  @HiveField(8)
  final SyncStatus status;
  @HiveField(9)
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
@HiveType(typeId: 215)
class CacheMetadata {
  @HiveField(0)
  final String key;
  @HiveField(1)
  final DateTime createdAt;
  @HiveField(2)
  final DateTime lastAccessedAt;
  @HiveField(3)
  final DateTime? expiresAt;
  @HiveField(4)
  final int accessCount;
  @HiveField(5)
  final int sizeBytes;
  @HiveField(6)
  final String? etag;
  @HiveField(7)
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
@HiveType(typeId: 216)
class SyncStatistics {
  @HiveField(0)
  final int totalItemsSynced;
  @HiveField(1)
  final int itemsSucceeded;
  @HiveField(2)
  final int itemsFailed;
  @HiveField(3)
  final int conflictsResolved;
  @HiveField(4)
  final DateTime lastSyncTime;
  @HiveField(5)
  final Duration averageSyncDuration;
  @HiveField(6)
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
