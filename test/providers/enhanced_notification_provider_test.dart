import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:go_router/go_router.dart';
import 'package:odtrack_academia/providers/notification_provider.dart';
import 'package:odtrack_academia/services/notification/notification_service.dart';
import 'package:odtrack_academia/models/notification_message.dart';

import 'enhanced_notification_provider_test.mocks.dart';

@GenerateMocks([NotificationService, GoRouter])
void main() {
  group('Enhanced NotificationProvider', () {
    late MockNotificationService mockNotificationService;
    late MockGoRouter mockRouter;
    late StreamController<NotificationMessage> messageController;

    // Helper function to create and initialize a provider for testing
    Future<NotificationProvider> createProvider() async {
      final provider = NotificationProvider(mockNotificationService, mockRouter);
      await Future<void>.delayed(const Duration(milliseconds: 100)); // Wait for initialization
      return provider;
    }

    setUp(() {
      mockNotificationService = MockNotificationService();
      mockRouter = MockGoRouter();
      messageController = StreamController<NotificationMessage>.broadcast();
      
      // Setup default mock behaviors
      when(mockNotificationService.initialize()).thenAnswer((_) async {});
      when(mockNotificationService.requestPermissions()).thenAnswer((_) async => true);
      when(mockNotificationService.getDeviceToken()).thenAnswer((_) async => 'test_token');
      when(mockNotificationService.getNotificationHistory()).thenAnswer((_) async => []);
      when(mockNotificationService.onMessageReceived).thenAnswer((_) => messageController.stream);
      when(mockNotificationService.areNotificationsEnabled()).thenAnswer((_) async => true);
    });

    tearDown(() {
      messageController.close();
    });

    group('Enhanced State Management', () {
      test('should initialize with enhanced state properties', () async {
        final provider = await createProvider();
        
        expect(provider.state.notifications, isEmpty);
        expect(provider.state.isInitialized, isTrue);
        expect(provider.state.deviceToken, equals('test_token'));
        expect(provider.state.permissionsGranted, isTrue);
        expect(provider.state.unreadCount, equals(0));
        expect(provider.state.badgeCount, equals(0));
        expect(provider.state.isLoading, isFalse);
        expect(provider.state.error, isNull);
        expect(provider.state.notificationCounts, isEmpty);
        expect(provider.state.lastRefresh, isNotNull);
        expect(provider.state.isRouting, isFalse);
        
        provider.dispose();
      });

      test('should handle incoming notifications with enhanced state', () async {
        final provider = await createProvider();
        
        final notification = NotificationMessage(
          id: 'test_1',
          title: 'Test Notification',
          body: 'Test body',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: DateTime.now(),
          isRead: false,
        );

        messageController.add(notification);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(provider.state.notifications, hasLength(1));
        expect(provider.state.unreadCount, equals(1));
        expect(provider.state.badgeCount, equals(1)); // OD status changes show badge
        expect(provider.state.notificationCounts['NotificationType.odStatusChange'], equals(1));
        expect(provider.state.notificationCounts['NotificationType.odStatusChange_unread'], equals(1));
        
        provider.dispose();
      });

      test('should calculate badge count correctly for different notification types', () async {
        final provider = await createProvider();
        
        final notifications = [
          NotificationMessage(
            id: '1',
            title: 'OD Status',
            body: 'Status changed',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
            isRead: false,
          ),
          NotificationMessage(
            id: '2',
            title: 'System Update',
            body: 'System updated',
            type: NotificationType.systemUpdate,
            data: {},
            timestamp: DateTime.now(),
            isRead: false,
          ),
        ];
        
        for (final notification in notifications) {
          messageController.add(notification);
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }

        // System updates don't show badge, OD status changes do
        expect(provider.state.badgeCount, equals(1));
        expect(provider.state.unreadCount, equals(2));
        
        provider.dispose();
      });

      test('should detect high priority unread notifications', () async {
        final provider = await createProvider();
        
        final highPriorityNotification = NotificationMessage(
          id: '1',
          title: 'Urgent',
          body: 'Urgent notification',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: DateTime.now(),
          isRead: false,
          priority: NotificationPriority.urgent,
        );
        
        messageController.add(highPriorityNotification);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(provider.state.hasHighPriorityUnread, isTrue);
        
        provider.dispose();
      });

      test('should group notifications by type', () async {
        final provider = await createProvider();
        
        final notifications = [
          NotificationMessage(
            id: '1',
            title: 'OD Status 1',
            body: 'Status changed',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
          ),
          NotificationMessage(
            id: '2',
            title: 'OD Status 2',
            body: 'Status changed',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
          ),
          NotificationMessage(
            id: '3',
            title: 'New Request',
            body: 'New OD request',
            type: NotificationType.newODRequest,
            data: {},
            timestamp: DateTime.now(),
          ),
        ];
        
        for (final notification in notifications) {
          messageController.add(notification);
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }

        final grouped = provider.state.groupedNotifications;
        expect(grouped[NotificationType.odStatusChange], hasLength(2));
        expect(grouped[NotificationType.newODRequest], hasLength(1));
        
        provider.dispose();
      });
    });

    group('Enhanced Badge Management', () {
      test('should get badge count by type', () async {
        final provider = await createProvider();
        
        final notifications = [
          NotificationMessage(
            id: '1',
            title: 'OD Status 1',
            body: 'Status changed',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
            isRead: false,
          ),
          NotificationMessage(
            id: '2',
            title: 'OD Status 2',
            body: 'Status changed',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
            isRead: false,
          ),
          NotificationMessage(
            id: '3',
            title: 'New Request',
            body: 'New OD request',
            type: NotificationType.newODRequest,
            data: {},
            timestamp: DateTime.now(),
            isRead: false,
          ),
        ];
        
        for (final notification in notifications) {
          messageController.add(notification);
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }

        final odStatusBadgeCount = provider.getBadgeCountByType(NotificationType.odStatusChange);
        final newRequestBadgeCount = provider.getBadgeCountByType(NotificationType.newODRequest);

        expect(odStatusBadgeCount, equals(2));
        expect(newRequestBadgeCount, equals(1));
        
        provider.dispose();
      });
    });

    group('Enhanced Notification Actions', () {
      test('should mark notifications as read by type', () async {
        final provider = await createProvider();
        
        final notifications = [
          NotificationMessage(
            id: '1',
            title: 'OD Status 1',
            body: 'Status changed',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
            isRead: false,
          ),
          NotificationMessage(
            id: '2',
            title: 'OD Status 2',
            body: 'Status changed',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
            isRead: false,
          ),
          NotificationMessage(
            id: '3',
            title: 'New Request',
            body: 'New OD request',
            type: NotificationType.newODRequest,
            data: {},
            timestamp: DateTime.now(),
            isRead: false,
          ),
        ];
        
        for (final notification in notifications) {
          messageController.add(notification);
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }

        await provider.markAsReadByType(NotificationType.odStatusChange);

        final odStatusNotifications = provider.state.notifications
            .where((n) => n.type == NotificationType.odStatusChange)
            .toList();
        expect(odStatusNotifications.every((n) => n.isRead), isTrue);
        
        final newRequestNotifications = provider.state.notifications
            .where((n) => n.type == NotificationType.newODRequest)
            .toList();
        expect(newRequestNotifications.any((n) => !n.isRead), isTrue);
        
        provider.dispose();
      });

      test('should handle notification actions', () async {
        final provider = await createProvider();
        
        final actionableNotification = NotificationMessage(
          id: '1',
          title: 'Actionable',
          body: 'Actionable notification',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: DateTime.now(),
          isRead: false,
          actions: [
            const NotificationAction(
              id: 'approve',
              title: 'Approve',
              data: {'action': 'approve'},
            ),
          ],
        );
        
        messageController.add(actionableNotification);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await provider.handleNotificationAction('1', 'approve');

        final updatedNotification = provider.state.notifications
            .firstWhere((n) => n.id == '1');
        expect(updatedNotification.isRead, isTrue);
        
        provider.dispose();
      });

      test('should remove expired notifications', () async {
        final provider = await createProvider();
        
        final now = DateTime.now();
        final expiredNotification = NotificationMessage(
          id: '1',
          title: 'Expired',
          body: 'Expired notification',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: now,
          expiresAt: now.subtract(const Duration(hours: 1)),
        );
        
        final validNotification = NotificationMessage(
          id: '2',
          title: 'Valid',
          body: 'Valid notification',
          type: NotificationType.newODRequest,
          data: {},
          timestamp: now,
          expiresAt: now.add(const Duration(hours: 1)),
        );
        
        messageController.add(expiredNotification);
        await Future<void>.delayed(const Duration(milliseconds: 25));
        messageController.add(validNotification);
        await Future<void>.delayed(const Duration(milliseconds: 25));

        await provider.removeExpiredNotifications();

        expect(provider.state.notifications, hasLength(1));
        expect(provider.state.notifications.first.id, equals('2'));
        
        provider.dispose();
      });

      test('should force refresh notifications', () async {
        final provider = await createProvider();
        
        final refreshedNotifications = [
          NotificationMessage(
            id: 'refreshed',
            title: 'Refreshed',
            body: 'Refreshed notification',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
          ),
        ];
        
        when(mockNotificationService.getNotificationHistory())
            .thenAnswer((_) async => refreshedNotifications);

        await provider.forceRefresh();

        expect(provider.state.notifications, hasLength(1));
        expect(provider.state.notifications.first.id, equals('refreshed'));
        expect(provider.state.lastRefresh, isNotNull);
        
        provider.dispose();
      });
    });

    group('Enhanced Routing', () {
      test('should route notifications without automatically marking as read', () async {
        final provider = await createProvider();
        
        final notification = NotificationMessage(
          id: 'route_test',
          title: 'Route Test',
          body: 'Test routing',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: DateTime.now(),
          isRead: false,
        );

        messageController.add(notification);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Notification should still be unread after routing
        expect(provider.state.notifications.first.isRead, isFalse);
        expect(provider.state.unreadCount, equals(1));
        
        provider.dispose();
      });
    });
  });
}