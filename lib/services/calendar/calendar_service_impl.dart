import 'dart:async';
import 'dart:io';
import 'package:device_calendar/device_calendar.dart' as device_calendar;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:odtrack_academia/models/calendar_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/calendar/calendar_service.dart';

/// Concrete implementation of CalendarService using device_calendar package
class CalendarServiceImpl implements CalendarService {
  static const String _calendarEventsBoxName = 'calendar_events_box';
  static const String _calendarSettingsBoxName = 'calendar_settings_box';
  static const String _settingsKey = 'calendar_sync_settings';
  
  final device_calendar.DeviceCalendarPlugin _deviceCalendarPlugin;
  Box<Map<String, dynamic>>? _eventsBox;
  Box<Map<String, dynamic>>? _settingsBox;
  
  CalendarServiceImpl({
    device_calendar.DeviceCalendarPlugin? deviceCalendarPlugin,
  }) : _deviceCalendarPlugin = deviceCalendarPlugin ?? device_calendar.DeviceCalendarPlugin();

  @override
  Future<void> initialize() async {
    try {
      // Initialize Hive boxes for calendar data
      if (!Hive.isBoxOpen(_calendarEventsBoxName)) {
        _eventsBox = await Hive.openBox<Map<String, dynamic>>(_calendarEventsBoxName);
      } else {
        _eventsBox = Hive.box<Map<String, dynamic>>(_calendarEventsBoxName);
      }
      
      if (!Hive.isBoxOpen(_calendarSettingsBoxName)) {
        _settingsBox = await Hive.openBox<Map<String, dynamic>>(_calendarSettingsBoxName);
      } else {
        _settingsBox = Hive.box<Map<String, dynamic>>(_calendarSettingsBoxName);
      }
      
      // Initialize default settings if not exists
      final settings = await getSyncSettings();
      if (settings.defaultCalendarId.isEmpty) {
        await _initializeDefaultSettings();
      }
      
      debugPrint('CalendarService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CalendarService: $e');
      rethrow;
    }
  }

  @override
  Future<bool> requestCalendarPermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android, request calendar permissions
        final status = await Permission.calendarFullAccess.request();
        return status.isGranted;
      } else if (Platform.isIOS) {
        // For iOS, the device_calendar plugin handles permissions internally
        final permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
        if (permissionsGranted.isSuccess && permissionsGranted.data == true) {
          return true;
        }
        
        final requestResult = await _deviceCalendarPlugin.requestPermissions();
        return requestResult.isSuccess && requestResult.data == true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error requesting calendar permission: $e');
      return false;
    }
  }

  @override
  Future<bool> hasCalendarPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.calendarFullAccess.status;
        return status.isGranted;
      } else if (Platform.isIOS) {
        final permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
        return permissionsGranted.isSuccess && permissionsGranted.data == true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking calendar permission: $e');
      return false;
    }
  }

  @override
  Future<List<Calendar>> getAvailableCalendars() async {
    try {
      final hasPermission = await hasCalendarPermission();
      if (!hasPermission) {
        debugPrint('Calendar permission not granted');
        return [];
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        debugPrint('Failed to retrieve calendars: ${calendarsResult.errors}');
        return [];
      }

      return calendarsResult.data!.map((deviceCalendar) {
        return Calendar(
          id: deviceCalendar.id!,
          name: deviceCalendar.name ?? 'Unknown Calendar',
          accountName: deviceCalendar.accountName,
          isDefault: deviceCalendar.isDefault ?? false,
          isReadOnly: deviceCalendar.isReadOnly ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting available calendars: $e');
      return [];
    }
  }

  @override
  Future<void> addODEventToCalendar(ODRequest request, String calendarId) async {
    try {
      final hasPermission = await hasCalendarPermission();
      if (!hasPermission) {
        throw Exception('Calendar permission not granted');
      }

      // Create calendar event from OD request
      final event = _createEventFromODRequest(request, calendarId);
      
      final createResult = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      if (createResult?.isSuccess != true || createResult?.data == null) {
        throw Exception('Failed to create calendar event: ${createResult?.errors}');
      }

      // Store event mapping in local storage
      await _storeEventMapping(request.id, createResult!.data!, calendarId);
      
      debugPrint('Successfully added OD event to calendar: ${request.id}');
    } catch (e) {
      debugPrint('Error adding OD event to calendar: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateODEventInCalendar(ODRequest request) async {
    try {
      final eventMapping = await _getEventMapping(request.id);
      if (eventMapping == null) {
        debugPrint('No calendar event found for OD request: ${request.id}');
        return;
      }

      final hasPermission = await hasCalendarPermission();
      if (!hasPermission) {
        throw Exception('Calendar permission not granted');
      }

      // Update the existing event
      final event = _createEventFromODRequest(request, eventMapping['calendarId'] as String);
      event.eventId = eventMapping['eventId'] as String?;
      
      final updateResult = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      if (updateResult?.isSuccess != true) {
        throw Exception('Failed to update calendar event: ${updateResult?.errors}');
      }
      
      debugPrint('Successfully updated OD event in calendar: ${request.id}');
    } catch (e) {
      debugPrint('Error updating OD event in calendar: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeODEventFromCalendar(String eventId) async {
    try {
      final hasPermission = await hasCalendarPermission();
      if (!hasPermission) {
        throw Exception('Calendar permission not granted');
      }

      // Find the event mapping
      final eventMapping = await _getEventMappingByEventId(eventId);
      if (eventMapping == null) {
        debugPrint('No event mapping found for event ID: $eventId');
        return;
      }

      final deleteResult = await _deviceCalendarPlugin.deleteEvent(
        eventMapping['calendarId'] as String?,
        eventId,
      );
      
      if (!deleteResult.isSuccess) {
        throw Exception('Failed to delete calendar event: ${deleteResult.errors}');
      }

      // Remove event mapping from local storage
      await _removeEventMapping(eventMapping['odRequestId'] as String);
      
      debugPrint('Successfully removed OD event from calendar: $eventId');
    } catch (e) {
      debugPrint('Error removing OD event from calendar: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeODEventByRequestId(String odRequestId) async {
    try {
      final hasPermission = await hasCalendarPermission();
      if (!hasPermission) {
        throw Exception('Calendar permission not granted');
      }

      // Find the event mapping for this OD request
      final eventMapping = await _getEventMapping(odRequestId);
      if (eventMapping == null) {
        debugPrint('No calendar event found for OD request: $odRequestId');
        return;
      }

      final eventId = eventMapping['eventId'] as String?;
      final calendarId = eventMapping['calendarId'] as String?;
      
      if (eventId == null || calendarId == null) {
        debugPrint('Invalid event mapping for OD request: $odRequestId');
        return;
      }

      final deleteResult = await _deviceCalendarPlugin.deleteEvent(calendarId, eventId);
      
      if (!deleteResult.isSuccess) {
        throw Exception('Failed to delete calendar event: ${deleteResult.errors}');
      }

      // Remove event mapping from local storage
      await _removeEventMapping(odRequestId);
      
      debugPrint('Successfully removed OD event from calendar for request: $odRequestId');
    } catch (e) {
      debugPrint('Error removing OD event from calendar by request ID: $e');
      rethrow;
    }
  }

  @override
  Future<void> syncAllODEventsToCalendar() async {
    try {
      final settings = await getSyncSettings();
      if (!settings.autoSyncEnabled) {
        debugPrint('Auto sync is disabled');
        return;
      }

      final hasPermission = await hasCalendarPermission();
      if (!hasPermission) {
        throw Exception('Calendar permission not granted');
      }

      // This would typically get OD requests from a repository
      // For now, we'll just log that sync would happen
      debugPrint('Syncing all OD events to calendar...');
      
      // TODO: Implement actual sync logic when OD request repository is available
      // This would involve:
      // 1. Get all approved OD requests (if syncApprovedOnly is true)
      // 2. Check which ones don't have calendar events
      // 3. Create calendar events for missing ones
      // 4. Update existing events if OD request data changed
      
    } catch (e) {
      debugPrint('Error syncing all OD events to calendar: $e');
      rethrow;
    }
  }

  @override
  Future<void> cleanupODEventsFromCalendar() async {
    try {
      final hasPermission = await hasCalendarPermission();
      if (!hasPermission) {
        throw Exception('Calendar permission not granted');
      }

      // Get all stored event mappings
      final allMappings = _eventsBox?.values.toList() ?? [];
      
      for (final mapping in allMappings) {
        final mappingData = Map<String, dynamic>.from(mapping);
        try {
          await _deviceCalendarPlugin.deleteEvent(
            mappingData['calendarId'] as String?,
            mappingData['eventId'] as String?,
          );
        } catch (e) {
          debugPrint('Error deleting event ${mappingData['eventId']}: $e');
        }
      }

      // Clear all event mappings
      await _eventsBox?.clear();
      
      debugPrint('Successfully cleaned up all OD events from calendar');
    } catch (e) {
      debugPrint('Error cleaning up OD events from calendar: $e');
      rethrow;
    }
  }

  @override
  Future<CalendarSyncSettings> getSyncSettings() async {
    try {
      final settingsData = _settingsBox?.get(_settingsKey);
      if (settingsData == null) {
        return _getDefaultSettings();
      }
      
      return CalendarSyncSettings.fromJson(Map<String, dynamic>.from(settingsData));
    } catch (e) {
      debugPrint('Error getting sync settings: $e');
      return _getDefaultSettings();
    }
  }

  @override
  Future<void> updateSyncSettings(CalendarSyncSettings settings) async {
    try {
      await _settingsBox?.put(_settingsKey, settings.toJson());
      debugPrint('Successfully updated calendar sync settings');
    } catch (e) {
      debugPrint('Error updating sync settings: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isAutoSyncEnabled() async {
    try {
      final settings = await getSyncSettings();
      return settings.autoSyncEnabled;
    } catch (e) {
      debugPrint('Error checking auto sync status: $e');
      return false;
    }
  }

  // Private helper methods

  device_calendar.Event _createEventFromODRequest(ODRequest request, String calendarId) {
    final event = device_calendar.Event(calendarId);
    
    // Set event title based on OD request status
    String title = 'OD Request';
    if (request.isApproved) {
      title = 'OD - ${request.reason}';
    } else if (request.isRejected) {
      title = 'OD (Rejected) - ${request.reason}';
    } else {
      title = 'OD (Pending) - ${request.reason}';
    }
    
    event.title = title;
    event.description = _buildEventDescription(request);
    
    // Set event timing - assuming periods are during school hours
    // This is a simplified approach - in reality, you'd need period timing data
    final startTime = DateTime(
      request.date.year,
      request.date.month,
      request.date.day,
      9, // Assuming school starts at 9 AM
      0,
    );
    
    final endTime = DateTime(
      request.date.year,
      request.date.month,
      request.date.day,
      9 + request.periods.length, // Assuming 1 hour per period
      0,
    );
    
    event.start = tz.TZDateTime.from(startTime, tz.local);
    event.end = tz.TZDateTime.from(endTime, tz.local);
    
    // Set event properties
    event.allDay = false;
    
    // Add metadata
    event.description = '${event.description}\n\nOD Request ID: ${request.id}';
    
    return event;
  }

  String _buildEventDescription(ODRequest request) {
    final buffer = StringBuffer();
    buffer.writeln('Student: ${request.studentName}');
    buffer.writeln('Register Number: ${request.registerNumber}');
    buffer.writeln('Periods: ${request.periods.join(', ')}');
    buffer.writeln('Reason: ${request.reason}');
    buffer.writeln('Status: ${request.status.toUpperCase()}');
    
    if (request.isApproved && request.approvedBy != null) {
      buffer.writeln('Approved by: ${request.approvedBy}');
    }
    
    if (request.isRejected && request.rejectionReason != null) {
      buffer.writeln('Rejection reason: ${request.rejectionReason}');
    }
    
    return buffer.toString();
  }

  Future<void> _storeEventMapping(String odRequestId, String eventId, String calendarId) async {
    final mapping = {
      'odRequestId': odRequestId,
      'eventId': eventId,
      'calendarId': calendarId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await _eventsBox?.put(odRequestId, mapping);
  }

  Future<Map<String, dynamic>?> _getEventMapping(String odRequestId) async {
    final mapping = _eventsBox?.get(odRequestId);
    return mapping != null ? Map<String, dynamic>.from(mapping) : null;
  }

  Future<Map<String, dynamic>?> _getEventMappingByEventId(String eventId) async {
    final allMappings = _eventsBox?.values.toList() ?? [];
    
    for (final mapping in allMappings) {
      final mappingData = Map<String, dynamic>.from(mapping);
      if (mappingData['eventId'] == eventId) {
        return mappingData;
      }
    }
    
    return null;
  }

  Future<void> _removeEventMapping(String odRequestId) async {
    await _eventsBox?.delete(odRequestId);
  }

  CalendarSyncSettings _getDefaultSettings() {
    return const CalendarSyncSettings(
      autoSyncEnabled: false,
      defaultCalendarId: '',
      syncApprovedOnly: true,
      includeRejectedEvents: false,
      reminderSettings: EventReminderSettings(
        enabled: true,
        minutesBefore: 15,
        reminderType: 'notification',
      ),
    );
  }

  Future<void> _initializeDefaultSettings() async {
    try {
      // Try to get the default calendar
      final calendars = await getAvailableCalendars();
      String defaultCalendarId = '';
      
      if (calendars.isNotEmpty) {
        // Find the default calendar or use the first writable one
        final defaultCalendar = calendars.firstWhere(
          (cal) => cal.isDefault && !cal.isReadOnly,
          orElse: () => calendars.firstWhere(
            (cal) => !cal.isReadOnly,
            orElse: () => calendars.first,
          ),
        );
        defaultCalendarId = defaultCalendar.id;
      }
      
      final defaultSettings = CalendarSyncSettings(
        autoSyncEnabled: false,
        defaultCalendarId: defaultCalendarId,
        syncApprovedOnly: true,
        includeRejectedEvents: false,
        reminderSettings: const EventReminderSettings(
          enabled: true,
          minutesBefore: 15,
          reminderType: 'notification',
        ),
      );
      
      await updateSyncSettings(defaultSettings);
    } catch (e) {
      debugPrint('Error initializing default settings: $e');
    }
  }
}