import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:go_router/go_router.dart';
import 'package:odtrack_academia/services/notification/notification_router.dart';
import 'package:odtrack_academia/models/notification_message.dart';

import 'notification_router_test.mocks.dart';

@GenerateMocks([GoRouter])
void main() {
  group('NotificationRouter', () {
    late MockGoRouter mockRouter;

    setUp(() {
      mockRouter = MockGoRouter();
    });

    group('Route Determination', () {
      test('should route to action URL when provided', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'Test',
          body: 'Test body',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: DateTime.now(),
          actionUrl: '/custom-route',
        );

        // Act
        await NotificationRouter.routeFromNotification(mockRouter, notification);

        // Assert
        verify(mockRouter.go('/custom-route')).called(1);
      });

      test('should route to OD request details for status change notifications', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'OD Status Changed',
          body: 'Your OD request has been approved',
          type: NotificationType.odStatusChange,
          data: {'request_id': '123'},
          timestamp: DateTime.now(),
        );

        // Act
        await NotificationRouter.routeFromNotification(mockRouter, notification);

        // Assert
        verify(mockRouter.go('/od-request/123')).called(1);
      });

      test('should route to staff inbox for new OD request notifications', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'New OD Request',
          body: 'A new OD request requires your attention',
          type: NotificationType.newODRequest,
          data: {'request_id': '456'},
          timestamp: DateTime.now(),
        );

        // Act
        await NotificationRouter.routeFromNotification(mockRouter, notification);

        // Assert
        verify(mockRouter.go('/staff/inbox?highlight=456')).called(1);
      });

      test('should route to staff inbox for bulk operation notifications', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'Bulk Operation Complete',
          body: 'Your bulk approval operation has completed',
          type: NotificationType.bulkOperationComplete,
          data: {'operation_type': 'approval'},
          timestamp: DateTime.now(),
        );

        // Act
        await NotificationRouter.routeFromNotification(mockRouter, notification);

        // Assert
        verify(mockRouter.go('/staff/inbox?bulk_result=approval')).called(1);
      });

      test('should route to dashboard for system update notifications', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'System Update',
          body: 'ODTrack has been updated with new features',
          type: NotificationType.systemUpdate,
          data: {},
          timestamp: DateTime.now(),
        );

        // Act
        await NotificationRouter.routeFromNotification(mockRouter, notification);

        // Assert
        verify(mockRouter.go('/dashboard')).called(1);
      });

      test('should route to dashboard as fallback when no specific route found', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'Unknown Notification',
          body: 'Unknown notification type',
          type: NotificationType.systemUpdate,
          data: {},
          timestamp: DateTime.now(),
        );

        // Act
        await NotificationRouter.routeFromNotification(mockRouter, notification);

        // Assert
        verify(mockRouter.go('/dashboard')).called(1);
      });
    });

    group('Reminder Routing', () {
      test('should route to staff inbox for pending approval reminders', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'Pending Approvals',
          body: 'You have pending OD requests to review',
          type: NotificationType.reminder,
          data: {'reminder_type': 'pending_approval'},
          timestamp: DateTime.now(),
        );

        // Act
        await NotificationRouter.routeFromNotification(mockRouter, notification);

        // Assert
        verify(mockRouter.go('/staff/inbox')).called(1);
      });

      test('should route to OD request for upcoming OD reminders', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'Upcoming OD',
          body: 'Your OD is scheduled for tomorrow',
          type: NotificationType.reminder,
          data: {
            'reminder_type': 'upcoming_od',
            'request_id': '789',
          },
          timestamp: DateTime.now(),
        );

        // Act
        await NotificationRouter.routeFromNotification(mockRouter, notification);

        // Assert
        verify(mockRouter.go('/od-request/789')).called(1);
      });

      test('should route to profile for profile incomplete reminders', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'Complete Your Profile',
          body: 'Please complete your profile information',
          type: NotificationType.reminder,
          data: {'reminder_type': 'profile_incomplete'},
          timestamp: DateTime.now(),
        );

        // Act
        await NotificationRouter.routeFromNotification(mockRouter, notification);

        // Assert
        verify(mockRouter.go('/profile')).called(1);
      });

      test('should route to analytics for analytics available reminders', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'Analytics Available',
          body: 'New analytics data is available',
          type: NotificationType.reminder,
          data: {'reminder_type': 'analytics_available'},
          timestamp: DateTime.now(),
        );

        // Act
        await NotificationRouter.routeFromNotification(mockRouter, notification);

        // Assert
        verify(mockRouter.go('/analytics')).called(1);
      });
    });

    group('Query Parameters', () {
      test('should extract common query parameters', () {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_123',
          title: 'Test',
          body: 'Test body',
          type: NotificationType.odStatusChange,
          data: {'new_status': 'approved'},
          timestamp: DateTime.now(),
        );

        // Act
        final params = NotificationRouter.extractQueryParams(notification);

        // Assert
        expect(params['from_notification'], equals('true'));
        expect(params['notification_id'], equals('test_123'));
        expect(params['status'], equals('approved'));
      });

      test('should build route with query parameters', () {
        // Arrange
        const basePath = '/od-request/123';
        final params = {
          'from_notification': 'true',
          'status': 'approved',
          'priority': 'high',
        };

        // Act
        final route = NotificationRouter.buildRouteWithParams(basePath, params);

        // Assert
        expect(route, contains('from_notification=true'));
        expect(route, contains('status=approved'));
        expect(route, contains('priority=high'));
        expect(route, startsWith('/od-request/123?'));
      });

      test('should return base path when no parameters provided', () {
        // Arrange
        const basePath = '/dashboard';
        final params = <String, String>{};

        // Act
        final route = NotificationRouter.buildRouteWithParams(basePath, params);

        // Assert
        expect(route, equals('/dashboard'));
      });
    });

    group('Notification Grouping', () {
      test('should generate grouping key for OD status change notifications', () {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'OD Status Changed',
          body: 'Status updated',
          type: NotificationType.odStatusChange,
          data: {'request_id': '123'},
          timestamp: DateTime.now(),
        );

        // Act
        final groupingKey = NotificationRouter.getGroupingKey(notification);

        // Assert
        expect(groupingKey, equals('od_status_123'));
      });

      test('should generate grouping key for new OD request notifications', () {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'New OD Request',
          body: 'New request received',
          type: NotificationType.newODRequest,
          data: {'department': 'CSE'},
          timestamp: DateTime.now(),
        );

        // Act
        final groupingKey = NotificationRouter.getGroupingKey(notification);

        // Assert
        expect(groupingKey, equals('new_requests_CSE'));
      });

      test('should generate default grouping key when department not provided', () {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'New OD Request',
          body: 'New request received',
          type: NotificationType.newODRequest,
          data: {},
          timestamp: DateTime.now(),
        );

        // Act
        final groupingKey = NotificationRouter.getGroupingKey(notification);

        // Assert
        expect(groupingKey, equals('new_requests'));
      });
    });

    group('Badge and Dismissal Logic', () {
      test('should show badge for OD status change notifications', () {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'OD Status Changed',
          body: 'Status updated',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: DateTime.now(),
        );

        // Act
        final shouldShow = NotificationRouter.shouldShowBadge(notification);

        // Assert
        expect(shouldShow, isTrue);
      });

      test('should show badge for new OD request notifications', () {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'New OD Request',
          body: 'New request received',
          type: NotificationType.newODRequest,
          data: {},
          timestamp: DateTime.now(),
        );

        // Act
        final shouldShow = NotificationRouter.shouldShowBadge(notification);

        // Assert
        expect(shouldShow, isTrue);
      });

      test('should not show badge for system update notifications', () {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'System Update',
          body: 'System updated',
          type: NotificationType.systemUpdate,
          data: {},
          timestamp: DateTime.now(),
        );

        // Act
        final shouldShow = NotificationRouter.shouldShowBadge(notification);

        // Assert
        expect(shouldShow, isFalse);
      });

      test('should auto-dismiss system update notifications', () {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'System Update',
          body: 'System updated',
          type: NotificationType.systemUpdate,
          data: {},
          timestamp: DateTime.now(),
        );

        // Act
        final shouldDismiss = NotificationRouter.shouldAutoDismiss(notification);

        // Assert
        expect(shouldDismiss, isTrue);
      });

      test('should not auto-dismiss OD status change notifications', () {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'OD Status Changed',
          body: 'Status updated',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: DateTime.now(),
        );

        // Act
        final shouldDismiss = NotificationRouter.shouldAutoDismiss(notification);

        // Assert
        expect(shouldDismiss, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle routing errors gracefully', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_id',
          title: 'Test',
          body: 'Test body',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: DateTime.now(),
        );

        when(mockRouter.go('/od-requests')).thenThrow(Exception('Routing error'));
        when(mockRouter.go('/dashboard')).thenReturn(null);

        // Act
        await NotificationRouter.routeFromNotification(mockRouter, notification);

        // Assert - Should fallback to dashboard after error
        verify(mockRouter.go('/dashboard')).called(1);
      });
    });
  });
}