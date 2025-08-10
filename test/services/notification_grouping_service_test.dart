import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/models/notification_message.dart';
import 'package:odtrack_academia/services/notification/notification_grouping_service.dart';

void main() {
  group('NotificationGroupingService', () {
    late NotificationGroupingService groupingService;
    // Note: mockBox is not used in this test but kept for future use

    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('test');
      Hive.registerAdapter(NotificationMessageAdapter());
    });

    setUp(() async {
      groupingService = NotificationGroupingService();
      // Note: In a real test environment, you'd want to use a test-specific box
      // For this example, we'll assume the service handles box creation
    });

    tearDown(() async {
      await groupingService.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        // Act & Assert
        expect(() => groupingService.initialize(), returnsNormally);
      });
    });

    group('Notification Grouping', () {
      setUp(() async {
        await groupingService.initialize();
      });

      test('should not group first notification of a type', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_1',
          title: 'First OD Status Update',
          body: 'Your request has been approved',
          type: NotificationType.odStatusChange,
          data: const {'request_id': 'req_123'},
          timestamp: DateTime.now(),
        );

        // Act
        final result = await groupingService.shouldGroupNotification(notification);

        // Assert
        expect(result.shouldGroup, isTrue);
        expect(result.groupKey, equals('od_status_req_123'));
        expect(result.groupSize, equals(1));
        expect(result.isSpamPrevention, isFalse);
      });

      test('should group similar notifications within time window', () async {
        // Arrange
        final baseTime = DateTime.now();
        final notification1 = NotificationMessage(
          id: 'test_1',
          title: 'OD Status Update 1',
          body: 'Your request has been approved',
          type: NotificationType.odStatusChange,
          data: const {'request_id': 'req_123'},
          timestamp: baseTime,
        );
        final notification2 = NotificationMessage(
          id: 'test_2',
          title: 'OD Status Update 2',
          body: 'Your request has been processed',
          type: NotificationType.odStatusChange,
          data: const {'request_id': 'req_123'},
          timestamp: baseTime.add(const Duration(minutes: 2)),
        );

        // Act
        final result1 = await groupingService.shouldGroupNotification(notification1);
        final result2 = await groupingService.shouldGroupNotification(notification2);

        // Assert
        expect(result1.shouldGroup, isTrue);
        expect(result1.groupSize, equals(1));
        expect(result2.shouldGroup, isTrue);
        expect(result2.groupSize, equals(2));
        expect(result1.groupKey, equals(result2.groupKey));
      });

      test('should start new group when time window expires', () async {
        // Arrange
        final baseTime = DateTime.now();
        final notification1 = NotificationMessage(
          id: 'test_1',
          title: 'OD Status Update 1',
          body: 'Your request has been approved',
          type: NotificationType.odStatusChange,
          data: const {'request_id': 'req_123'},
          timestamp: baseTime,
        );
        final notification2 = NotificationMessage(
          id: 'test_2',
          title: 'OD Status Update 2',
          body: 'Your request has been updated',
          type: NotificationType.odStatusChange,
          data: const {'request_id': 'req_123'},
          timestamp: baseTime.add(const Duration(minutes: 10)), // Beyond 5-minute window
        );

        // Act
        final result1 = await groupingService.shouldGroupNotification(notification1);
        final result2 = await groupingService.shouldGroupNotification(notification2);

        // Assert
        expect(result1.shouldGroup, isTrue);
        expect(result1.groupSize, equals(1));
        expect(result2.shouldGroup, isTrue);
        expect(result2.groupSize, equals(1)); // New group started
        expect(result1.groupKey, equals(result2.groupKey));
      });

      test('should detect spam prevention when group size exceeds limit', () async {
        // Arrange
        final baseTime = DateTime.now();
        final notifications = List.generate(7, (index) => NotificationMessage(
          id: 'test_$index',
          title: 'OD Status Update $index',
          body: 'Update $index',
          type: NotificationType.odStatusChange,
          data: const {'request_id': 'req_123'},
          timestamp: baseTime.add(Duration(seconds: index * 30)),
        ));

        // Act
        final results = <NotificationGroupResult>[];
        for (final notification in notifications) {
          final result = await groupingService.shouldGroupNotification(notification);
          results.add(result);
        }

        // Assert
        expect(results.first.isSpamPrevention, isFalse);
        expect(results.last.isSpamPrevention, isTrue); // Should be spam prevention
        expect(results.last.groupSize, greaterThan(5));
      });

      test('should generate different group keys for different request IDs', () async {
        // Arrange
        final notification1 = NotificationMessage(
          id: 'test_1',
          title: 'OD Status Update',
          body: 'Request 123 approved',
          type: NotificationType.odStatusChange,
          data: const {'request_id': 'req_123'},
          timestamp: DateTime.now(),
        );
        final notification2 = NotificationMessage(
          id: 'test_2',
          title: 'OD Status Update',
          body: 'Request 456 approved',
          type: NotificationType.odStatusChange,
          data: const {'request_id': 'req_456'},
          timestamp: DateTime.now(),
        );

        // Act
        final result1 = await groupingService.shouldGroupNotification(notification1);
        final result2 = await groupingService.shouldGroupNotification(notification2);

        // Assert
        expect(result1.groupKey, equals('od_status_req_123'));
        expect(result2.groupKey, equals('od_status_req_456'));
        expect(result1.groupKey, isNot(equals(result2.groupKey)));
      });

      test('should group new OD requests by department', () async {
        // Arrange
        final notification1 = NotificationMessage(
          id: 'test_1',
          title: 'New OD Request',
          body: 'From Computer Science',
          type: NotificationType.newODRequest,
          data: const {'department': 'CS'},
          timestamp: DateTime.now(),
        );
        final notification2 = NotificationMessage(
          id: 'test_2',
          title: 'New OD Request',
          body: 'From Mathematics',
          type: NotificationType.newODRequest,
          data: const {'department': 'MATH'},
          timestamp: DateTime.now(),
        );

        // Act
        final result1 = await groupingService.shouldGroupNotification(notification1);
        final result2 = await groupingService.shouldGroupNotification(notification2);

        // Assert
        expect(result1.groupKey, equals('new_requests_dept_CS'));
        expect(result2.groupKey, equals('new_requests_dept_MATH'));
        expect(result1.groupKey, isNot(equals(result2.groupKey)));
      });
    });

    group('Group Management', () {
      setUp(() async {
        await groupingService.initialize();
      });

      test('should return grouped notifications', () async {
        // Arrange
        final notifications = [
          NotificationMessage(
            id: 'test_1',
            title: 'Reminder 1',
            body: 'First reminder',
            type: NotificationType.reminder,
            data: const {'reminder_type': 'pending_approval'},
            timestamp: DateTime.now(),
          ),
          NotificationMessage(
            id: 'test_2',
            title: 'Reminder 2',
            body: 'Second reminder',
            type: NotificationType.reminder,
            data: const {'reminder_type': 'pending_approval'},
            timestamp: DateTime.now().add(const Duration(minutes: 1)),
          ),
        ];

        // Act
        for (final notification in notifications) {
          await groupingService.shouldGroupNotification(notification);
        }
        final groupedNotifications = groupingService.getGroupedNotifications('reminder_pending_approval');

        // Assert
        expect(groupedNotifications.length, equals(2));
        expect(groupedNotifications[0].id, equals('test_1'));
        expect(groupedNotifications[1].id, equals('test_2'));
      });

      test('should generate group summary correctly', () async {
        // Arrange
        final notifications = [
          NotificationMessage(
            id: 'test_1',
            title: 'System Update 1',
            body: 'Update available',
            type: NotificationType.systemUpdate,
            data: const {'update_type': 'app_update'},
            timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
          NotificationMessage(
            id: 'test_2',
            title: 'System Update 2',
            body: 'Update installed',
            type: NotificationType.systemUpdate,
            data: const {'update_type': 'app_update'},
            timestamp: DateTime.now(),
          ),
        ];

        // Act
        for (final notification in notifications) {
          await groupingService.shouldGroupNotification(notification);
        }
        final summary = groupingService.getGroupSummary('system_app_update');

        // Assert
        expect(summary.count, equals(2));
        expect(summary.type, equals(NotificationType.systemUpdate));
        expect(summary.title, equals('System Updates'));
        expect(summary.summary, contains('2 system notifications'));
        expect(summary.latestMessage?.id, equals('test_2'));
      });

      test('should clear expired groups', () async {
        // Arrange
        final oldNotification = NotificationMessage(
          id: 'old_test',
          title: 'Old Notification',
          body: 'This is old',
          type: NotificationType.reminder,
          data: const {'reminder_type': 'old'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        );

        await groupingService.shouldGroupNotification(oldNotification);
        expect(groupingService.getAllActiveGroups().isNotEmpty, isTrue);

        // Act
        await groupingService.clearExpiredGroups();

        // Assert
        final activeGroups = groupingService.getAllActiveGroups();
        expect(activeGroups.isEmpty, isTrue);
      });

      test('should clear all groups', () async {
        // Arrange
        final notification = NotificationMessage(
          id: 'test_clear',
          title: 'Test Clear',
          body: 'This will be cleared',
          type: NotificationType.bulkOperationComplete,
          data: const {'operation_type': 'approval'},
          timestamp: DateTime.now(),
        );

        await groupingService.shouldGroupNotification(notification);
        expect(groupingService.getAllActiveGroups().isNotEmpty, isTrue);

        // Act
        await groupingService.clearAllGroups();

        // Assert
        final activeGroups = groupingService.getAllActiveGroups();
        expect(activeGroups.isEmpty, isTrue);
      });
    });

    group('Spam Statistics', () {
      setUp(() async {
        await groupingService.initialize();
      });

      test('should calculate spam statistics correctly', () async {
        // Arrange - Create multiple groups with different sizes
        final notifications = [
          // Group 1: 3 notifications (no spam)
          ...List.generate(3, (i) => NotificationMessage(
            id: 'group1_$i',
            title: 'Group 1 Notification $i',
            body: 'Body $i',
            type: NotificationType.odStatusChange,
            data: const {'request_id': 'req_1'},
            timestamp: DateTime.now().add(Duration(seconds: i)),
          )),
          // Group 2: 7 notifications (2 spam prevented)
          ...List.generate(7, (i) => NotificationMessage(
            id: 'group2_$i',
            title: 'Group 2 Notification $i',
            body: 'Body $i',
            type: NotificationType.newODRequest,
            data: const {'department': 'CS'},
            timestamp: DateTime.now().add(Duration(seconds: i + 10)),
          )),
        ];

        // Act
        for (final notification in notifications) {
          await groupingService.shouldGroupNotification(notification);
        }
        final stats = groupingService.getSpamStats();

        // Assert
        expect(stats.totalGroups, equals(2));
        expect(stats.totalNotifications, equals(10));
        expect(stats.spamPreventedCount, equals(2)); // 7 - 5 (max per group)
        expect(stats.groupingEfficiency, greaterThan(0));
      });
    });
  });
}

// Mock adapter for testing (in a real app, this would be generated)
class NotificationMessageAdapter extends TypeAdapter<NotificationMessage> {
  @override
  final int typeId = 0;

  @override
  NotificationMessage read(BinaryReader reader) {
    // Simplified implementation for testing
    throw UnimplementedError('Mock adapter for testing');
  }

  @override
  void write(BinaryWriter writer, NotificationMessage obj) {
    // Simplified implementation for testing
    throw UnimplementedError('Mock adapter for testing');
  }
}