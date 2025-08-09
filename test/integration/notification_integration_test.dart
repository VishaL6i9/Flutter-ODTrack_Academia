import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:odtrack_academia/services/notification/notification_router.dart';
import 'package:odtrack_academia/models/notification_message.dart';

import '../services/notification/notification_router_test.mocks.dart';

void main() {
  group('Notification Integration Tests', () {
    late MockGoRouter mockRouter;

    setUp(() {
      mockRouter = MockGoRouter();
    });

    test('should route correctly based on notification type', () async {
      // Arrange
      final odStatusNotification = NotificationMessage(
        id: 'route_test_1',
        title: 'OD Status Changed',
        body: 'Your OD request has been approved',
        type: NotificationType.odStatusChange,
        data: {'request_id': '456'},
        timestamp: DateTime.now(),
      );

      final newRequestNotification = NotificationMessage(
        id: 'route_test_2',
        title: 'New OD Request',
        body: 'A new OD request requires your attention',
        type: NotificationType.newODRequest,
        data: {'request_id': '789'},
        timestamp: DateTime.now(),
      );

      // Act & Assert - Test OD status change routing
      await NotificationRouter.routeFromNotification(mockRouter, odStatusNotification);
      verify(mockRouter.go('/od-request/456')).called(1);

      // Act & Assert - Test new OD request routing
      await NotificationRouter.routeFromNotification(mockRouter, newRequestNotification);
      verify(mockRouter.go('/staff/inbox?highlight=789')).called(1);
    });

    test('should handle notification grouping correctly', () {
      // Arrange
      final notification1 = NotificationMessage(
        id: 'group_test_1',
        title: 'OD Status Changed',
        body: 'Request 123 approved',
        type: NotificationType.odStatusChange,
        data: {'request_id': '123'},
        timestamp: DateTime.now(),
      );

      final notification2 = NotificationMessage(
        id: 'group_test_2',
        title: 'OD Status Changed',
        body: 'Request 123 rejected',
        type: NotificationType.odStatusChange,
        data: {'request_id': '123'},
        timestamp: DateTime.now(),
      );

      // Act
      final groupKey1 = NotificationRouter.getGroupingKey(notification1);
      final groupKey2 = NotificationRouter.getGroupingKey(notification2);

      // Assert
      expect(groupKey1, equals(groupKey2));
      expect(groupKey1, equals('od_status_123'));
    });

    test('should handle notification priority correctly', () {
      // Arrange
      final urgentNotification = NotificationMessage(
        id: 'priority_test_1',
        title: 'Urgent: System Maintenance',
        body: 'System will be down for maintenance',
        type: NotificationType.systemUpdate,
        data: {},
        timestamp: DateTime.now(),
        priority: NotificationPriority.urgent,
      );

      final normalNotification = NotificationMessage(
        id: 'priority_test_2',
        title: 'OD Status Update',
        body: 'Your request is being processed',
        type: NotificationType.odStatusChange,
        data: {},
        timestamp: DateTime.now(),
        priority: NotificationPriority.normal,
      );

      // Act & Assert
      expect(NotificationRouter.shouldShowBadge(urgentNotification), isFalse); // System updates don't show badges
      expect(NotificationRouter.shouldShowBadge(normalNotification), isTrue); // OD status changes show badges
      
      expect(NotificationRouter.shouldAutoDismiss(urgentNotification), isTrue); // System updates auto-dismiss
      expect(NotificationRouter.shouldAutoDismiss(normalNotification), isFalse); // OD status changes don't auto-dismiss
    });

    test('should extract query parameters correctly', () {
      // Arrange
      final notification = NotificationMessage(
        id: 'query_test_1',
        title: 'Bulk Operation Complete',
        body: 'Bulk approval completed',
        type: NotificationType.bulkOperationComplete,
        data: {
          'operation_type': 'approval',
          'success_count': '15',
          'failure_count': '2',
        },
        timestamp: DateTime.now(),
      );

      // Act
      final params = NotificationRouter.extractQueryParams(notification);

      // Assert
      expect(params['from_notification'], equals('true'));
      expect(params['notification_id'], equals('query_test_1'));
      expect(params['operation'], equals('approval'));
      expect(params['success'], equals('15'));
      expect(params['failures'], equals('2'));
    });

    test('should build routes with parameters correctly', () {
      // Arrange
      const basePath = '/staff/inbox';
      final params = {
        'from_notification': 'true',
        'bulk_result': 'approval',
        'success': '10',
      };

      // Act
      final route = NotificationRouter.buildRouteWithParams(basePath, params);

      // Assert
      expect(route, startsWith('/staff/inbox?'));
      expect(route, contains('from_notification=true'));
      expect(route, contains('bulk_result=approval'));
      expect(route, contains('success=10'));
    });
  });
}