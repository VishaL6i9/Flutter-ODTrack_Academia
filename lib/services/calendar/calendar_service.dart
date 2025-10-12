import 'dart:async';
import 'package:odtrack_academia/models/calendar_models.dart';
import 'package:odtrack_academia/models/od_request.dart';

/// Abstract interface for calendar integration service
/// Handles device calendar synchronization for OD requests
abstract class CalendarService {
  /// Initialize the calendar service
  Future<void> initialize();
  
  /// Request calendar permissions
  Future<bool> requestCalendarPermission();
  
  /// Check if calendar permission is granted
  Future<bool> hasCalendarPermission();
  
  /// Get available calendars on device
  Future<List<Calendar>> getAvailableCalendars();
  
  /// Add OD event to device calendar
  Future<void> addODEventToCalendar(ODRequest request, String calendarId);
  
  /// Update existing OD event in calendar
  Future<void> updateODEventInCalendar(ODRequest request);
  
  /// Remove OD event from calendar by event ID
  Future<void> removeODEventFromCalendar(String eventId);
  
  /// Remove OD event from calendar by OD request ID
  Future<void> removeODEventByRequestId(String odRequestId);
  
  /// Sync all approved OD events to calendar
  Future<void> syncAllODEventsToCalendar();
  
  /// Clean up OD events from calendar
  Future<void> cleanupODEventsFromCalendar();
  
  /// Get calendar sync settings
  Future<CalendarSyncSettings> getSyncSettings();
  
  /// Update calendar sync settings
  Future<void> updateSyncSettings(CalendarSyncSettings settings);
  
  /// Check if auto-sync is enabled
  Future<bool> isAutoSyncEnabled();
  
  /// Batch sync multiple OD requests to calendar
  Future<BatchSyncResult> batchSyncODRequests(List<ODRequest> requests);
  
  /// Get calendar sync status for multiple requests
  Future<Map<String, CalendarSyncStatus>> getCalendarSyncStatus(List<String> requestIds);
}
