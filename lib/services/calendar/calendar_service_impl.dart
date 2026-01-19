import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:odtrack_academia/models/calendar_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/calendar/calendar_service.dart';

/// Concrete implementation of CalendarService using local storage
/// Note: device_calendar plugin removed due to Android SDK 35 compatibility issues
/// Calendar events are stored locally in Hive
class CalendarServiceImpl implements CalendarService {
  static const String _calendarEventsBoxName = 'calendar_events_box';
  static const String _calendarSettingsBoxName = 'calendar_settings_box';
  static const String _settingsKey = 'calendar_sync_settings';
  
  Box<Map<String, dynamic>>? _eventsBox;
  Box<Map<String, dynamic>>? _settingsBox;
  
  CalendarServiceImpl();

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
        final status = await Permission.calendarFullAccess.request();
        return status.isGranted;
      } else if (Platform.isIOS) {
        final status = await Permission.calendarFullAccess.request();
        return status.isGranted;
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
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.calendarFullAccess.status;
        return status.isGranted;
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
      // Return a default local calendar since we're not using device_calendar
      return [
        const Calendar(
          id: 'local_calendar',
          name: 'ODTrack Calendar',
          accountName: 'Local Storage',
          isDefault: true,
          isReadOnly: false,
        ),
      ];
    } catch (e) {
      debugPrint('Error getting available calendars: $e');
      return [];
    }
  }

  @override
  Future<void> addODEventToCalendar(ODRequest request, String calendarId) async {
    try {
      // Store event locally in Hive
      final eventData = _createEventDataFromODRequest(request, calendarId);
      await _storeEventMappingData(request.id, eventData);
      debugPrint('Successfully stored OD event locally: ${request.id}');
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

      final calendarId = eventMapping['calendarId'] as String? ?? 'local_calendar';
      final eventData = _createEventDataFromODRequest(request, calendarId);
      await _storeEventMappingData(request.id, eventData);
      debugPrint('Successfully updated OD event locally: ${request.id}');
    } catch (e) {
      debugPrint('Error updating OD event in calendar: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeODEventFromCalendar(String eventId) async {
    try {
      final eventMapping = await _getEventMappingByEventId(eventId);
      if (eventMapping == null) {
        debugPrint('No event mapping found for event ID: $eventId');
        return;
      }

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
      final eventMapping = await _getEventMapping(odRequestId);
      if (eventMapping == null) {
        debugPrint('No calendar event found for OD request: $odRequestId');
        return;
      }

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

      debugPrint('Syncing all OD events to local calendar...');
      // Events are stored locally, no external sync needed
    } catch (e) {
      debugPrint('Error syncing all OD events to calendar: $e');
      rethrow;
    }
  }

  @override
  Future<void> cleanupODEventsFromCalendar() async {
    try {
      await _eventsBox?.clear();
      debugPrint('Successfully cleaned up all OD events from local calendar');
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

  @override
  Future<BatchSyncResult> batchSyncODRequests(List<ODRequest> requests) async {
    final syncTimestamp = DateTime.now();
    final successfulRequestIds = <String>[];
    final errors = <String, String>{};
    
    try {
      final hasPermission = await hasCalendarPermission();
      if (!hasPermission) {
        throw Exception('Calendar permission not granted');
      }

      final settings = await getSyncSettings();
      if (settings.defaultCalendarId.isEmpty) {
        throw Exception('No default calendar selected');
      }

      // Filter requests based on sync settings
      final requestsToSync = requests.where((request) {
        if (settings.syncApprovedOnly && !request.isApproved) {
          return settings.includeRejectedEvents && request.isRejected;
        }
        if (request.isRejected && !settings.includeRejectedEvents) {
          return false;
        }
        return true;
      }).toList();

      // Batch sync with rate limiting to avoid overwhelming calendar API
      for (final request in requestsToSync) {
        try {
          await addODEventToCalendar(request, settings.defaultCalendarId);
          successfulRequestIds.add(request.id);
          
          // Add small delay between requests to prevent API rate limiting
          await Future<void>.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          errors[request.id] = e.toString();
          debugPrint('Error syncing request ${request.id}: $e');
        }
      }

      return BatchSyncResult(
        totalRequests: requestsToSync.length,
        successCount: successfulRequestIds.length,
        errorCount: errors.length,
        successfulRequestIds: successfulRequestIds,
        errors: errors,
        syncTimestamp: syncTimestamp,
      );
    } catch (e) {
      debugPrint('Error in batch sync: $e');
      
      // Return result with global error
      return BatchSyncResult(
        totalRequests: requests.length,
        successCount: successfulRequestIds.length,
        errorCount: requests.length - successfulRequestIds.length,
        successfulRequestIds: successfulRequestIds,
        errors: {
          'global': e.toString(),
          ...errors,
        },
        syncTimestamp: syncTimestamp,
      );
    }
  }

  @override
  Future<Map<String, CalendarSyncStatus>> getCalendarSyncStatus(List<String> requestIds) async {
    final statusMap = <String, CalendarSyncStatus>{};
    
    try {
      for (final requestId in requestIds) {
        final eventMapping = await _getEventMapping(requestId);
        
        if (eventMapping != null) {
          statusMap[requestId] = CalendarSyncStatus(
            requestId: requestId,
            isSynced: true,
            eventId: eventMapping['eventId'] as String?,
            calendarId: eventMapping['calendarId'] as String?,
            lastSyncTime: DateTime.tryParse(eventMapping['createdAt'] as String? ?? ''),
          );
        } else {
          statusMap[requestId] = CalendarSyncStatus(
            requestId: requestId,
            isSynced: false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting calendar sync status: $e');
      
      // Return error status for all requests
      for (final requestId in requestIds) {
        statusMap[requestId] = CalendarSyncStatus(
          requestId: requestId,
          isSynced: false,
          error: e.toString(),
        );
      }
    }
    
    return statusMap;
  }

  // Private helper methods

  Map<String, dynamic> _createEventDataFromODRequest(ODRequest request, String calendarId) {
    final startTime = DateTime(
      request.date.year,
      request.date.month,
      request.date.day,
      9,
      0,
    );
    
    final endTime = DateTime(
      request.date.year,
      request.date.month,
      request.date.day,
      9 + request.periods.length,
      0,
    );
    
    String title = 'OD Request';
    if (request.isApproved) {
      title = 'OD - ${request.reason}';
    } else if (request.isRejected) {
      title = 'OD (Rejected) - ${request.reason}';
    } else {
      title = 'OD (Pending) - ${request.reason}';
    }
    
    return {
      'odRequestId': request.id,
      'eventId': 'event_${request.id}',
      'calendarId': calendarId,
      'title': title,
      'description': _buildEventDescription(request),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };
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

  Future<void> _storeEventMappingData(String odRequestId, Map<String, dynamic> eventData) async {
    await _eventsBox?.put(odRequestId, eventData);
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