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
    );
  }
}