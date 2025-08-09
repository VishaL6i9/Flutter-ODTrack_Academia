import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:go_router/go_router.dart';
import 'package:odtrack_academia/providers/notification_provider.dart';
import 'package:odtrack_academia/services/notification/notification_service.dart';
import 'package:odtrack_academia/models/notification_message.dart';

import 'notification_provider_test.mocks.dart';

@GenerateMocks([NotificationService, GoRouter])
void main() {
  group('NotificationProvider', () {
    late NotificationProvider notificationProvider;
    late MockNotificationService mockNotificationService;
    late MockGoRouter mockRouter;
    late StreamController<NotificationMessage> messageController;

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
      
      notificationProvider = NotificationProvider(mockNotificationService, mockRouter);
    });

    tearDown(() {
      messageController.close();
      notificationProvider.dispose();
    });

    group('Initialization', () {
      test('should initialize with default state', () {
        // Assert
        expect(notificationProvider.state.notifications, isEmpty);
        expect(notificationProvider.state.isInitialized, isFalse);
        expect(notificationProvider.state.deviceToken, isNull);
        expect(notificationProvider.state.permissionsGranted, isFalse);
        expect(notificationProvider.state.unreadCount, equals(0));
        expect(notificationProvider.state.isLoading, isFalse);
        expect(notificationProvider.state.error, isNull);
      });

      test('should initialize notification service and update state', () async {
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockNotificationService.initialize()).called(1);
        verify(mockNotificationService.requestPermissions()).called(1);
        verify(mockNotificationService.getDeviceToken()).called(1);
        verify(mockNotificationService.getNotificationHistory()).called(1);
        
        expect(notificationProvider.state.isInitialized, isTrue);
        expect(notificationProvider.state.permissionsGranted, isTrue);
        expect(notificationProvider.state.deviceToken, equals('test_token'));
        expect(notificationProvider.state.isLoading, isFalse);
      });

      test('should handle initialization errors', () async {
        // Arrange
        when(mockNotificationService.initialize())
            .thenThrow(Exception('Initialization failed'));
        
        final provider = NotificationProvider(mockNotificationService, mockRouter);
        
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(provider.state.isLoading, isFalse);
        expect(provider.state.error, contains('Failed to initialize notifications'));
        
        provider.dispose();
      });

      test('should load existing notification history during initialization', () async {
        // Arrange
        final existingNotifications = [
          NotificationMessage(
            id: '1',
            title: 'Test 1',
            body: 'Body 1',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
            isRead: false,
          ),
          NotificationMessage(
            id: '2',
            title: 'Test 2',
            body: 'Body 2',
            type: NotificationType.newODRequest,
            data: {},
            timestamp: DateTime.now(),
            isRead: true,
          ),
        ];
        
        when(mockNotificationService.getNotificationHistory())
            .thenAnswer((_) async => existingNotifications);
        
        final provider = NotificationProvider(mockNotificationService, mockRouter);
        
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(provider.state.notifications, hasLength(2));
        expect(provider.state.unreadCount, equals(1));
        
        provider.dispose();
      });
    });

    group('Incoming Notifications', () {
      test('should handle incoming notifications and update state', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        final newNotification = NotificationMessage(
          id: 'new_1',
          title: 'New Notification',
          body: 'New notification body',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: DateTime.now(),
          isRead: false,
        );

        // Act
        messageController.add(newNotification);
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(notificationProvider.state.notifications, hasLength(1));
        expect(notificationProvider.state.notifications.first.id, equals('new_1'));
        expect(notificationProvider.state.unreadCount, equals(1));
      });

      test('should add new notifications to the beginning of the list', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        final notification1 = NotificationMessage(
          id: '1',
          title: 'First',
          body: 'First notification',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: DateTime.now(),
        );
        
        final notification2 = NotificationMessage(
          id: '2',
          title: 'Second',
          body: 'Second notification',
          type: NotificationType.newODRequest,
          data: {},
          timestamp: DateTime.now(),
        );

        // Act
        messageController.add(notification1);
        await Future.delayed(const Duration(milliseconds: 50));
        messageController.add(notification2);
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(notificationProvider.state.notifications, hasLength(2));
        expect(notificationProvider.state.notifications.first.id, equals('2'));
        expect(notificationProvider.state.notifications.last.id, equals('1'));
      });
    });

    group('Mark as Read', () {
      test('should mark single notification as read', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        final notification = NotificationMessage(
          id: 'test_1',
          title: 'Test',
          body: 'Test body',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: DateTime.now(),
          isRead: false,
        );
        
        messageController.add(notification);
        await Future.delayed(const Duration(milliseconds: 50));

        // Act
        await notificationProvider.markAsRead('test_1');

        // Assert
        final updatedNotification = notificationProvider.state.notifications
            .firstWhere((n) => n.id == 'test_1');
        expect(updatedNotification.isRead, isTrue);
        expect(notificationProvider.state.unreadCount, equals(0));
      });

      test('should mark all notifications as read', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        final notifications = [
          NotificationMessage(
            id: '1',
            title: 'Test 1',
            body: 'Body 1',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
            isRead: false,
          ),
          NotificationMessage(
            id: '2',
            title: 'Test 2',
            body: 'Body 2',
            type: NotificationType.newODRequest,
            data: {},
            timestamp: DateTime.now(),
            isRead: false,
          ),
        ];
        
        for (final notification in notifications) {
          messageController.add(notification);
          await Future.delayed(const Duration(milliseconds: 25));
        }

        // Act
        await notificationProvider.markAllAsRead();

        // Assert
        expect(notificationProvider.state.unreadCount, equals(0));
        expect(
          notificationProvider.state.notifications.every((n) => n.isRead),
          isTrue,
        );
      });
    });

    group('Clear Notifications', () {
      test('should clear all notifications', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        when(mockNotificationService.clearAllNotifications())
            .thenAnswer((_) async {});
        
        final notification = NotificationMessage(
          id: 'test_1',
          title: 'Test',
          body: 'Test body',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: DateTime.now(),
        );
        
        messageController.add(notification);
        await Future.delayed(const Duration(milliseconds: 50));

        // Act
        await notificationProvider.clearAllNotifications();

        // Assert
        verify(mockNotificationService.clearAllNotifications()).called(1);
        expect(notificationProvider.state.notifications, isEmpty);
        expect(notificationProvider.state.unreadCount, equals(0));
      });
    });

    group('Topic Management', () {
      test('should subscribe to topic', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        const topic = 'test_topic';
        when(mockNotificationService.subscribeToTopic(topic))
            .thenAnswer((_) async {});

        // Act
        await notificationProvider.subscribeToTopic(topic);

        // Assert
        verify(mockNotificationService.subscribeToTopic(topic)).called(1);
      });

      test('should unsubscribe from topic', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        const topic = 'test_topic';
        when(mockNotificationService.unsubscribeFromTopic(topic))
            .thenAnswer((_) async {});

        // Act
        await notificationProvider.unsubscribeFromTopic(topic);

        // Assert
        verify(mockNotificationService.unsubscribeFromTopic(topic)).called(1);
      });
    });

    group('Permission Management', () {
      test('should request permissions and update state', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        when(mockNotificationService.requestPermissions())
            .thenAnswer((_) async => true);

        // Act
        final result = await notificationProvider.requestPermissions();

        // Assert
        expect(result, isTrue);
        expect(notificationProvider.state.permissionsGranted, isTrue);
      });

      test('should check if notifications are enabled', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Act
        final result = await notificationProvider.areNotificationsEnabled();

        // Assert
        expect(result, isTrue);
        verify(mockNotificationService.areNotificationsEnabled()).called(1);
      });
    });

    group('Filtering and Queries', () {
      test('should get notifications by type', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        final notifications = [
          NotificationMessage(
            id: '1',
            title: 'OD Status',
            body: 'Status changed',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
          ),
          NotificationMessage(
            id: '2',
            title: 'New Request',
            body: 'New OD request',
            type: NotificationType.newODRequest,
            data: {},
            timestamp: DateTime.now(),
          ),
          NotificationMessage(
            id: '3',
            title: 'Another Status',
            body: 'Another status change',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
          ),
        ];
        
        for (final notification in notifications) {
          messageController.add(notification);
          await Future.delayed(const Duration(milliseconds: 25));
        }

        // Act
        final odStatusNotifications = notificationProvider
            .getNotificationsByType(NotificationType.odStatusChange);

        // Assert
        expect(odStatusNotifications, hasLength(2));
        expect(
          odStatusNotifications.every((n) => n.type == NotificationType.odStatusChange),
          isTrue,
        );
      });

      test('should get unread notifications', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        final notifications = [
          NotificationMessage(
            id: '1',
            title: 'Read',
            body: 'Read notification',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: DateTime.now(),
            isRead: true,
          ),
          NotificationMessage(
            id: '2',
            title: 'Unread',
            body: 'Unread notification',
            type: NotificationType.newODRequest,
            data: {},
            timestamp: DateTime.now(),
            isRead: false,
          ),
        ];
        
        for (final notification in notifications) {
          messageController.add(notification);
          await Future.delayed(const Duration(milliseconds: 25));
        }

        // Act
        final unreadNotifications = notificationProvider.unreadNotifications;

        // Assert
        expect(unreadNotifications, hasLength(1));
        expect(unreadNotifications.first.id, equals('2'));
      });

      test('should get recent notifications', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final twoDaysAgo = now.subtract(const Duration(days: 2));
        
        final notifications = [
          NotificationMessage(
            id: '1',
            title: 'Old',
            body: 'Old notification',
            type: NotificationType.odStatusChange,
            data: {},
            timestamp: twoDaysAgo,
          ),
          NotificationMessage(
            id: '2',
            title: 'Recent',
            body: 'Recent notification',
            type: NotificationType.newODRequest,
            data: {},
            timestamp: yesterday.add(const Duration(hours: 1)),
          ),
        ];
        
        for (final notification in notifications) {
          messageController.add(notification);
          await Future.delayed(const Duration(milliseconds: 25));
        }

        // Act
        final recentNotifications = notificationProvider.recentNotifications;

        // Assert
        expect(recentNotifications, hasLength(1));
        expect(recentNotifications.first.id, equals('2'));
      });
    });

    group('Error Handling', () {
      test('should handle notification service errors', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        when(mockNotificationService.subscribeToTopic(any))
            .thenThrow(Exception('Subscription failed'));

        // Act
        await notificationProvider.subscribeToTopic('test_topic');

        // Assert
        expect(notificationProvider.state.error, contains('Failed to subscribe to topic'));
      });

      test('should clear error state', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Arrange
        when(mockNotificationService.subscribeToTopic(any))
            .thenThrow(Exception('Subscription failed'));
        
        await notificationProvider.subscribeToTopic('test_topic');
        expect(notificationProvider.state.error, isNotNull);

        // Act
        notificationProvider.clearError();

        // Assert
        expect(notificationProvider.state.error, isNull);
      });
    });
  });
}