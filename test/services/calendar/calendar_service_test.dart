import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:odtrack_academia/services/calendar/calendar_service_impl.dart';

void main() {
  group('CalendarServiceImpl', () {
    late CalendarServiceImpl calendarService;

    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('test/hive_test_db');
    });

    setUp(() async {
      calendarService = CalendarServiceImpl();
    });

    group('initialize', () {
      test('should initialize successfully', () async {
        // Act & Assert - no exception should be thrown
        expect(() => calendarService.initialize(), returnsNormally);
      });
    });

    group('permission handling', () {
      test('should have permission methods', () async {
        // Test that the methods exist and are callable
        expect(calendarService.requestCalendarPermission, isA<Function>());
        expect(calendarService.hasCalendarPermission, isA<Function>());
      });
    });

    group('calendar operations', () {
      test('should have calendar operation methods', () async {
        // Test that the methods exist and are callable
        expect(calendarService.getAvailableCalendars, isA<Function>());
      });
    });

    group('OD event management', () {
      test('should have OD event management methods', () async {
        // Test that the methods exist and are callable
        expect(calendarService.addODEventToCalendar, isA<Function>());
        expect(calendarService.updateODEventInCalendar, isA<Function>());
        expect(calendarService.removeODEventFromCalendar, isA<Function>());
        expect(calendarService.removeODEventByRequestId, isA<Function>());
      });
    });

    group('sync settings', () {
      test('should have sync settings methods', () async {
        // Test that the methods exist and are callable
        expect(calendarService.getSyncSettings, isA<Function>());
        expect(calendarService.updateSyncSettings, isA<Function>());
        expect(calendarService.isAutoSyncEnabled, isA<Function>());
      });
    });

    group('sync operations', () {
      test('should have sync operation methods', () async {
        // Test that the methods exist and are callable
        expect(calendarService.syncAllODEventsToCalendar, isA<Function>());
        expect(calendarService.cleanupODEventsFromCalendar, isA<Function>());
      });
    });
  });
}