import 'package:json_annotation/json_annotation.dart';

part 'calendar_models.g.dart';

/// Calendar model
@JsonSerializable()
class Calendar {
  final String id;
  final String name;
  final String? accountName;
  final bool isDefault;
  final bool isReadOnly;

  const Calendar({
    required this.id,
    required this.name,
    this.accountName,
    this.isDefault = false,
    this.isReadOnly = false,
  });

  factory Calendar.fromJson(Map<String, dynamic> json) =>
      _$CalendarFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarToJson(this);
}

/// Calendar event model
@JsonSerializable()
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String calendarId;
  final Map<String, String> metadata;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.calendarId,
    required this.metadata,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarEventToJson(this);
}

/// Calendar sync settings model
@JsonSerializable()
class CalendarSyncSettings {
  final bool autoSyncEnabled;
  final String defaultCalendarId;
  final bool syncApprovedOnly;
  final bool includeRejectedEvents;
  final EventReminderSettings reminderSettings;

  const CalendarSyncSettings({
    required this.autoSyncEnabled,
    required this.defaultCalendarId,
    required this.syncApprovedOnly,
    required this.includeRejectedEvents,
    required this.reminderSettings,
  });

  factory CalendarSyncSettings.fromJson(Map<String, dynamic> json) =>
      _$CalendarSyncSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarSyncSettingsToJson(this);
}

/// Event reminder settings model
@JsonSerializable()
class EventReminderSettings {
  final bool enabled;
  final int minutesBefore;
  final String reminderType; // 'notification', 'email', 'both'

  const EventReminderSettings({
    required this.enabled,
    required this.minutesBefore,
    required this.reminderType,
  });

  factory EventReminderSettings.fromJson(Map<String, dynamic> json) =>
      _$EventReminderSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$EventReminderSettingsToJson(this);
}