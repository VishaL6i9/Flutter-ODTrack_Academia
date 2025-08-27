import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:odtrack_academia/features/calendar_settings/calendar_settings_screen.dart';
import 'package:odtrack_academia/models/calendar_models.dart';
import 'package:odtrack_academia/providers/calendar_provider.dart';
import 'package:odtrack_academia/services/calendar/calendar_service.dart';

import 'calendar_settings_screen_test.mocks.dart';

// Generate mocks for the calendar service
@GenerateMocks([CalendarService])
void main() {
  group('CalendarSettingsScreen', () {
    late MockCalendarService mockCalendarService;

    setUp(() {
      mockCalendarService = MockCalendarService();
    });

    Widget createTestWidget({CalendarState? initialState}) {
      return ProviderScope(
        overrides: [
          calendarServiceProvider.overrideWithValue(mockCalendarService),
          if (initialState != null)
            calendarProvider.overrideWith((ref) {
              return CalendarNotifier(mockCalendarService)
                ..state = AsyncValue.data(initialState);
            }),
        ],
        child: const MaterialApp(
          home: CalendarSettingsScreen(),
        ),
      );
    }

    group('UI Components', () {
      testWidgets('should display loading indicator initially', (tester) async {
        // Setup
        when(mockCalendarService.initialize()).thenAnswer((_) async {});
        when(mockCalendarService.hasCalendarPermission()).thenAnswer((_) async => false);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => const CalendarSyncSettings(
          autoSyncEnabled: false,
          defaultCalendarId: '',
          syncApprovedOnly: true,
          includeRejectedEvents: false,
          reminderSettings: EventReminderSettings(
            enabled: true,
            minutesBefore: 15,
            reminderType: 'notification',
          ),
        ));

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display permission section when no permission', (tester) async {
        // Setup
        const testState = CalendarState(
          hasPermission: false,
          availableCalendars: [],
          syncSettings: CalendarSyncSettings(
            autoSyncEnabled: false,
            defaultCalendarId: '',
            syncApprovedOnly: true,
            includeRejectedEvents: false,
            reminderSettings: EventReminderSettings(
              enabled: true,
              minutesBefore: 15,
              reminderType: 'notification',
            ),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(initialState: testState));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Calendar Permission'), findsOneWidget);
        expect(find.text('Grant Permission'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });

      testWidgets('should display calendar settings when permission granted', (tester) async {
        // Setup
        const testCalendars = [
          Calendar(
            id: 'cal1',
            name: 'Test Calendar 1',
            isDefault: true,
          ),
          Calendar(
            id: 'cal2',
            name: 'Test Calendar 2',
          ),
        ];

        const testState = CalendarState(
          hasPermission: true,
          availableCalendars: testCalendars,
          syncSettings: CalendarSyncSettings(
            autoSyncEnabled: true,
            defaultCalendarId: 'cal1',
            syncApprovedOnly: true,
            includeRejectedEvents: false,
            reminderSettings: EventReminderSettings(
              enabled: true,
              minutesBefore: 15,
              reminderType: 'notification',
            ),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(initialState: testState));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Calendar Permission'), findsOneWidget);
        expect(find.text('Default Calendar'), findsOneWidget);
        expect(find.text('Sync Settings'), findsOneWidget);
        expect(find.text('Reminder Settings'), findsOneWidget);
        expect(find.text('Actions'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('should display sync settings switches', (tester) async {
        // Setup
        const testState = CalendarState(
          hasPermission: true,
          availableCalendars: [],
          syncSettings: CalendarSyncSettings(
            autoSyncEnabled: true,
            defaultCalendarId: 'cal1',
            syncApprovedOnly: false,
            includeRejectedEvents: true,
            reminderSettings: EventReminderSettings(
              enabled: true,
              minutesBefore: 30,
              reminderType: 'notification',
            ),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(initialState: testState));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Auto Sync'), findsOneWidget);
        expect(find.text('Sync Approved Only'), findsOneWidget);
        expect(find.text('Include Rejected Events'), findsOneWidget);
        expect(find.text('Enable Reminders'), findsOneWidget);
        
        // Check switch states
        final autoSyncSwitch = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'Auto Sync'),
        );
        expect(autoSyncSwitch.value, isTrue);

        final syncApprovedOnlySwitch = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'Sync Approved Only'),
        );
        expect(syncApprovedOnlySwitch.value, isFalse);

        final includeRejectedSwitch = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'Include Rejected Events'),
        );
        expect(includeRejectedSwitch.value, isTrue);
      });

      testWidgets('should display action buttons', (tester) async {
        // Setup
        const testState = CalendarState(
          hasPermission: true,
          availableCalendars: [],
          syncSettings: CalendarSyncSettings(
            autoSyncEnabled: false,
            defaultCalendarId: '',
            syncApprovedOnly: true,
            includeRejectedEvents: false,
            reminderSettings: EventReminderSettings(
              enabled: true,
              minutesBefore: 15,
              reminderType: 'notification',
            ),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(initialState: testState));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Sync All Events'), findsOneWidget);
        expect(find.text('Cleanup Events'), findsOneWidget);
      });

      testWidgets('should display error state', (tester) async {
        // Setup - create widget with error state
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              calendarServiceProvider.overrideWithValue(mockCalendarService),
              calendarProvider.overrideWith((ref) {
                return CalendarNotifier(mockCalendarService)
                  ..state = AsyncValue.error('Test error', StackTrace.current);
              }),
            ],
            child: const MaterialApp(
              home: CalendarSettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Error loading calendar settings'), findsOneWidget);
        expect(find.text('Test error'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('should show calendar dropdown when calendars available', (tester) async {
        // Setup
        const testCalendars = [
          Calendar(
            id: 'cal1',
            name: 'Personal Calendar',
            accountName: 'personal@example.com',
          ),
          Calendar(
            id: 'cal2',
            name: 'Work Calendar',
            accountName: 'work@example.com',
          ),
        ];

        const testState = CalendarState(
          hasPermission: true,
          availableCalendars: testCalendars,
          syncSettings: CalendarSyncSettings(
            autoSyncEnabled: false,
            defaultCalendarId: 'cal1',
            syncApprovedOnly: true,
            includeRejectedEvents: false,
            reminderSettings: EventReminderSettings(
              enabled: true,
              minutesBefore: 15,
              reminderType: 'notification',
            ),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(initialState: testState));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
        
        // Tap dropdown to open it
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();

        // Check dropdown items
        expect(find.text('Personal Calendar'), findsWidgets);
        expect(find.text('Work Calendar'), findsOneWidget);
      });

      testWidgets('should show reminder time dropdown when reminders enabled', (tester) async {
        // Setup
        const testState = CalendarState(
          hasPermission: true,
          availableCalendars: [],
          syncSettings: CalendarSyncSettings(
            autoSyncEnabled: false,
            defaultCalendarId: '',
            syncApprovedOnly: true,
            includeRejectedEvents: false,
            reminderSettings: EventReminderSettings(
              enabled: true,
              minutesBefore: 15,
              reminderType: 'notification',
            ),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(initialState: testState));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('15 minutes before'), findsOneWidget);
        expect(find.byType(DropdownButton<int>), findsOneWidget);
      });
    });
  });
}