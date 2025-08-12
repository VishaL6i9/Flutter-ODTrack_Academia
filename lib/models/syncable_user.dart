import 'package:json_annotation/json_annotation.dart';
import 'package:odtrack_academia/models/user.dart';
import 'package:odtrack_academia/models/sync_models.dart';

part 'syncable_user.g.dart';

/// Syncable wrapper for User that implements SyncableItem interface
@JsonSerializable()
class SyncableUser extends User implements SyncableItem {
  @override
  final SyncStatus syncStatus;
  
  @override
  final DateTime lastModified;
  
  final List<SyncConflict> conflicts;

  SyncableUser({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.registerNumber,
    super.department,
    super.year,
    super.section,
    super.phone,
    this.syncStatus = SyncStatus.pending,
    DateTime? lastModified,
    this.conflicts = const [],
  }) : lastModified = lastModified ?? DateTime.now();

  /// Create SyncableUser from regular User
  factory SyncableUser.fromUser(
    User user, {
    SyncStatus syncStatus = SyncStatus.pending,
    DateTime? lastModified,
    List<SyncConflict> conflicts = const [],
  }) {
    return SyncableUser(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      registerNumber: user.registerNumber,
      department: user.department,
      year: user.year,
      section: user.section,
      phone: user.phone,
      syncStatus: syncStatus,
      lastModified: lastModified ?? DateTime.now(),
      conflicts: conflicts,
    );
  }

  factory SyncableUser.fromJson(Map<String, dynamic> json) =>
      _$SyncableUserFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SyncableUserToJson(this);

  @override
  SyncableItem fromJson(Map<String, dynamic> json) =>
      SyncableUser.fromJson(json);

  /// Create a copy with updated sync information
  SyncableUser copyWithSync({
    SyncStatus? syncStatus,
    DateTime? lastModified,
    List<SyncConflict>? conflicts,
  }) {
    return SyncableUser(
      id: id,
      name: name,
      email: email,
      role: role,
      registerNumber: registerNumber,
      department: department,
      year: year,
      section: section,
      phone: phone,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModified: lastModified ?? this.lastModified,
      conflicts: conflicts ?? this.conflicts,
    );
  }

  /// Create a copy with updated user data
  SyncableUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? registerNumber,
    String? department,
    String? year,
    String? section,
    String? phone,
    SyncStatus? syncStatus,
    DateTime? lastModified,
    List<SyncConflict>? conflicts,
  }) {
    return SyncableUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      registerNumber: registerNumber ?? this.registerNumber,
      department: department ?? this.department,
      year: year ?? this.year,
      section: section ?? this.section,
      phone: phone ?? this.phone,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModified: lastModified ?? this.lastModified,
      conflicts: conflicts ?? this.conflicts,
    );
  }

  /// Convert to regular User
  User toUser() {
    return User(
      id: id,
      name: name,
      email: email,
      role: role,
      registerNumber: registerNumber,
      department: department,
      year: year,
      section: section,
      phone: phone,
    );
  }

  /// Check if this user needs to be synced
  bool get needsSync => syncStatus == SyncStatus.pending || 
                       syncStatus == SyncStatus.failed;

  /// Check if this user has unresolved conflicts
  bool get hasConflicts => conflicts.isNotEmpty;

  /// Check if sync is in progress
  bool get isSyncing => syncStatus == SyncStatus.inProgress;

  /// Check if sync is completed
  bool get isSynced => syncStatus == SyncStatus.completed;

  /// Get sync priority (user data typically has lower priority than OD requests)
  int get syncPriority {
    int basePriority = 3; // Lower than OD requests
    
    // Boost priority for staff users
    if (isStaff) basePriority += 1;
    
    return basePriority.clamp(1, 10);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncableUser &&
           other.id == id &&
           other.syncStatus == syncStatus &&
           other.lastModified == lastModified;
  }

  @override
  int get hashCode => Object.hash(id, syncStatus, lastModified);

  @override
  String toString() {
    return 'SyncableUser(id: $id, name: $name, role: $role, syncStatus: $syncStatus, '
           'lastModified: $lastModified, conflicts: ${conflicts.length})';
  }
}