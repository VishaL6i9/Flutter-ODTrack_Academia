import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:odtrack_academia/models/calendar_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/calendar/calendar_service.dart';
import 'package:odtrack_academia/services/calendar/calendar_sync_service.dart';

import 'calendar_sync_service_test.mocks.dart';

@GenerateMocks([CalendarService])
void main() {
  group('CalendarSyncService', () {
    late CalendarSyncService calendarSyncService;
    late MockCalendarService mockCalendarService;

    setUp(() {
      mockCalendarService = MockCalendarService();
      calendarSyncService = CalendarSyncService(mockCalendarService);
    });

    group('handleODRequestStatusChange', () {
      test('should skip sync when auto sync is disabled', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => false);
        
        final oldRequest = _createTestODRequest(status: 'pending');
        final newRequest = _createTestODRequest(status: 'approved');

        // Act
        await calendarSyncService.handleODRequestStatusChange(oldRequest, newRequest);

        // Assert
        verify(mockCalendarService.isAutoSyncEnabled()).called(1);
        verifyNoMoreInteractions(mockCalendarService);
      });

      test('should create calendar event when request becomes approved', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => _createTestSyncSettings());
        when(mockCalendarService.addODEventToCalendar(any, any)).thenAnswer((_) async {});
        
        final oldRequest = _createTestODRequest(status: 'pending');
        final newRequest = _createTestODRequest(status: 'approved');

        // Act
        await calendarSyncService.handleODRequestStatusChange(oldRequest, newRequest);

        // Assert
        verify(mockCalendarService.isAutoSyncEnabled()).called(1);
        verify(mockCalendarService.getSyncSettings()).called(1);
        verify(mockCalendarService.addODEventToCalendar(newRequest, 'test_calendar_id')).called(1);
      });

      test('should remove calendar event when request becomes rejected and includeRejectedEvents is false', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => _createTestSyncSettings(includeRejectedEvents: false));
        when(mockCalendarService.removeODEventByRequestId(any)).thenAnswer((_) async {});
        
        final oldRequest = _createTestODRequest(status: 'approved');
        final newRequest = _createTestODRequest(status: 'rejected');

        // Act
        await calendarSyncService.handleODRequestStatusChange(oldRequest, newRequest);

        // Assert
        verify(mockCalendarService.isAutoSyncEnabled()).called(1);
        verify(mockCalendarService.getSyncSettings()).called(1);
        verify(mockCalendarService.removeODEventByRequestId(newRequest.id)).called(1);
      });

      test('should update calendar event when approved request details change', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => _createTestSyncSettings());
        when(mockCalendarService.updateODEventInCalendar(any)).thenAnswer((_) async {});
        
        final oldRequest = _createTestODRequest(status: 'approved', reason: 'Old reason');
        final newRequest = _createTestODRequest(status: 'approved', reason: 'New reason');

        // Act
        await calendarSyncService.handleODRequestStatusChange(oldRequest, newRequest);

        // Assert
        verify(mockCalendarService.isAutoSyncEnabled()).called(1);
        verify(mockCalendarService.getSyncSettings()).called(1);
        verify(mockCalendarService.updateODEventInCalendar(newRequest)).called(1);
      });

      test('should handle rejected events when includeRejectedEvents is true', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => _createTestSyncSettings(includeRejectedEvents: true));
        when(mockCalendarService.addODEventToCalendar(any, any)).thenAnswer((_) async {});
        
        final oldRequest = _createTestODRequest(status: 'pending');
        final newRequest = _createTestODRequest(status: 'rejected');

        // Act
        await calendarSyncService.handleODRequestStatusChange(oldRequest, newRequest);

        // Assert
        verify(mockCalendarService.isAutoSyncEnabled()).called(1);
        verify(mockCalendarService.getSyncSettings()).called(1);
        verify(mockCalendarService.addODEventToCalendar(newRequest, 'test_calendar_id')).called(1);
      });
    });

    group('handleODRequestCreation', () {
      test('should skip sync when auto sync is disabled', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => false);
        
        final request = _createTestODRequest(status: 'approved');

        // Act
        await calendarSyncService.handleODRequestCreation(request);

        // Assert
        verify(mockCalendarService.isAutoSyncEnabled()).called(1);
        verifyNoMoreInteractions(mockCalendarService);
      });

      test('should create calendar event for approved request', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => _createTestSyncSettings());
        when(mockCalendarService.addODEventToCalendar(any, any)).thenAnswer((_) async {});
        
        final request = _createTestODRequest(status: 'approved');

        // Act
        await calendarSyncService.handleODRequestCreation(request);

        // Assert
        verify(mockCalendarService.isAutoSyncEnabled()).called(1);
        verify(mockCalendarService.getSyncSettings()).called(1);
        verify(mockCalendarService.addODEventToCalendar(request, 'test_calendar_id')).called(1);
      });

      test('should not create calendar event for pending request when syncApprovedOnly is true', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => _createTestSyncSettings(syncApprovedOnly: true));
        
        final request = _createTestODRequest(status: 'pending');

        // Act
        await calendarSyncService.handleODRequestCreation(request);

        // Assert
        verify(mockCalendarService.isAutoSyncEnabled()).called(1);
        verify(mockCalendarService.getSyncSettings()).called(1);
        verifyNever(mockCalendarService.addODEventToCalendar(any, any));
      });
    });

    group('handleODRequestDeletion', () {
      test('should remove calendar event when request is deleted', () async {
        // Arrange
        when(mockCalendarService.removeODEventByRequestId(any)).thenAnswer((_) async {});
        
        final request = _createTestODRequest(status: 'approved');

        // Act
        await calendarSyncService.handleODRequestDeletion(request);

        // Assert
        verify(mockCalendarService.removeODEventByRequestId(request.id)).called(1);
      });

      test('should handle errors gracefully when removing non-existent event', () async {
        // Arrange
        when(mockCalendarService.removeODEventByRequestId(any))
            .thenThrow(Exception('Event not found'));
        
        final request = _createTestODRequest(status: 'approved');

        // Act & Assert - should not throw
        await calendarSyncService.handleODRequestDeletion(request);
        
        verify(mockCalendarService.removeODEventByRequestId(request.id)).called(1);
      });
    });

    group('syncAllODRequests', () {
      test('should skip sync when auto sync is disabled', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => false);
        
        final requests = [_createTestODRequest(status: 'approved')];

        // Act
        await calendarSyncService.syncAllODRequests(requests);

        // Assert
        verify(mockCalendarService.isAutoSyncEnabled()).called(1);
        verifyNoMoreInteractions(mockCalendarService);
      });

      test('should sync all eligible requests', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => _createTestSyncSettings());
        when(mockCalendarService.updateODEventInCalendar(any)).thenAnswer((_) async {});
        when(mockCalendarService.addODEventToCalendar(any, any)).thenAnswer((_) async {});
        
        final requests = [
          _createTestODRequest(id: '1', status: 'approved'),
          _createTestODRequest(id: '2', status: 'pending'),
          _createTestODRequest(id: '3', status: 'approved'),
        ];

        // Act
        await calendarSyncService.syncAllODRequests(requests);

        // Assert
        verify(mockCalendarService.isAutoSyncEnabled()).called(1);
        verify(mockCalendarService.getSyncSettings()).called(1);
        // Should try to update first, then create if update fails
        verify(mockCalendarService.updateODEventInCalendar(requests[0])).called(1);
        verify(mockCalendarService.updateODEventInCalendar(requests[2])).called(1);
        // Pending request should not be synced when syncApprovedOnly is true
        verifyNever(mockCalendarService.updateODEventInCalendar(requests[1]));
      });

      test('should continue syncing other requests when one fails', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => _createTestSyncSettings());
        when(mockCalendarService.updateODEventInCalendar(any))
            .thenThrow(Exception('Update failed'));
        when(mockCalendarService.addODEventToCalendar(any, any)).thenAnswer((_) async {});
        
        final requests = [
          _createTestODRequest(id: '1', status: 'approved'),
          _createTestODRequest(id: '2', status: 'approved'),
        ];

        // Act
        await calendarSyncService.syncAllODRequests(requests);

        // Assert
        verify(mockCalendarService.isAutoSyncEnabled()).called(1);
        verify(mockCalendarService.getSyncSettings()).called(1);
        verify(mockCalendarService.updateODEventInCalendar(requests[0])).called(1);
        verify(mockCalendarService.updateODEventInCalendar(requests[1])).called(1);
        verify(mockCalendarService.addODEventToCalendar(requests[0], 'test_calendar_id')).called(1);
        verify(mockCalendarService.addODEventToCalendar(requests[1], 'test_calendar_id')).called(1);
      });
    });

    group('error handling', () {
      test('should rethrow errors from calendar service during status change', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => _createTestSyncSettings());
        when(mockCalendarService.addODEventToCalendar(any, any))
            .thenThrow(Exception('Calendar service error'));
        
        final oldRequest = _createTestODRequest(status: 'pending');
        final newRequest = _createTestODRequest(status: 'approved');

        // Act & Assert
        expect(
          () => calendarSyncService.handleODRequestStatusChange(oldRequest, newRequest),
          throwsException,
        );
      });

      test('should rethrow errors from calendar service during creation', () async {
        // Arrange
        when(mockCalendarService.isAutoSyncEnabled()).thenAnswer((_) async => true);
        when(mockCalendarService.getSyncSettings()).thenAnswer((_) async => _createTestSyncSettings());
        when(mockCalendarService.addODEventToCalendar(any, any))
            .thenThrow(Exception('Calendar service error'));
        
        final request = _createTestODRequest(status: 'approved');

        // Act & Assert
        expect(
          () => calendarSyncService.handleODRequestCreation(request),
          throwsException,
        );
      });
    });
  });
}

// Helper functions for creating test data
ODRequest _createTestODRequest({
  String? id,
  String status = 'pending',
  String reason = 'Test reason',
}) {
  return ODRequest(
    id: id ?? 'test_id',
    studentId: 'student_123',
    studentName: 'Test Student',
    registerNumber: '123456789',
    date: DateTime.now().add(const Duration(days: 1)),
    periods: [1, 2, 3],
    reason: reason,
    status: status,
    createdAt: DateTime.now(),
  );
}

CalendarSyncSettings _createTestSyncSettings({
  bool autoSyncEnabled = true,
  String defaultCalendarId = 'test_calendar_id',
  bool syncApprovedOnly = true,
  bool includeRejectedEvents = false,
}) {
  return CalendarSyncSettings(
    autoSyncEnabled: autoSyncEnabled,
    defaultCalendarId: defaultCalendarId,
    syncApprovedOnly: syncApprovedOnly,
    includeRejectedEvents: includeRejectedEvents,
    reminderSettings: const EventReminderSettings(
      enabled: true,
      minutesBefore: 15,
      reminderType: 'notification',
    ),
  );
}