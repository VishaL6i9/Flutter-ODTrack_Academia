import 'package:json_annotation/json_annotation.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/sync_models.dart';

part 'syncable_od_request.g.dart';

/// Syncable wrapper for ODRequest that implements SyncableItem interface
@JsonSerializable()
class SyncableODRequest extends ODRequest implements SyncableItem {
  @override
  final SyncStatus syncStatus;
  
  @override
  final DateTime lastModified;
  
  final List<SyncConflict> conflicts;

  SyncableODRequest({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.registerNumber,
    required super.date,
    required super.periods,
    required super.reason,
    required super.status,
    super.attachmentUrl,
    required super.createdAt,
    super.approvedAt,
    super.approvedBy,
    super.rejectionReason,
    super.staffId,
    this.syncStatus = SyncStatus.pending,
    DateTime? lastModified,
    this.conflicts = const [],
  }) : lastModified = lastModified ?? DateTime.now();

  /// Create SyncableODRequest from regular ODRequest
  factory SyncableODRequest.fromODRequest(
    ODRequest request, {
    SyncStatus syncStatus = SyncStatus.pending,
    DateTime? lastModified,
    List<SyncConflict> conflicts = const [],
  }) {
    return SyncableODRequest(
      id: request.id,
      studentId: request.studentId,
      studentName: request.studentName,
      registerNumber: request.registerNumber,
      date: request.date,
      periods: request.periods,
      reason: request.reason,
      status: request.status,
      attachmentUrl: request.attachmentUrl,
      createdAt: request.createdAt,
      approvedAt: request.approvedAt,
      approvedBy: request.approvedBy,
      rejectionReason: request.rejectionReason,
      staffId: request.staffId,
      syncStatus: syncStatus,
      lastModified: lastModified ?? DateTime.now(),
      conflicts: conflicts,
    );
  }

  factory SyncableODRequest.fromJson(Map<String, dynamic> json) =>
      _$SyncableODRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SyncableODRequestToJson(this);

  @override
  SyncableItem fromJson(Map<String, dynamic> json) =>
      SyncableODRequest.fromJson(json);

  /// Create a copy with updated sync information
  SyncableODRequest copyWithSync({
    SyncStatus? syncStatus,
    DateTime? lastModified,
    List<SyncConflict>? conflicts,
  }) {
    return SyncableODRequest(
      id: id,
      studentId: studentId,
      studentName: studentName,
      registerNumber: registerNumber,
      date: date,
      periods: periods,
      reason: reason,
      status: status,
      attachmentUrl: attachmentUrl,
      createdAt: createdAt,
      approvedAt: approvedAt,
      approvedBy: approvedBy,
      rejectionReason: rejectionReason,
      staffId: staffId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModified: lastModified ?? this.lastModified,
      conflicts: conflicts ?? this.conflicts,
    );
  }

  /// Create a copy with updated OD request data
  SyncableODRequest copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? registerNumber,
    DateTime? date,
    List<int>? periods,
    String? reason,
    String? status,
    String? attachmentUrl,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? approvedBy,
    String? rejectionReason,
    String? staffId,
    SyncStatus? syncStatus,
    DateTime? lastModified,
    List<SyncConflict>? conflicts,
  }) {
    return SyncableODRequest(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      registerNumber: registerNumber ?? this.registerNumber,
      date: date ?? this.date,
      periods: periods ?? this.periods,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      staffId: staffId ?? this.staffId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModified: lastModified ?? this.lastModified,
      conflicts: conflicts ?? this.conflicts,
    );
  }

  /// Convert to regular ODRequest
  ODRequest toODRequest() {
    return ODRequest(
      id: id,
      studentId: studentId,
      studentName: studentName,
      registerNumber: registerNumber,
      date: date,
      periods: periods,
      reason: reason,
      status: status,
      attachmentUrl: attachmentUrl,
      createdAt: createdAt,
      approvedAt: approvedAt,
      approvedBy: approvedBy,
      rejectionReason: rejectionReason,
      staffId: staffId,
    );
  }

  /// Check if this request needs to be synced
  bool get needsSync => syncStatus == SyncStatus.pending || 
                       syncStatus == SyncStatus.failed;

  /// Check if this request has unresolved conflicts
  bool get hasConflicts => conflicts.isNotEmpty;

  /// Check if sync is in progress
  bool get isSyncing => syncStatus == SyncStatus.inProgress;

  /// Check if sync is completed
  bool get isSynced => syncStatus == SyncStatus.completed;

  /// Get sync priority based on status and age
  int get syncPriority {
    // Higher priority for newer requests and certain statuses
    final ageInHours = DateTime.now().difference(createdAt).inHours;
    int basePriority = 5;
    
    // Boost priority for pending requests
    if (status == 'pending') basePriority += 3;
    
    // Boost priority for newer requests
    if (ageInHours < 1) {
      basePriority += 2;
    } else if (ageInHours < 24) {
      basePriority += 1;
    }
    
    // Reduce priority for very old requests
    if (ageInHours > 168) basePriority -= 2; // Older than a week
    
    return basePriority.clamp(1, 10);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncableODRequest &&
           other.id == id &&
           other.syncStatus == syncStatus &&
           other.lastModified == lastModified;
  }

  @override
  int get hashCode => Object.hash(id, syncStatus, lastModified);

  @override
  String toString() {
    return 'SyncableODRequest(id: $id, status: $status, syncStatus: $syncStatus, '
           'lastModified: $lastModified, conflicts: ${conflicts.length})';
  }
}