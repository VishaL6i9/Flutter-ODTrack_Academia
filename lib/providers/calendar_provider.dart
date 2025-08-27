import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odtrack_academia/models/calendar_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/calendar/calendar_service.dart';
import 'package:odtrack_academia/services/calendar/calendar_service_impl.dart';

/// Calendar state model
@immutable
class CalendarState {
  final bool hasPermission;
  final List<Calendar> availableCalendars;
  final CalendarSyncSettings? syncSettings;
  final bool isLoading;
  final String? error;

  const CalendarState({
    this.hasPermission = false,
    this.availableCalendars = const [],
    this.syncSettings,
    this.isLoading = false,
    this.error,
  });

  CalendarState copyWith({
    bool? hasPermission,
    List<Calendar>? availableCalendars,
    CalendarSyncSettings? syncSettings,
    bool? isLoading,
    String? error,
  }) {
    return CalendarState(
      hasPermission: hasPermission ?? this.hasPermission,
      availableCalendars: availableCalendars ?? this.availableCalendars,
      syncSettings: syncSettings ?? this.syncSettings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Calendar service provider
final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarServiceImpl();
});

/// Calendar state notifier
class CalendarNotifier extends StateNotifier<AsyncValue<CalendarState>> {
  final CalendarService _calendarService;

  CalendarNotifier(this._calendarService) : super(const AsyncValue.loading());

  /// Initialize calendar service and load initial state
  Future<void> initialize() async {
    try {
      state = const AsyncValue.loading();
      
      await _calendarService.initialize();
      
      final hasPermission = await _calendarService.hasCalendarPermission();
      final syncSettings = await _calendarService.getSyncSettings();
      
      List<Calendar> calendars = [];
      if (hasPermission) {
        calendars = await _calendarService.getAvailableCalendars();
      }
      
      state = AsyncValue.data(CalendarState(
        hasPermission: hasPermission,
        availableCalendars: calendars,
        syncSettings: syncSettings,
      ));
    } catch (e, stackTrace) {
      debugPrint('Error initializing calendar: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Request calendar permission
  Future<void> requestPermission() async {
    try {
      final currentState = state.value;
      if (currentState == null) return;

      state = AsyncValue.data(currentState.copyWith(isLoading: true));
      
      final granted = await _calendarService.requestCalendarPermission();
      
      if (granted) {
        final calendars = await _calendarService.getAvailableCalendars();
        state = AsyncValue.data(currentState.copyWith(
          hasPermission: true,
          availableCalendars: calendars,
          isLoading: false,
        ));
      } else {
        state = AsyncValue.data(currentState.copyWith(
          hasPermission: false,
          isLoading: false,
          error: 'Calendar permission denied',
        ));
      }
    } catch (e, stackTrace) {
      debugPrint('Error requesting calendar permission: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Load available calendars
  Future<void> loadAvailableCalendars() async {
    try {
      final currentState = state.value;
      if (currentState == null || !currentState.hasPermission) return;

      state = AsyncValue.data(currentState.copyWith(isLoading: true));
      
      final calendars = await _calendarService.getAvailableCalendars();
      
      state = AsyncValue.data(currentState.copyWith(
        availableCalendars: calendars,
        isLoading: false,
      ));
    } catch (e, stackTrace) {
      debugPrint('Error loading calendars: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update default calendar
  Future<void> updateDefaultCalendar(String calendarId) async {
    try {
      final currentState = state.value;
      if (currentState?.syncSettings == null) return;

      final updatedSettings = CalendarSyncSettings(
        autoSyncEnabled: currentState!.syncSettings!.autoSyncEnabled,
        defaultCalendarId: calendarId,
        syncApprovedOnly: currentState.syncSettings!.syncApprovedOnly,
        includeRejectedEvents: currentState.syncSettings!.includeRejectedEvents,
        reminderSettings: currentState.syncSettings!.reminderSettings,
      );

      await _calendarService.updateSyncSettings(updatedSettings);
      
      state = AsyncValue.data(currentState.copyWith(
        syncSettings: updatedSettings,
      ));
    } catch (e, stackTrace) {
      debugPrint('Error updating default calendar: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update auto sync setting
  Future<void> updateAutoSync(bool enabled) async {
    try {
      final currentState = state.value;
      if (currentState?.syncSettings == null) return;

      final updatedSettings = CalendarSyncSettings(
        autoSyncEnabled: enabled,
        defaultCalendarId: currentState!.syncSettings!.defaultCalendarId,
        syncApprovedOnly: currentState.syncSettings!.syncApprovedOnly,
        includeRejectedEvents: currentState.syncSettings!.includeRejectedEvents,
        reminderSettings: currentState.syncSettings!.reminderSettings,
      );

      await _calendarService.updateSyncSettings(updatedSettings);
      
      state = AsyncValue.data(currentState.copyWith(
        syncSettings: updatedSettings,
      ));
    } catch (e, stackTrace) {
      debugPrint('Error updating auto sync: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update sync approved only setting
  Future<void> updateSyncApprovedOnly(bool syncApprovedOnly) async {
    try {
      final currentState = state.value;
      if (currentState?.syncSettings == null) return;

      final updatedSettings = CalendarSyncSettings(
        autoSyncEnabled: currentState!.syncSettings!.autoSyncEnabled,
        defaultCalendarId: currentState.syncSettings!.defaultCalendarId,
        syncApprovedOnly: syncApprovedOnly,
        includeRejectedEvents: currentState.syncSettings!.includeRejectedEvents,
        reminderSettings: currentState.syncSettings!.reminderSettings,
      );

      await _calendarService.updateSyncSettings(updatedSettings);
      
      state = AsyncValue.data(currentState.copyWith(
        syncSettings: updatedSettings,
      ));
    } catch (e, stackTrace) {
      debugPrint('Error updating sync approved only: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update include rejected events setting
  Future<void> updateIncludeRejected(bool includeRejected) async {
    try {
      final currentState = state.value;
      if (currentState?.syncSettings == null) return;

      final updatedSettings = CalendarSyncSettings(
        autoSyncEnabled: currentState!.syncSettings!.autoSyncEnabled,
        defaultCalendarId: currentState.syncSettings!.defaultCalendarId,
        syncApprovedOnly: currentState.syncSettings!.syncApprovedOnly,
        includeRejectedEvents: includeRejected,
        reminderSettings: currentState.syncSettings!.reminderSettings,
      );

      await _calendarService.updateSyncSettings(updatedSettings);
      
      state = AsyncValue.data(currentState.copyWith(
        syncSettings: updatedSettings,
      ));
    } catch (e, stackTrace) {
      debugPrint('Error updating include rejected: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update reminder enabled setting
  Future<void> updateReminderEnabled(bool enabled) async {
    try {
      final currentState = state.value;
      if (currentState?.syncSettings == null) return;

      final updatedReminderSettings = EventReminderSettings(
        enabled: enabled,
        minutesBefore: currentState!.syncSettings!.reminderSettings.minutesBefore,
        reminderType: currentState.syncSettings!.reminderSettings.reminderType,
      );

      final updatedSettings = CalendarSyncSettings(
        autoSyncEnabled: currentState.syncSettings!.autoSyncEnabled,
        defaultCalendarId: currentState.syncSettings!.defaultCalendarId,
        syncApprovedOnly: currentState.syncSettings!.syncApprovedOnly,
        includeRejectedEvents: currentState.syncSettings!.includeRejectedEvents,
        reminderSettings: updatedReminderSettings,
      );

      await _calendarService.updateSyncSettings(updatedSettings);
      
      state = AsyncValue.data(currentState.copyWith(
        syncSettings: updatedSettings,
      ));
    } catch (e, stackTrace) {
      debugPrint('Error updating reminder enabled: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update reminder time
  Future<void> updateReminderTime(int minutes) async {
    try {
      final currentState = state.value;
      if (currentState?.syncSettings == null) return;

      final updatedReminderSettings = EventReminderSettings(
        enabled: currentState!.syncSettings!.reminderSettings.enabled,
        minutesBefore: minutes,
        reminderType: currentState.syncSettings!.reminderSettings.reminderType,
      );

      final updatedSettings = CalendarSyncSettings(
        autoSyncEnabled: currentState.syncSettings!.autoSyncEnabled,
        defaultCalendarId: currentState.syncSettings!.defaultCalendarId,
        syncApprovedOnly: currentState.syncSettings!.syncApprovedOnly,
        includeRejectedEvents: currentState.syncSettings!.includeRejectedEvents,
        reminderSettings: updatedReminderSettings,
      );

      await _calendarService.updateSyncSettings(updatedSettings);
      
      state = AsyncValue.data(currentState.copyWith(
        syncSettings: updatedSettings,
      ));
    } catch (e, stackTrace) {
      debugPrint('Error updating reminder time: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Add OD event to calendar
  Future<void> addODEventToCalendar(ODRequest request, {String? calendarId}) async {
    try {
      final currentState = state.value;
      if (currentState?.syncSettings == null) return;

      final targetCalendarId = calendarId ?? currentState!.syncSettings!.defaultCalendarId;
      if (targetCalendarId.isEmpty) {
        throw Exception('No calendar selected');
      }

      await _calendarService.addODEventToCalendar(request, targetCalendarId);
    } catch (e) {
      debugPrint('Error adding OD event to calendar: $e');
      rethrow;
    }
  }

  /// Update OD event in calendar
  Future<void> updateODEventInCalendar(ODRequest request) async {
    try {
      await _calendarService.updateODEventInCalendar(request);
    } catch (e) {
      debugPrint('Error updating OD event in calendar: $e');
      rethrow;
    }
  }

  /// Remove OD event from calendar
  Future<void> removeODEventFromCalendar(String eventId) async {
    try {
      await _calendarService.removeODEventFromCalendar(eventId);
    } catch (e) {
      debugPrint('Error removing OD event from calendar: $e');
      rethrow;
    }
  }

  /// Sync all OD events to calendar
  Future<void> syncAllEvents() async {
    try {
      final currentState = state.value;
      if (currentState == null) return;

      state = AsyncValue.data(currentState.copyWith(isLoading: true));
      
      await _calendarService.syncAllODEventsToCalendar();
      
      state = AsyncValue.data(currentState.copyWith(isLoading: false));
    } catch (e, stackTrace) {
      debugPrint('Error syncing all events: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Cleanup all calendar events
  Future<void> cleanupAllEvents() async {
    try {
      final currentState = state.value;
      if (currentState == null) return;

      state = AsyncValue.data(currentState.copyWith(isLoading: true));
      
      await _calendarService.cleanupODEventsFromCalendar();
      
      state = AsyncValue.data(currentState.copyWith(isLoading: false));
    } catch (e, stackTrace) {
      debugPrint('Error cleaning up events: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Check if auto sync is enabled
  Future<bool> isAutoSyncEnabled() async {
    try {
      return await _calendarService.isAutoSyncEnabled();
    } catch (e) {
      debugPrint('Error checking auto sync status: $e');
      return false;
    }
  }

  /// Remove OD event from calendar by request ID
  Future<void> removeODEventByRequestId(String odRequestId) async {
    try {
      await _calendarService.removeODEventByRequestId(odRequestId);
    } catch (e) {
      debugPrint('Error removing OD event by request ID: $e');
      rethrow;
    }
  }
}

/// Calendar provider
final calendarProvider = StateNotifierProvider<CalendarNotifier, AsyncValue<CalendarState>>((ref) {
  final calendarService = ref.watch(calendarServiceProvider);
  return CalendarNotifier(calendarService);
});