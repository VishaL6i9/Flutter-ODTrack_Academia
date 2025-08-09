import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/models/notification_message.dart';

void main() {
  group('NotificationMessage', () {
    test('should create notification message with required fields', () {
      final timestamp = DateTime.now();
      final data = {'key': 'value'};
      
      final notification = NotificationMessage(
        id: '123',
        title: 'Test Title',
        body: 'Test Body',
        type: NotificationType.odStatusChange,
        data: data,
        timestamp: timestamp,
      );

      expect(notification.id, '123');
      expect(notification.title, 'Test Title');
      expect(notification.body, 'Test Body');
      expect(notification.type, NotificationType.odStatusChange);
      expect(notification.data, data);
      expect(notification.timestamp, timestamp);
      expect(notification.isRead, false);
      expect(notification.priority, NotificationPriority.normal);
      expect(notification.imageUrl, isNull);
      expect(notification.groupId, isNull);
      expect(notification.actionUrl, isNull);
      expect(notification.actions, isNull);
      expect(notification.expiresAt, isNull);
    });

    test('should create notification message with all fields', () {
      final timestamp = DateTime.now();
      final expiresAt = timestamp.add(const Duration(hours: 24));
      final data = {'requestId': '456'};
      final actions = [
        const NotificationAction(id: 'approve', title: 'Approve'),
        const NotificationAction(id: 'reject', title: 'Reject', destructive: true),
      ];
      
      final notification = NotificationMessage(
        id: '123',
        title: 'OD Request Update',
        body: 'Your OD request has been approved',
        type: NotificationType.odStatusChange,
        data: data,
        timestamp: timestamp,
        isRead: true,
        imageUrl: 'https://example.com/image.png',
        priority: NotificationPriority.high,
        groupId: 'od_updates',
        actionUrl: '/od-request/456',
        actions: actions,
        expiresAt: expiresAt,
      );

      expect(notification.id, '123');
      expect(notification.title, 'OD Request Update');
      expect(notification.body, 'Your OD request has been approved');
      expect(notification.type, NotificationType.odStatusChange);
      expect(notification.data, data);
      expect(notification.timestamp, timestamp);
      expect(notification.isRead, true);
      expect(notification.imageUrl, 'https://example.com/image.png');
      expect(notification.priority, NotificationPriority.high);
      expect(notification.groupId, 'od_updates');
      expect(notification.actionUrl, '/od-request/456');
      expect(notification.actions, actions);
      expect(notification.expiresAt, expiresAt);
    });

    test('should create copy with updated fields', () {
      final original = NotificationMessage(
        id: '123',
        title: 'Original Title',
        body: 'Original Body',
        type: NotificationType.newODRequest,
        data: const {'key': 'value'},
        timestamp: DateTime.now(),
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        isRead: true,
        priority: NotificationPriority.urgent,
      );

      expect(updated.id, '123');
      expect(updated.title, 'Updated Title');
      expect(updated.body, 'Original Body');
      expect(updated.type, NotificationType.newODRequest);
      expect(updated.isRead, true);
      expect(updated.priority, NotificationPriority.urgent);
    });

    test('should serialize to and from JSON', () {
      final timestamp = DateTime.now();
      final actions = [
        const NotificationAction(id: 'view', title: 'View Details'),
      ];
      
      final notification = NotificationMessage(
        id: '123',
        title: 'Test Notification',
        body: 'Test Body',
        type: NotificationType.reminder,
        data: const {'requestId': '456'},
        timestamp: timestamp,
        isRead: true,
        imageUrl: 'https://example.com/image.png',
        priority: NotificationPriority.high,
        groupId: 'reminders',
        actionUrl: '/reminder/456',
        actions: actions,
        expiresAt: timestamp.add(const Duration(days: 1)),
      );

      final json = notification.toJson();
      final deserialized = NotificationMessage.fromJson(json);

      expect(deserialized.id, notification.id);
      expect(deserialized.title, notification.title);
      expect(deserialized.body, notification.body);
      expect(deserialized.type, notification.type);
      expect(deserialized.data, notification.data);
      expect(deserialized.timestamp, notification.timestamp);
      expect(deserialized.isRead, notification.isRead);
      expect(deserialized.imageUrl, notification.imageUrl);
      expect(deserialized.priority, notification.priority);
      expect(deserialized.groupId, notification.groupId);
      expect(deserialized.actionUrl, notification.actionUrl);
      expect(deserialized.actions?.length, notification.actions?.length);
      expect(deserialized.expiresAt, notification.expiresAt);
    });

    group('isExpired', () {
      test('should return false when expiresAt is null', () {
        final notification = NotificationMessage(
          id: '123',
          title: 'Test',
          body: 'Test',
          type: NotificationType.systemUpdate,
          data: const {},
          timestamp: DateTime.now(),
        );

        expect(notification.isExpired, false);
      });

      test('should return false when not expired', () {
        final notification = NotificationMessage(
          id: '123',
          title: 'Test',
          body: 'Test',
          type: NotificationType.systemUpdate,
          data: const {},
          timestamp: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(notification.isExpired, false);
      });

      test('should return true when expired', () {
        final notification = NotificationMessage(
          id: '123',
          title: 'Test',
          body: 'Test',
          type: NotificationType.systemUpdate,
          data: const {},
          timestamp: DateTime.now(),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(notification.isExpired, true);
      });
    });

    group('hasActions', () {
      test('should return false when actions is null', () {
        final notification = NotificationMessage(
          id: '123',
          title: 'Test',
          body: 'Test',
          type: NotificationType.systemUpdate,
          data: const {},
          timestamp: DateTime.now(),
        );

        expect(notification.hasActions, false);
      });

      test('should return false when actions is empty', () {
        final notification = NotificationMessage(
          id: '123',
          title: 'Test',
          body: 'Test',
          type: NotificationType.systemUpdate,
          data: const {},
          timestamp: DateTime.now(),
          actions: const [],
        );

        expect(notification.hasActions, false);
      });

      test('should return true when actions is not empty', () {
        final notification = NotificationMessage(
          id: '123',
          title: 'Test',
          body: 'Test',
          type: NotificationType.systemUpdate,
          data: const {},
          timestamp: DateTime.now(),
          actions: const [
            NotificationAction(id: 'action1', title: 'Action 1'),
          ],
        );

        expect(notification.hasActions, true);
      });
    });

    group('displayTime', () {
      test('should return "Just now" for very recent notifications', () {
        final notification = NotificationMessage(
          id: '123',
          title: 'Test',
          body: 'Test',
          type: NotificationType.systemUpdate,
          data: const {},
          timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
        );

        expect(notification.displayTime, 'Just now');
      });

      test('should return minutes for notifications within an hour', () {
        final notification = NotificationMessage(
          id: '123',
          title: 'Test',
          body: 'Test',
          type: NotificationType.systemUpdate,
          data: const {},
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        expect(notification.displayTime, '30m ago');
      });

      test('should return hours for notifications within a day', () {
        final notification = NotificationMessage(
          id: '123',
          title: 'Test',
          body: 'Test',
          type: NotificationType.systemUpdate,
          data: const {},
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        );

        expect(notification.displayTime, '5h ago');
      });

      test('should return days for notifications within a week', () {
        final notification = NotificationMessage(
          id: '123',
          title: 'Test',
          body: 'Test',
          type: NotificationType.systemUpdate,
          data: const {},
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
        );

        expect(notification.displayTime, '3d ago');
      });

      test('should return date for older notifications', () {
        final timestamp = DateTime(2023, 5, 15, 10, 30);
        final notification = NotificationMessage(
          id: '123',
          title: 'Test',
          body: 'Test',
          type: NotificationType.systemUpdate,
          data: const {},
          timestamp: timestamp,
        );

        expect(notification.displayTime, '15/5/2023');
      });
    });
  });

  group('NotificationAction', () {
    test('should create notification action with required fields', () {
      const action = NotificationAction(
        id: 'approve',
        title: 'Approve',
      );

      expect(action.id, 'approve');
      expect(action.title, 'Approve');
      expect(action.icon, isNull);
      expect(action.destructive, false);
      expect(action.data, isNull);
    });

    test('should create notification action with all fields', () {
      const action = NotificationAction(
        id: 'delete',
        title: 'Delete',
        icon: 'delete_icon',
        destructive: true,
        data: {'confirmRequired': true},
      );

      expect(action.id, 'delete');
      expect(action.title, 'Delete');
      expect(action.icon, 'delete_icon');
      expect(action.destructive, true);
      expect(action.data, const {'confirmRequired': true});
    });

    test('should serialize to and from JSON', () {
      const action = NotificationAction(
        id: 'share',
        title: 'Share',
        icon: 'share_icon',
        destructive: false,
        data: {'shareType': 'email'},
      );

      final json = action.toJson();
      final deserialized = NotificationAction.fromJson(json);

      expect(deserialized.id, action.id);
      expect(deserialized.title, action.title);
      expect(deserialized.icon, action.icon);
      expect(deserialized.destructive, action.destructive);
      expect(deserialized.data, action.data);
    });
  });

  group('NotificationType', () {
    test('should have all expected values', () {
      expect(NotificationType.values, contains(NotificationType.odStatusChange));
      expect(NotificationType.values, contains(NotificationType.newODRequest));
      expect(NotificationType.values, contains(NotificationType.reminder));
      expect(NotificationType.values, contains(NotificationType.systemUpdate));
      expect(NotificationType.values, contains(NotificationType.bulkOperationComplete));
    });
  });

  group('NotificationPriority', () {
    test('should have all expected values', () {
      expect(NotificationPriority.values, contains(NotificationPriority.low));
      expect(NotificationPriority.values, contains(NotificationPriority.normal));
      expect(NotificationPriority.values, contains(NotificationPriority.high));
      expect(NotificationPriority.values, contains(NotificationPriority.urgent));
    });
  });
}