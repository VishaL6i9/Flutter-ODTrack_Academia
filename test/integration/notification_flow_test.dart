import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/models/notification_message.dart';
import 'package:odtrack_academia/services/notification/notification_grouping_service.dart';

void main() {
  group('Notification Flow Integration Tests', () {
    late NotificationGroupingService groupingService;

    setUpAll(() async {
      // Initialize Hive for testing
      Hive.init('test');
    });

    setUp(() {
      groupingService = NotificationGroupingService();
    });

    tearDown(() async {
      try {
        await groupingService.dispose();
      } catch (e) {
        // Ignore disposal errors in tests
      }
    });

    group('Notification Grouping', () {
      test('should initialize grouping service', () async {
        // Act & Assert
        expect(() => groupingService.initialize(), returnsNormally);
      });

      test('should group notifications correctly', () async {
        // Arrange
        await groupingService.initialize();
        
        final notification = NotificationMessage(
          id: 'test_1',
          title: 'Test Notification',
          body: 'Test body',
          type: NotificationType.odStatusChange,
          data: const {'request_id': 'req_123'},
          timestamp: DateTime.now(),
        );

        // Act
        final result = await groupingService.shouldGroupNotification(notification);

        // Assert
        expect(result.shouldGroup, isTrue);
        expect(result.groupKey, isNotNull);
        expect(result.groupSize, equals(1));
        expect(result.isSpamPrevention, isFalse);
      });

      test('should detect spam prevention', () async {
        // Arrange
        await groupingService.initialize();
        
        final notifications = List.generate(7, (index) => NotificationMessage(
          id: 'test_$index',
          title: 'Test Notification $index',
          body: 'Test body $index',
          type: NotificationType.odStatusChange,
          data: const {'request_id': 'req_123'},
          timestamp: DateTime.now().add(Duration(seconds: index * 10)),
        ));

        // Act
        final results = <NotificationGroupResult>[];
        for (final notification in notifications) {
          final result = await groupingService.shouldGroupNotification(notification);
          results.add(result);
        }

        // Assert
        expect(results.first.isSpamPrevention, isFalse);
        expect(results.last.isSpamPrevention, isTrue);
      });

      test('should generate group summaries', () async {
        // Arrange
        await groupingService.initialize();
        
        final notification = NotificationMessage(
          id: 'test_summary',
          title: 'Test Summary',
          body: 'Test summary body',
          type: NotificationType.systemUpdate,
          data: const {'update_type': 'app_update'},
          timestamp: DateTime.now(),
        );

        await groupingService.shouldGroupNotification(notification);

        // Act
        final summary = groupingService.getGroupSummary('system_app_update');

        // Assert
        expect(summary.count, equals(1));
        expect(summary.type, equals(NotificationType.systemUpdate));
        expect(summary.title, equals('System Updates'));
      });

      test('should clear expired groups', () async {
        // Arrange
        await groupingService.initialize();
        
        final oldNotification = NotificationMessage(
          id: 'old_test',
          title: 'Old Notification',
          body: 'This is old',
          type: NotificationType.reminder,
          data: const {'reminder_type': 'old'},
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        );

        await groupingService.shouldGroupNotification(oldNotification);

        // Act
        await groupingService.clearExpiredGroups();

        // Assert
        final activeGroups = groupingService.getAllActiveGroups();
        expect(activeGroups.isEmpty, isTrue);
      });

      test('should calculate spam statistics', () async {
        // Arrange
        await groupingService.initialize();
        
        final notifications = List.generate(3, (index) => NotificationMessage(
          id: 'stats_$index',
          title: 'Stats Test $index',
          body: 'Stats body $index',
          type: NotificationType.newODRequest,
          data: const {'department': 'CS'},
          timestamp: DateTime.now().add(Duration(seconds: index * 10)),
        ));

        for (final notification in notifications) {
          await groupingService.shouldGroupNotification(notification);
        }

        // Act
        final stats = groupingService.getSpamStats();

        // Assert
        expect(stats.totalGroups, greaterThan(0));
        expect(stats.totalNotifications, equals(3));
        expect(stats.spamPreventedCount, equals(0)); // No spam with only 3 notifications
      });
    });
  });
}