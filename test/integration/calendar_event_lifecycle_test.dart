import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:odtrack_academia/models/calendar_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/calendar/calendar_service.dart';
import 'package:odtrack_academia/services/calendar/calendar_sync_service.dart';
import 'package:odtrack_academia/providers/od_request_provider.dart';

import 'calendar_event_lifecycle_test.mocks.dart';

@GenerateMocks([CalendarService])
void main() {
  group('Calendar Event Lifecycle Integration Tests', () {
    late MockCalendarService mockCalendarService;
    late CalendarSyncService calendarSyncService;
    late ODRequestNotifier odRequestNotifier;

    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('test/hive_test_db');
    });

    setUp(() async {
      mockCalendarService = MockCalendarService();
      calendarSyncService = CalendarSyncService(mockCalendarService);
      odRequestNotifier = ODRequestNotifier(calendarSyncService: calendarSyncService);

      // Setup mock responses
      when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
      when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => const CalendarSyncSettings(
        autoSyncEnabled: true,
        defaultCalendarId: 'test_calendar_id',
        syncApprovedOnly: true,
        includeRejectedEvents: false,
        reminderSettings: EventReminderSettings(
          enabled: true,
          minutesBefore: 15,
          reminderType: 'notification',
        ),
      ));
      when(mockCalendarService.addODEventToCalendar(any, any)).thenAnswer((_) async {});
      when(mockCalendarService.updateODEventInCalendar(any)).thenAnswer((_) async {});
      when(mockCalendarService.removeODEventByRequestId(any)).thenAnswer((_) async {});
    });

    tearDown(() async {
      // Clean up Hive boxes
      try {
        await Hive.deleteBoxFromDisk('calendar_events_box');
        await Hive.deleteBoxFromDisk('calendar_settings_box');
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('OD Request Creation Lifecycle', () {
      test('should create calendar event when approved OD request is created', () async {
        // Arrange
        final approvedRequest = ODRequest(
          id: 'test_request_1',
          studentId: 'student_123',
          studentName: 'Test Student',
          registerNumber: '123456789',
          date: DateTime.now().add(const Duration(days: 1)),
          periods: [1, 2, 3],
          reason: 'Medical appointment',
          status: 'approved',
          createdAt: DateTime.now(),
          approvedAt: DateTime.now(),
          approvedBy: 'Test Staff',
        );

        // Act
        await odRequestNotifier.createRequest(approvedRequest);

        // Assert
        verify(mockCalendarService.addODEventToCalendar(approvedRequest, 'test_calendar_id')).called(1);
        
        // Verify the request was added to the state
        final requests = odRequestNotifier.state;
        expect(requests.length, equals(4)); // 3 demo + 1 new
        expect(requests.first.id, equals('test_request_1'));
      });

      test('should not create calendar event when pending OD request is created', () async {
        // Arrange
        final pendingRequest = ODRequest(
          id: 'test_request_2',
          studentId: 'student_123',
          studentName: 'Test Student',
          registerNumber: '123456789',
          date: DateTime.now().add(const Duration(days: 1)),
          periods: [1, 2, 3],
          reason: 'Personal work',
          status: 'pending',
          createdAt: DateTime.now(),
        );

        // Act
        await odRequestNotifier.createRequest(pendingRequest);

        // Assert
        verifyNever(mockCalendarService.addODEventToCalendar(any, any));
        
        // Verify the request was added to the state
        final requests = odRequestNotifier.state;
        expect(requests.length, equals(4)); // 3 demo + 1 new
        expect(requests.first.id, equals('test_request_2'));
      });
    });

    group('OD Request Status Change Lifecycle', () {
      test('should create calendar event when request is approved', () async {
        // Arrange - create a pending request first
        final pendingRequest = ODRequest(
          id: 'test_request_3',
          studentId: 'student_123',
          studentName: 'Test Student',
          registerNumber: '123456789',
          date: DateTime.now().add(const Duration(days: 1)),
          periods: [1, 2, 3],
          reason: 'Family function',
          status: 'pending',
          createdAt: DateTime.now(),
        );
        
        await odRequestNotifier.createRequest(pendingRequest);
        reset(mockCalendarService); // Reset to clear the creation call
        
        // Setup mock for approval
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => const CalendarSyncSettings(
          autoSyncEnabled: true,
          defaultCalendarId: 'test_calendar_id',
          syncApprovedOnly: true,
          includeRejectedEvents: false,
          reminderSettings: EventReminderSettings(
            enabled: true,
            minutesBefore: 15,
            reminderType: 'notification',
          ),
        ));
        when(mockCalendarService.addODEventToCalendar(any, any)).thenAnswer((_) async {});

        // Act - approve the request
        await odRequestNotifier.updateRequestStatus('test_request_3', 'approved');

        // Assert
        verify(mockCalendarService.addODEventToCalendar(any, 'test_calendar_id')).called(1);
        
        // Verify the request status was updated
        final requests = odRequestNotifier.state;
        final updatedRequest = requests.firstWhere((r) => r.id == 'test_request_3');
        expect(updatedRequest.status, equals('approved'));
        expect(updatedRequest.approvedAt, isNotNull);
        expect(updatedRequest.approvedBy, equals('Demo Staff'));
      });

      test('should remove calendar event when approved request is rejected', () async {
        // Arrange - create an approved request first
        final approvedRequest = ODRequest(
          id: 'test_request_4',
          studentId: 'student_123',
          studentName: 'Test Student',
          registerNumber: '123456789',
          date: DateTime.now().add(const Duration(days: 1)),
          periods: [1, 2, 3],
          reason: 'Medical appointment',
          status: 'approved',
          createdAt: DateTime.now(),
          approvedAt: DateTime.now(),
          approvedBy: 'Test Staff',
        );
        
        await odRequestNotifier.createRequest(approvedRequest);
        reset(mockCalendarService); // Reset to clear the creation call
        
        // Setup mock for rejection
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => const CalendarSyncSettings(
          autoSyncEnabled: true,
          defaultCalendarId: 'test_calendar_id',
          syncApprovedOnly: true,
          includeRejectedEvents: false,
          reminderSettings: EventReminderSettings(
            enabled: true,
            minutesBefore: 15,
            reminderType: 'notification',
          ),
        ));
        when(mockCalendarService.removeODEventByRequestId(any)).thenAnswer((_) async {});

        // Act - reject the request
        await odRequestNotifier.updateRequestStatus('test_request_4', 'rejected', reason: 'Insufficient documentation');

        // Assert
        verify(mockCalendarService.removeODEventByRequestId('test_request_4')).called(1);
        
        // Verify the request status was updated
        final requests = odRequestNotifier.state;
        final updatedRequest = requests.firstWhere((r) => r.id == 'test_request_4');
        expect(updatedRequest.status, equals('rejected'));
        expect(updatedRequest.rejectionReason, equals('Insufficient documentation'));
      });

      test('should update calendar event when approved request details change', () async {
        // Arrange - create an approved request first
        final approvedRequest = ODRequest(
          id: 'test_request_5',
          studentId: 'student_123',
          studentName: 'Test Student',
          registerNumber: '123456789',
          date: DateTime.now().add(const Duration(days: 1)),
          periods: [1, 2, 3],
          reason: 'Original reason',
          status: 'approved',
          createdAt: DateTime.now(),
          approvedAt: DateTime.now(),
          approvedBy: 'Test Staff',
        );
        
        await odRequestNotifier.createRequest(approvedRequest);
        reset(mockCalendarService); // Reset to clear the creation call
        
        // Setup mock for update
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => const CalendarSyncSettings(
          autoSyncEnabled: true,
          defaultCalendarId: 'test_calendar_id',
          syncApprovedOnly: true,
          includeRejectedEvents: false,
          reminderSettings: EventReminderSettings(
            enabled: true,
            minutesBefore: 15,
            reminderType: 'notification',
          ),
        ));
        when(mockCalendarService.updateODEventInCalendar(any)).thenAnswer((_) async {});

        // Act - update the request (simulate a re-approval with same status)
        await odRequestNotifier.updateRequestStatus('test_request_5', 'approved');

        // Assert
        verify(mockCalendarService.updateODEventInCalendar(any)).called(1);
        
        // Verify the request was updated
        final requests = odRequestNotifier.state;
        final updatedRequest = requests.firstWhere((r) => r.id == 'test_request_5');
        expect(updatedRequest.status, equals('approved'));
      });
    });

    group('OD Request Deletion Lifecycle', () {
      test('should remove calendar event when OD request is deleted', () async {
        // Arrange - create an approved request first
        final approvedRequest = ODRequest(
          id: 'test_request_6',
          studentId: 'student_123',
          studentName: 'Test Student',
          registerNumber: '123456789',
          date: DateTime.now().add(const Duration(days: 1)),
          periods: [1, 2, 3],
          reason: 'Medical appointment',
          status: 'approved',
          createdAt: DateTime.now(),
          approvedAt: DateTime.now(),
          approvedBy: 'Test Staff',
        );
        
        await odRequestNotifier.createRequest(approvedRequest);
        reset(mockCalendarService); // Reset to clear the creation call
        
        // Setup mock for deletion
        when(mockCalendarService.removeODEventByRequestId(any)).thenAnswer((_) async {});

        // Act - delete the request
        await odRequestNotifier.deleteRequest('test_request_6');

        // Assert
        verify(mockCalendarService.removeODEventByRequestId('test_request_6')).called(1);
        
        // Verify the request was removed from state
        final requests = odRequestNotifier.state;
        expect(requests.where((r) => r.id == 'test_request_6'), isEmpty);
      });
    });

    group('Bulk Sync Operations', () {
      test('should sync all eligible requests when syncAllRequestsWithCalendar is called', () async {
        // Arrange - add some test requests
        final requests = [
          ODRequest(
            id: 'bulk_test_1',
            studentId: 'student_123',
            studentName: 'Test Student 1',
            registerNumber: '123456789',
            date: DateTime.now().add(const Duration(days: 1)),
            periods: [1, 2],
            reason: 'Medical appointment',
            status: 'approved',
            createdAt: DateTime.now(),
            approvedAt: DateTime.now(),
            approvedBy: 'Test Staff',
          ),
          ODRequest(
            id: 'bulk_test_2',
            studentId: 'student_124',
            studentName: 'Test Student 2',
            registerNumber: '123456790',
            date: DateTime.now().add(const Duration(days: 2)),
            periods: [3, 4],
            reason: 'Family function',
            status: 'pending',
            createdAt: DateTime.now(),
          ),
          ODRequest(
            id: 'bulk_test_3',
            studentId: 'student_125',
            studentName: 'Test Student 3',
            registerNumber: '123456791',
            date: DateTime.now().add(const Duration(days: 3)),
            periods: [5, 6],
            reason: 'Personal work',
            status: 'approved',
            createdAt: DateTime.now(),
            approvedAt: DateTime.now(),
            approvedBy: 'Test Staff',
          ),
        ];

        for (final request in requests) {
          await odRequestNotifier.createRequest(request);
        }
        
        reset(mockCalendarService); // Reset to clear the creation calls
        
        // Setup mocks for sync
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => const CalendarSyncSettings(
          autoSyncEnabled: true,
          defaultCalendarId: 'test_calendar_id',
          syncApprovedOnly: true,
          includeRejectedEvents: false,
          reminderSettings: EventReminderSettings(
            enabled: true,
            minutesBefore: 15,
            reminderType: 'notification',
          ),
        ));
        when(mockCalendarService.updateODEventInCalendar(any)).thenThrow(Exception('Update failed'));
        when(mockCalendarService.addODEventToCalendar(any, any)).thenAnswer((_) async {});

        // Act - sync all requests
        await odRequestNotifier.syncAllRequestsWithCalendar();

        // Assert - should only sync approved requests (2 out of 3) plus the 3 demo requests that are approved
        // The demo requests include 1 approved request, so total should be 3 approved requests
        verify(mockCalendarService.updateODEventInCalendar(any)).called(3);
        verify(mockCalendarService.addODEventToCalendar(any, 'test_calendar_id')).called(3);
      });
    });

    group('Error Handling', () {
      test('should handle calendar service errors gracefully during request creation', () async {
        // Arrange
        when(mockCalendarService.addODEventToCalendar(any, any))
            .thenThrow(Exception('Calendar service error'));
        
        final approvedRequest = ODRequest(
          id: 'error_test_1',
          studentId: 'student_123',
          studentName: 'Test Student',
          registerNumber: '123456789',
          date: DateTime.now().add(const Duration(days: 1)),
          periods: [1, 2, 3],
          reason: 'Medical appointment',
          status: 'approved',
          createdAt: DateTime.now(),
          approvedAt: DateTime.now(),
          approvedBy: 'Test Staff',
        );

        // Act & Assert - should not throw, request should still be created
        await odRequestNotifier.createRequest(approvedRequest);
        
        // Verify the request was added despite calendar error
        final requests = odRequestNotifier.state;
        expect(requests.any((r) => r.id == 'error_test_1'), isTrue);
      });

      test('should handle calendar service errors gracefully during status update', () async {
        // Arrange - create a pending request first
        final pendingRequest = ODRequest(
          id: 'error_test_2',
          studentId: 'student_123',
          studentName: 'Test Student',
          registerNumber: '123456789',
          date: DateTime.now().add(const Duration(days: 1)),
          periods: [1, 2, 3],
          reason: 'Family function',
          status: 'pending',
          createdAt: DateTime.now(),
        );
        
        await odRequestNotifier.createRequest(pendingRequest);
        
        // Setup mock to throw error on calendar event creation
        when(mockCalendarService.addODEventToCalendar(any, any))
            .thenThrow(Exception('Calendar service error'));

        // Act & Assert - should not throw, status should still be updated
        await odRequestNotifier.updateRequestStatus('error_test_2', 'approved');
        
        // Verify the status was updated despite calendar error
        final requests = odRequestNotifier.state;
        final updatedRequest = requests.firstWhere((r) => r.id == 'error_test_2');
        expect(updatedRequest.status, equals('approved'));
      });
    });

    group('Sync Settings Integration', () {
      test('should respect syncApprovedOnly setting', () async {
        // Arrange - disable syncApprovedOnly
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => const CalendarSyncSettings(
          autoSyncEnabled: true,
          defaultCalendarId: 'test_calendar_id',
          syncApprovedOnly: false,
          includeRejectedEvents: false,
          reminderSettings: EventReminderSettings(
            enabled: true,
            minutesBefore: 15,
            reminderType: 'notification',
          ),
        ));
        
        final pendingRequest = ODRequest(
          id: 'sync_setting_test_1',
          studentId: 'student_123',
          studentName: 'Test Student',
          registerNumber: '123456789',
          date: DateTime.now().add(const Duration(days: 1)),
          periods: [1, 2, 3],
          reason: 'Personal work',
          status: 'pending',
          createdAt: DateTime.now(),
        );

        // Act
        await odRequestNotifier.createRequest(pendingRequest);

        // Assert - should create calendar event for pending request when syncApprovedOnly is false
        verify(mockCalendarService.addODEventToCalendar(pendingRequest, 'test_calendar_id')).called(1);
      });

      test('should respect includeRejectedEvents setting', () async {
        // Arrange - enable includeRejectedEvents
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => const CalendarSyncSettings(
          autoSyncEnabled: true,
          defaultCalendarId: 'test_calendar_id',
          syncApprovedOnly: false,
          includeRejectedEvents: true,
          reminderSettings: EventReminderSettings(
            enabled: true,
            minutesBefore: 15,
            reminderType: 'notification',
          ),
        ));
        
        final rejectedRequest = ODRequest(
          id: 'sync_setting_test_2',
          studentId: 'student_123',
          studentName: 'Test Student',
          registerNumber: '123456789',
          date: DateTime.now().add(const Duration(days: 1)),
          periods: [1, 2, 3],
          reason: 'Personal work',
          status: 'rejected',
          createdAt: DateTime.now(),
          rejectionReason: 'Insufficient documentation',
        );

        // Act
        await odRequestNotifier.createRequest(rejectedRequest);

        // Assert - should create calendar event for rejected request when includeRejectedEvents is true
        verify(mockCalendarService.addODEventToCalendar(rejectedRequest, 'test_calendar_id')).called(1);
      });
    });
  });
}

