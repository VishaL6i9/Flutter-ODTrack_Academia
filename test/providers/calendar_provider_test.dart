import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:odtrack_academia/models/calendar_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/providers/calendar_provider.dart';
import 'package:odtrack_academia/services/calendar/calendar_service.dart';

import 'calendar_provider_test.mocks.dart';

// Generate mocks for the calendar service
@GenerateMocks([CalendarService])
void main() {
  group('CalendarProvider', () {
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

    group('initialization', () {
      test('should initialize successfully with permission granted', () async {
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

        const testSettings = CalendarSyncSettings(
          autoSyncEnabled: false,
          defaultCalendarId: 'cal1',
          syncApprovedOnly: true,
          includeRejectedEvents: false,
          reminderSettings: EventReminderSettings(
            enabled: true,
            minutesBefore: 15,
            reminderType: 'notification',
          ),
        );

        when(mockCalendarService.initialize()).thenAnswer((_) async {});
        when(mockCalendarService.hasCalendarPermission()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => testSettings);
        when(mockCalendarService.getAvailableCalendars()).thenAnswer((_) async => testCalendars);

        // Act
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Assert
        final state = container.read(calendarProvider);
        expect(state.hasValue, isTrue);
        
        final calendarState = state.value!;
        expect(calendarState.hasPermission, isTrue);
        expect(calendarState.availableCalendars, hasLength(2));
        expect(calendarState.availableCalendars[0].id, equals('cal1'));
        expect(calendarState.syncSettings?.defaultCalendarId, equals('cal1'));
        
        verify(mockCalendarService.initialize()).called(1);
        verify(mockCalendarService.hasCalendarPermission()).called(1);
        verify(mockCalendarService.getSyncSettings()).called(1);
        verify(mockCalendarService.getAvailableCalendars()).called(1);
      });

      test('should initialize with permission denied', () async {
        // Setup
        const testSettings = CalendarSyncSettings(
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

        when(mockCalendarService.initialize()).thenAnswer((_) async {});
        when(mockCalendarService.hasCalendarPermission()).thenAnswer((_) async => false);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => testSettings);

        // Act
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Assert
        final state = container.read(calendarProvider);
        expect(state.hasValue, isTrue);
        
        final calendarState = state.value!;
        expect(calendarState.hasPermission, isFalse);
        expect(calendarState.availableCalendars, isEmpty);
        
        verify(mockCalendarService.initialize()).called(1);
        verify(mockCalendarService.hasCalendarPermission()).called(1);
        verify(mockCalendarService.getSyncSettings()).called(1);
        verifyNever(mockCalendarService.getAvailableCalendars());
      });

      test('should handle initialization error', () async {
        // Setup
        when(mockCalendarService.initialize()).thenThrow(Exception('Initialization failed'));

        // Act
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Assert
        final state = container.read(calendarProvider);
        expect(state.hasError, isTrue);
        expect(state.error.toString(), contains('Initialization failed'));
      });
    });

    group('permission management', () {
      test('should request permission successfully', () async {
        // Setup initial state
        const initialSettings = CalendarSyncSettings(
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

        const testCalendars = [
          Calendar(id: 'cal1', name: 'Test Calendar'),
        ];

        when(mockCalendarService.initialize()).thenAnswer((_) async {});
        when(mockCalendarService.hasCalendarPermission()).thenAnswer((_) async => false);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => initialSettings);
        when(mockCalendarService.requestCalendarPermission()).thenAnswer((_) async => true);
        when(mockCalendarService.getAvailableCalendars()).thenAnswer((_) async => testCalendars);

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act
        await notifier.requestPermission();

        // Assert
        final state = container.read(calendarProvider);
        expect(state.hasValue, isTrue);
        
        final calendarState = state.value!;
        expect(calendarState.hasPermission, isTrue);
        expect(calendarState.availableCalendars, hasLength(1));
        
        verify(mockCalendarService.requestCalendarPermission()).called(1);
        verify(mockCalendarService.getAvailableCalendars()).called(1);
      });

      test('should handle permission denial', () async {
        // Setup initial state
        const initialSettings = CalendarSyncSettings(
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

        when(mockCalendarService.initialize()).thenAnswer((_) async {});
        when(mockCalendarService.hasCalendarPermission()).thenAnswer((_) async => false);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => initialSettings);
        when(mockCalendarService.requestCalendarPermission()).thenAnswer((_) async => false);

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act
        await notifier.requestPermission();

        // Assert
        final state = container.read(calendarProvider);
        expect(state.hasValue, isTrue);
        
        final calendarState = state.value!;
        expect(calendarState.hasPermission, isFalse);
        expect(calendarState.error, equals('Calendar permission denied'));
        
        verify(mockCalendarService.requestCalendarPermission()).called(1);
        verifyNever(mockCalendarService.getAvailableCalendars());
      });
    });

    group('settings management', () {
      late CalendarSyncSettings initialSettings;

      setUp(() {
        initialSettings = const CalendarSyncSettings(
          autoSyncEnabled: false,
          defaultCalendarId: 'cal1',
          syncApprovedOnly: true,
          includeRejectedEvents: false,
          reminderSettings: EventReminderSettings(
            enabled: true,
            minutesBefore: 15,
            reminderType: 'notification',
          ),
        );

        // Setup common mocks
        when(mockCalendarService.initialize()).thenAnswer((_) async {});
        when(mockCalendarService.hasCalendarPermission()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => initialSettings);
        when(mockCalendarService.getAvailableCalendars()).thenAnswer((_) async => []);
      });

      test('should update default calendar', () async {
        // Setup
        const newCalendarId = 'cal2';
        when(mockCalendarService.updateSyncSettings(any)).thenAnswer((_) async {});

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act
        await notifier.updateDefaultCalendar(newCalendarId);

        // Assert
        final state = container.read(calendarProvider);
        final calendarState = state.value!;
        expect(calendarState.syncSettings?.defaultCalendarId, equals(newCalendarId));
        
        verify(mockCalendarService.updateSyncSettings(any)).called(1);
      });

      test('should update auto sync setting', () async {
        // Setup
        when(mockCalendarService.updateSyncSettings(any)).thenAnswer((_) async {});

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act
        await notifier.updateAutoSync(true);

        // Assert
        final state = container.read(calendarProvider);
        final calendarState = state.value!;
        expect(calendarState.syncSettings?.autoSyncEnabled, isTrue);
        
        verify(mockCalendarService.updateSyncSettings(any)).called(1);
      });

      test('should update sync approved only setting', () async {
        // Setup
        when(mockCalendarService.updateSyncSettings(any)).thenAnswer((_) async {});

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act
        await notifier.updateSyncApprovedOnly(false);

        // Assert
        final state = container.read(calendarProvider);
        final calendarState = state.value!;
        expect(calendarState.syncSettings?.syncApprovedOnly, isFalse);
        
        verify(mockCalendarService.updateSyncSettings(any)).called(1);
      });

      test('should update reminder settings', () async {
        // Setup
        when(mockCalendarService.updateSyncSettings(any)).thenAnswer((_) async {});

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act
        await notifier.updateReminderEnabled(false);
        await notifier.updateReminderTime(30);

        // Assert
        final state = container.read(calendarProvider);
        final calendarState = state.value!;
        expect(calendarState.syncSettings?.reminderSettings.enabled, isFalse);
        expect(calendarState.syncSettings?.reminderSettings.minutesBefore, equals(30));
        
        verify(mockCalendarService.updateSyncSettings(any)).called(2);
      });
    });

    group('OD event operations', () {
      late ODRequest testODRequest;
      late CalendarSyncSettings testSettings;

      setUp(() {
        testODRequest = ODRequest(
          id: 'test-od-1',
          studentId: 'student-1',
          studentName: 'John Doe',
          registerNumber: 'REG001',
          date: DateTime.parse('2024-01-15T00:00:00.000Z'),
          periods: const [1, 2, 3],
          reason: 'Medical appointment',
          status: 'approved',
          createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        );

        testSettings = const CalendarSyncSettings(
          autoSyncEnabled: true,
          defaultCalendarId: 'cal1',
          syncApprovedOnly: true,
          includeRejectedEvents: false,
          reminderSettings: EventReminderSettings(
            enabled: true,
            minutesBefore: 15,
            reminderType: 'notification',
          ),
        );

        // Setup common mocks
        when(mockCalendarService.initialize()).thenAnswer((_) async {});
        when(mockCalendarService.hasCalendarPermission()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => testSettings);
        when(mockCalendarService.getAvailableCalendars()).thenAnswer((_) async => []);
      });

      test('should add OD event to calendar', () async {
        // Setup
        when(mockCalendarService.addODEventToCalendar(any, any)).thenAnswer((_) async {});

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act
        await notifier.addODEventToCalendar(testODRequest);

        // Assert
        verify(mockCalendarService.addODEventToCalendar(testODRequest, 'cal1')).called(1);
      });

      test('should throw exception when no calendar selected', () async {
        // Setup - settings with empty default calendar
        final settingsWithoutCalendar = testSettings.copyWith(defaultCalendarId: '');
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => settingsWithoutCalendar);

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act & Assert
        expect(
          () => notifier.addODEventToCalendar(testODRequest),
          throwsException,
        );
      });

      test('should update OD event in calendar', () async {
        // Setup
        when(mockCalendarService.updateODEventInCalendar(any)).thenAnswer((_) async {});

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act
        await notifier.updateODEventInCalendar(testODRequest);

        // Assert
        verify(mockCalendarService.updateODEventInCalendar(testODRequest)).called(1);
      });

      test('should remove OD event from calendar', () async {
        // Setup
        const eventId = 'test-event-1';
        when(mockCalendarService.removeODEventFromCalendar(any)).thenAnswer((_) async {});

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act
        await notifier.removeODEventFromCalendar(eventId);

        // Assert
        verify(mockCalendarService.removeODEventFromCalendar(eventId)).called(1);
      });
    });

    group('bulk operations', () {
      setUp(() {
        const testSettings = CalendarSyncSettings(
          autoSyncEnabled: true,
          defaultCalendarId: 'cal1',
          syncApprovedOnly: true,
          includeRejectedEvents: false,
          reminderSettings: EventReminderSettings(
            enabled: true,
            minutesBefore: 15,
            reminderType: 'notification',
          ),
        );

        // Setup common mocks
        when(mockCalendarService.initialize()).thenAnswer((_) async {});
        when(mockCalendarService.hasCalendarPermission()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => testSettings);
        when(mockCalendarService.getAvailableCalendars()).thenAnswer((_) async => []);
      });

      test('should sync all events', () async {
        // Setup
        when(mockCalendarService.syncAllODEventsToCalendar()).thenAnswer((_) async {});

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act
        await notifier.syncAllEvents();

        // Assert
        verify(mockCalendarService.syncAllODEventsToCalendar()).called(1);
      });

      test('should cleanup all events', () async {
        // Setup
        when(mockCalendarService.cleanupODEventsFromCalendar()).thenAnswer((_) async {});

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act
        await notifier.cleanupAllEvents();

        // Assert
        verify(mockCalendarService.cleanupODEventsFromCalendar()).called(1);
      });

      test('should check auto sync status', () async {
        // Setup
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);

        // Initialize first
        final notifier = container.read(calendarProvider.notifier);
        await notifier.initialize();

        // Act
        final isEnabled = await notifier.isAutoSyncEnabled();

        // Assert
        expect(isEnabled, isTrue);
        verify(mockCalendarService.isAutoSyncEnabled()).called(1);
      });
    });
  });
}

// Extension to add copyWith method to CalendarSyncSettings for testing
extension CalendarSyncSettingsTest on CalendarSyncSettings {
  CalendarSyncSettings copyWith({
    bool? autoSyncEnabled,
    String? defaultCalendarId,
    bool? syncApprovedOnly,
    bool? includeRejectedEvents,
    EventReminderSettings? reminderSettings,
  }) {
    return CalendarSyncSettings(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      defaultCalendarId: defaultCalendarId ?? this.defaultCalendarId,
      syncApprovedOnly: syncApprovedOnly ?? this.syncApprovedOnly,
      includeRejectedEvents: includeRejectedEvents ?? this.includeRejectedEvents,
      reminderSettings: reminderSettings ?? this.reminderSettings,
    );
  }
}