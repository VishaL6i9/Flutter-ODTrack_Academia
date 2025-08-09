import 'package:json_annotation/json_annotation.dart';

part 'notification_message.g.dart';

/// Enumeration for notification types
enum NotificationType {
  @JsonValue('od_status_change')
  odStatusChange,
  @JsonValue('new_od_request')
  newODRequest,
  @JsonValue('reminder')
  reminder,
  @JsonValue('system_update')
  systemUpdate,
  @JsonValue('bulk_operation_complete')
  bulkOperationComplete,
}

/// Enumeration for notification priority levels
enum NotificationPriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

/// Model for push notification messages
@JsonSerializable()
class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final NotificationPriority priority;
  final String? groupId;
  final String? actionUrl;
  @JsonKey(toJson: _actionsToJson, fromJson: _actionsFromJson)
  final List<NotificationAction>? actions;
  final DateTime? expiresAt;

  const NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.priority = NotificationPriority.normal,
    this.groupId,
    this.actionUrl,
    this.actions,
    this.expiresAt,
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) =>
      _$NotificationMessageFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationMessageToJson(this);

  NotificationMessage copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    NotificationPriority? priority,
    String? groupId,
    String? actionUrl,
    List<NotificationAction>? actions,
    DateTime? expiresAt,
  }) {
    return NotificationMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
      groupId: groupId ?? this.groupId,
      actionUrl: actionUrl ?? this.actionUrl,
      actions: actions ?? this.actions,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Check if notification has expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check if notification is actionable
  bool get hasActions => actions != null && actions!.isNotEmpty;

  /// Get display time for notification (relative time)
  String get displayTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// Model for notification actions
@JsonSerializable()
class NotificationAction {
  final String id;
  final String title;
  final String? icon;
  final bool destructive;
  final Map<String, dynamic>? data;

  const NotificationAction({
    required this.id,
    required this.title,
    this.icon,
    this.destructive = false,
    this.data,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) =>
      _$NotificationActionFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationActionToJson(this);
}

// Helper functions for JSON serialization of actions list
List<Map<String, dynamic>>? _actionsToJson(List<NotificationAction>? actions) {
  return actions?.map((action) => action.toJson()).toList();
}

List<NotificationAction>? _actionsFromJson(List<dynamic>? json) {
  return json?.map((item) => NotificationAction.fromJson(item as Map<String, dynamic>)).toList();
}