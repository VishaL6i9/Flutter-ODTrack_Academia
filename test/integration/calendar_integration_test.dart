import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:odtrack_academia/features/calendar_settings/calendar_settings_screen.dart';
import 'package:odtrack_academia/models/calendar_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/providers/calendar_provider.dart';
import 'package:odtrack_academia/providers/od_request_provider.dart';
import 'package:odtrack_academia/services/calendar/calendar_service.dart';
import 'package:odtrack_academia/services/calendar/calendar_sync_service.dart';

import 'calendar_integration_test.mocks.dart';

@GenerateMocks([CalendarService])
void main() {
  group('Calendar Integration Tests', () {
    late MockCalendarService mockCalendarService;
    late ProviderContainer container;

    setUp(() {
      mockCalendarService = MockCalendarService();
      container = ProviderContainer(
        overrides: [
          calendarServiceProvider.overrideWithValue(mockCalendarService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Calendar Settings Screen - Permission Flow', (tester) async {
      // Setup mock responses
      when(mockCalendarService.initialize()).thenAnswer((_) async {});
      when(mockCalendarService.hasCalendarPermission()).thenAnswer((_) async => false);
      when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => _getDefaultSettings());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CalendarSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify permission section is shown
      expect(find.text('Calendar Permission'), findsOneWidget);
      expect(find.text('Grant Permission'), findsOneWidget);

      // Tap grant permission button
      when(mockCalendarService.requestCalendarPermission()).thenAnswer((_) async => true);
      when(mockCalendarService.getAvailableCalendars()).thenAnswer((_) async => [
        const Calendar(
          id: 'test-calendar-1',
          name: 'Test Calendar',
          isDefault: true,
        ),
      ]);

      await tester.tap(find.text('Grant Permission'));
      await tester.pumpAndSettle();

      // Verify permission granted and calendars loaded
      verify(mockCalendarService.requestCalendarPermission()).called(1);
      verify(mockCalendarService.getAvailableCalendars()).called(1);
    });

    testWidgets('Calendar Settings Screen - Sync Settings Configuration', (tester) async {
      // Setup mock responses for granted permission
      when(mockCalendarService.initialize()).thenAnswer((_) async {});
      when(mockCalendarService.hasCalendarPermission()).thenAnswer((_) async => true);
      when(mockCalendarService.getAvailableCalendars()).thenAnswer((_) async => [
        const Calendar(
          id: 'test-calendar-1',
          name: 'Test Calendar',
          isDefault: true,
        ),
      ]);
      when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => _getDefaultSettings());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CalendarSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify sync settings are shown
      expect(find.text('Sync Settings'), findsOneWidget);
      expect(find.text('Auto Sync'), findsOneWidget);
      expect(find.text('Sync Approved Only'), findsOneWidget);

      // Test toggling auto sync
      final autoSyncSwitch = find.byType(Switch).first;
      await tester.tap(autoSyncSwitch);
      await tester.pumpAndSettle();

      // Verify update method was called
      verify(mockCalendarService.updateSyncSettings(any)).called(1);
    });

    testWidgets('Calendar Settings Screen - Batch Sync Flow', (tester) async {
      // Setup mock responses
      when(mockCalendarService.initialize()).thenAnswer((_) async {});
      when(mockCalendarService.hasCalendarPermission()).thenAnswer((_) async => true);
      when(mockCalendarService.getAvailableCalendars()).thenAnswer((_) async => [
        const Calendar(
          id: 'test-calendar-1',
          name: 'Test Calendar',
          isDefault: true,
        ),
      ]);
      when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => const CalendarSyncSettings(
        autoSyncEnabled: true,
        defaultCalendarId: 'test-calendar-1',
        syncApprovedOnly: true,
        includeRejectedEvents: false,
        reminderSettings: EventReminderSettings(
          enabled: true,
          minutesBefore: 15,
          reminderType: 'notification',
        ),
      ));

      // Mock batch sync result
      when(mockCalendarService.batchSyncODRequests(any)).thenAnswer((_) async => BatchSyncResult(
        totalRequests: 2,
        successCount: 2,
        errorCount: 0,
        successfulRequestIds: ['req1', 'req2'],
        errors: {},
        syncTimestamp: DateTime.now(),
      ));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer(
            overrides: [
              calendarServiceProvider.overrideWithValue(mockCalendarService),
              odRequestProvider.overrideWith((ref) {
                final notifier = ODRequestNotifier();
                notifier.state = [
                  _createTestODRequest('req1', true),
                  _createTestODRequest('req2', true),
                ];
                return notifier;
              }),
            ],
          ),
          child: const MaterialApp(
            home: CalendarSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to find the batch sync button
      await tester.scrollUntilVisible(
        find.text('Start Batch Sync'),
        500.0,
      );

      // Find and tap batch sync button
      expect(find.text('Start Batch Sync'), findsOneWidget);
      await tester.tap(find.text('Start Batch Sync'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify batch sync was called
      verify(mockCalendarService.batchSyncODRequests(any)).called(1);

      // Wait for sync completion
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify success message appears
      expect(find.textContaining('Successfully synced'), findsOneWidget);
    });

    test('Calendar Sync Service - OD Request Status Change Handling', () async {
      // Setup
      final calendarSyncService = CalendarSyncService(mockCalendarService);
      
      when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
      when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => const CalendarSyncSettings(
        autoSyncEnabled: true,
        defaultCalendarId: 'test-calendar-1',
        syncApprovedOnly: true,
        includeRejectedEvents: false,
        reminderSettings: EventReminderSettings(
          enabled: true,
          minutesBefore: 15,
          reminderType: 'notification',
        ),
      ));

      final oldRequest = _createTestODRequest('test-1', false); // Pending
      final newRequest = _createTestODRequest('test-1', true);  // Approved

      when(mockCalendarService.addODEventToCalendar(any, any)).thenAnswer((_) async {});

      // Test status change from pending to approved
      await calendarSyncService.handleODRequestStatusChange(oldRequest, newRequest);

      // Verify calendar event was created
      verify(mockCalendarService.addODEventToCalendar(newRequest, 'test-calendar-1')).called(1);
    });

    test('Calendar Sync Service - Batch Sync All Requests', () async {
      // Setup
      final calendarSyncService = CalendarSyncService(mockCalendarService);
      
      when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
      when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => const CalendarSyncSettings(
        autoSyncEnabled: true,
        defaultCalendarId: 'test-calendar-1',
        syncApprovedOnly: true,
        includeRejectedEvents: false,
        reminderSettings: EventReminderSettings(
          enabled: true,
          minutesBefore: 15,
          reminderType: 'notification',
        ),
      ));

      final requests = [
        _createTestODRequest('req1', true),  // Should sync
        _createTestODRequest('req2', false), // Should not sync (pending)
        _createTestODRequest('req3', true),  // Should sync
      ];

      when(mockCalendarService.addODEventToCalendar(any, any)).thenAnswer((_) async {});
      when(mockCalendarService.updateODEventInCalendar(any)).thenThrow(Exception('Event not found'));

      // Test batch sync
      await calendarSyncService.syncAllODRequests(requests);

      // Verify only approved requests were synced
      verify(mockCalendarService.addODEventToCalendar(requests[0], 'test-calendar-1')).called(1);
      verify(mockCalendarService.addODEventToCalendar(requests[2], 'test-calendar-1')).called(1);
      verifyNever(mockCalendarService.addODEventToCalendar(requests[1], any));
    });

    test('Calendar Service - Batch Sync with Error Handling', () async {
      // Setup
      when(mockCalendarService.hasCalendarPermission()).thenAnswer((_) async => true);
      when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => const CalendarSyncSettings(
        autoSyncEnabled: true,
        defaultCalendarId: 'test-calendar-1',
        syncApprovedOnly: true,
        includeRejectedEvents: false,
        reminderSettings: EventReminderSettings(
          enabled: true,
          minutesBefore: 15,
          reminderType: 'notification',
        ),
      ));

      final requests = [
        _createTestODRequest('req1', true),
        _createTestODRequest('req2', true),
      ];

      // Mock batch sync with partial failure
      when(mockCalendarService.batchSyncODRequests(requests)).thenAnswer((_) async => BatchSyncResult(
        totalRequests: 2,
        successCount: 1,
        errorCount: 1,
        successfulRequestIds: ['req1'],
        errors: {'req2': 'Calendar API error'},
        syncTimestamp: DateTime.now(),
      ));

      // Test batch sync
      final result = await mockCalendarService.batchSyncODRequests(requests);

      // Verify partial success is handled correctly
      expect(result.totalRequests, equals(2));
      expect(result.successCount, equals(1));
      expect(result.errorCount, equals(1));
      expect(result.successfulRequestIds, contains('req1'));
      expect(result.errors, containsPair('req2', contains('Calendar API error')));
    });

    test('Calendar Sync Status Tracking', () async {
      // Setup
      final requestIds = ['req1', 'req2', 'req3'];
      
      when(mockCalendarService.getCalendarSyncStatus(requestIds)).thenAnswer((_) async => {
        'req1': const CalendarSyncStatus(
          requestId: 'req1',
          isSynced: true,
          eventId: 'event1',
          calendarId: 'test-calendar-1',
        ),
        'req2': const CalendarSyncStatus(
          requestId: 'req2',
          isSynced: false,
        ),
        'req3': const CalendarSyncStatus(
          requestId: 'req3',
          isSynced: false,
          error: 'Permission denied',
        ),
      });

      // Test sync status retrieval
      final statusMap = await mockCalendarService.getCalendarSyncStatus(requestIds);

      // Verify status tracking
      expect(statusMap['req1']?.isSynced, isTrue);
      expect(statusMap['req1']?.eventId, equals('event1'));
      expect(statusMap['req2']?.isSynced, isFalse);
      expect(statusMap['req3']?.error, equals('Permission denied'));
      
      // Verify the mock was called correctly
      verify(mockCalendarService.getCalendarSyncStatus(requestIds)).called(1);
    });
  });
}

// Helper functions
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

ODRequest _createTestODRequest(String id, bool isApproved) {
  return ODRequest(
    id: id,
    studentId: 'student_123',
    studentName: 'Test Student',
    registerNumber: 'REG123',
    date: DateTime.now(),
    periods: [1, 2],
    reason: 'Test reason',
    status: isApproved ? 'approved' : 'pending',
    createdAt: DateTime.now(),
    approvedBy: isApproved ? 'Test Staff' : null,
    approvedAt: isApproved ? DateTime.now() : null,
  );
}