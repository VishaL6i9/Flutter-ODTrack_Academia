import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odtrack_academia/models/calendar_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/calendar/calendar_service.dart';
import 'package:odtrack_academia/providers/calendar_provider.dart';

/// Service responsible for synchronizing OD requests with calendar events
class CalendarSyncService {
  final CalendarService _calendarService;
  
  CalendarSyncService(this._calendarService);

  /// Handles OD request status changes and syncs with calendar
  Future<void> handleODRequestStatusChange(ODRequest oldRequest, ODRequest newRequest) async {
    try {
      // Check if auto sync is enabled
      final isAutoSyncEnabled = await _calendarService.isAutoSyncEnabled();
      if (!isAutoSyncEnabled) {
        debugPrint('Auto sync is disabled, skipping calendar sync');
        return;
      }

      // Get sync settings to determine what to sync
      final settings = await _calendarService.getSyncSettings();
      
      // Handle different status change scenarios
      await _handleStatusChangeScenario(oldRequest, newRequest, settings);
      
    } catch (e) {
      debugPrint('Error handling OD request status change: $e');
      rethrow;
    }
  }

  /// Handles creation of new OD requests
  Future<void> handleODRequestCreation(ODRequest request) async {
    try {
      // Check if auto sync is enabled
      final isAutoSyncEnabled = await _calendarService.isAutoSyncEnabled();
      if (!isAutoSyncEnabled) {
        debugPrint('Auto sync is disabled, skipping calendar sync');
        return;
      }

      final settings = await _calendarService.getSyncSettings();
      
      // Only create calendar event if it matches sync criteria
      if (_shouldSyncRequest(request, settings)) {
        await _createCalendarEventForRequest(request, settings);
      }
      
    } catch (e) {
      debugPrint('Error handling OD request creation: $e');
      rethrow;
    }
  }

  /// Handles deletion of OD requests
  Future<void> handleODRequestDeletion(ODRequest request) async {
    try {
      // Always try to remove calendar event when OD request is deleted
      await _removeCalendarEventForRequest(request);
      
    } catch (e) {
      debugPrint('Error handling OD request deletion: $e');
      rethrow;
    }
  }

  /// Syncs all existing OD requests with calendar
  Future<void> syncAllODRequests(List<ODRequest> requests) async {
    try {
      // Check if auto sync is enabled
      final isAutoSyncEnabled = await _calendarService.isAutoSyncEnabled();
      if (!isAutoSyncEnabled) {
        debugPrint('Auto sync is disabled, skipping calendar sync');
        return;
      }

      final settings = await _calendarService.getSyncSettings();
      
      for (final request in requests) {
        if (_shouldSyncRequest(request, settings)) {
          try {
            await _createOrUpdateCalendarEventForRequest(request, settings);
          } catch (e) {
            debugPrint('Error syncing request ${request.id}: $e');
            // Continue with other requests even if one fails
          }
        }
      }
      
    } catch (e) {
      debugPrint('Error syncing all OD requests: $e');
      rethrow;
    }
  }

  // Private helper methods

  Future<void> _handleStatusChangeScenario(
    ODRequest oldRequest, 
    ODRequest newRequest, 
    CalendarSyncSettings settings
  ) async {
    final oldShouldSync = _shouldSyncRequest(oldRequest, settings);
    final newShouldSync = _shouldSyncRequest(newRequest, settings);

    if (!oldShouldSync && newShouldSync) {
      // Request now meets sync criteria - create calendar event
      await _createCalendarEventForRequest(newRequest, settings);
    } else if (oldShouldSync && !newShouldSync) {
      // Request no longer meets sync criteria - remove calendar event
      await _removeCalendarEventForRequest(newRequest);
    } else if (oldShouldSync && newShouldSync) {
      // Request still meets sync criteria - update calendar event
      await _updateCalendarEventForRequest(newRequest);
    }
    // If neither old nor new should sync, do nothing
  }

  bool _shouldSyncRequest(ODRequest request, CalendarSyncSettings settings) {
    // Check if request status matches sync settings
    if (settings.syncApprovedOnly && !request.isApproved) {
      // Only sync approved requests, but this request is not approved
      if (!settings.includeRejectedEvents || !request.isRejected) {
        return false;
      }
    }
    
    // Don't sync rejected requests unless explicitly enabled
    if (request.isRejected && !settings.includeRejectedEvents) {
      return false;
    }
    
    // Check if default calendar is set
    if (settings.defaultCalendarId.isEmpty) {
      debugPrint('No default calendar set, cannot sync');
      return false;
    }
    
    return true;
  }

  Future<void> _createCalendarEventForRequest(ODRequest request, CalendarSyncSettings settings) async {
    try {
      await _calendarService.addODEventToCalendar(request, settings.defaultCalendarId);
      debugPrint('Created calendar event for OD request: ${request.id}');
    } catch (e) {
      debugPrint('Error creating calendar event for request ${request.id}: $e');
      rethrow;
    }
  }

  Future<void> _updateCalendarEventForRequest(ODRequest request) async {
    try {
      await _calendarService.updateODEventInCalendar(request);
      debugPrint('Updated calendar event for OD request: ${request.id}');
    } catch (e) {
      debugPrint('Error updating calendar event for request ${request.id}: $e');
      rethrow;
    }
  }

  Future<void> _removeCalendarEventForRequest(ODRequest request) async {
    try {
      await _calendarService.removeODEventByRequestId(request.id);
      debugPrint('Removed calendar event for OD request: ${request.id}');
    } catch (e) {
      debugPrint('Error removing calendar event for request ${request.id}: $e');
      // Don't rethrow here as the event might not exist
    }
  }

  Future<void> _createOrUpdateCalendarEventForRequest(ODRequest request, CalendarSyncSettings settings) async {
    try {
      // Try to update first (in case event already exists)
      await _calendarService.updateODEventInCalendar(request);
    } catch (e) {
      // If update fails, try to create new event
      try {
        await _calendarService.addODEventToCalendar(request, settings.defaultCalendarId);
      } catch (createError) {
        debugPrint('Error creating calendar event for request ${request.id}: $createError');
        rethrow;
      }
    }
  }
}

/// Provider for calendar sync service
final calendarSyncServiceProvider = Provider<CalendarSyncService>((ref) {
  final calendarService = ref.watch(calendarServiceProvider);
  return CalendarSyncService(calendarService);
});