import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/services/notification/firebase_notification_service.dart';
import 'package:odtrack_academia/models/notification_message.dart';

import 'firebase_notification_service_test.mocks.dart';

@GenerateMocks([
  FirebaseMessaging,
  FlutterLocalNotificationsPlugin,
  Box,
  NotificationSettings,
])
void main() {
  group('FirebaseNotificationService', () {
    late FirebaseNotificationService notificationService;
    late MockFirebaseMessaging mockFirebaseMessaging;
    late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
    late MockBox mockNotificationBox;
    late MockNotificationSettings mockNotificationSettings;

    setUp(() {
      mockFirebaseMessaging = MockFirebaseMessaging();
      mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
      mockNotificationBox = MockBox();
      mockNotificationSettings = MockNotificationSettings();
      
      notificationService = FirebaseNotificationService();
      
      // Setup default mock behaviors
      when(mockFirebaseMessaging.requestPermission(
        alert: anyNamed('alert'),
        announcement: anyNamed('announcement'),
        badge: anyNamed('badge'),
        carPlay: anyNamed('carPlay'),
        criticalAlert: anyNamed('criticalAlert'),
        provisional: anyNamed('provisional'),
        sound: anyNamed('sound'),
      )).thenAnswer((_) async => mockNotificationSettings);
      
      when(mockNotificationSettings.authorizationStatus)
          .thenReturn(AuthorizationStatus.authorized);
      
      when(mockFirebaseMessaging.getToken())
          .thenAnswer((_) async => 'test_device_token');
      
      when(mockFirebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: anyNamed('alert'),
        badge: anyNamed('badge'),
        sound: anyNamed('sound'),
      )).thenAnswer((_) async {});
      
      when(mockLocalNotifications.initialize(
        any,
        onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse'),
      )).thenAnswer((_) async => true);
      
      when(mockNotificationBox.keys).thenReturn([]);
      when(mockNotificationBox.put(any, any)).thenAnswer((_) async {});
      when(mockNotificationBox.get(any)).thenReturn(null);
    });

    group('Initialization', () {
      test('should initialize successfully with valid configuration', () async {
        // Arrange
        when(mockFirebaseMessaging.getInitialMessage())
            .thenAnswer((_) async => null);
        
        // Act & Assert
        expect(() => notificationService.initialize(), returnsNormally);
      });

      test('should request notification permissions during initialization', () async {
        // Arrange
        when(mockFirebaseMessaging.getInitialMessage())
            .thenAnswer((_) async => null);
        
        // Act
        await notificationService.initialize();
        
        // Assert
        verify(mockFirebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        )).called(1);
      });

      test('should get and cache device token during initialization', () async {
        // Arrange
        const expectedToken = 'test_device_token';
        when(mockFirebaseMessaging.getToken())
            .thenAnswer((_) async => expectedToken);
        when(mockFirebaseMessaging.getInitialMessage())
            .thenAnswer((_) async => null);
        
        // Act
        await notificationService.initialize();
        
        // Assert
        verify(mockFirebaseMessaging.getToken()).called(1);
        verify(mockNotificationBox.put('device_token', expectedToken)).called(1);
      });

      test('should throw error if initialization fails', () async {
        // Arrange
        when(mockFirebaseMessaging.requestPermission(
          alert: anyNamed('alert'),
          announcement: anyNamed('announcement'),
          badge: anyNamed('badge'),
          carPlay: anyNamed('carPlay'),
          criticalAlert: anyNamed('criticalAlert'),
          provisional: anyNamed('provisional'),
          sound: anyNamed('sound'),
        )).thenThrow(Exception('Permission request failed'));
        
        // Act & Assert
        expect(
          () => notificationService.initialize(),
          throwsException,
        );
      });
    });

    group('Device Token Management', () {
      test('should return cached device token if available', () async {
        // Arrange
        const expectedToken = 'cached_token';
        await notificationService.initialize();
        
        // Mock cached token
        when(mockNotificationBox.get('device_token')).thenReturn(expectedToken);
        
        // Act
        final token = await notificationService.getDeviceToken();
        
        // Assert
        expect(token, equals(expectedToken));
      });

      test('should fetch fresh token if not cached', () async {
        // Arrange
        const expectedToken = 'fresh_token';
        when(mockFirebaseMessaging.getToken())
            .thenAnswer((_) async => expectedToken);
        when(mockNotificationBox.get('device_token')).thenReturn(null);
        
        await notificationService.initialize();
        
        // Act
        final token = await notificationService.getDeviceToken();
        
        // Assert
        expect(token, equals(expectedToken));
        verify(mockNotificationBox.put('device_token', expectedToken)).called(greaterThanOrEqualTo(1));
      });

      test('should throw StateError if not initialized', () async {
        // Act & Assert
        expect(
          () => notificationService.getDeviceToken(),
          throwsStateError,
        );
      });
    });

    group('Topic Subscription', () {
      test('should subscribe to topic successfully', () async {
        // Arrange
        const topic = 'test_topic';
        when(mockFirebaseMessaging.subscribeToTopic(topic))
            .thenAnswer((_) async {});
        
        await notificationService.initialize();
        
        // Act
        await notificationService.subscribeToTopic(topic);
        
        // Assert
        verify(mockFirebaseMessaging.subscribeToTopic(topic)).called(1);
      });

      test('should unsubscribe from topic successfully', () async {
        // Arrange
        const topic = 'test_topic';
        when(mockFirebaseMessaging.unsubscribeFromTopic(topic))
            .thenAnswer((_) async {});
        
        await notificationService.initialize();
        
        // Act
        await notificationService.unsubscribeFromTopic(topic);
        
        // Assert
        verify(mockFirebaseMessaging.unsubscribeFromTopic(topic)).called(1);
      });

      test('should throw StateError if not initialized when subscribing', () async {
        // Act & Assert
        expect(
          () => notificationService.subscribeToTopic('test_topic'),
          throwsStateError,
        );
      });
    });

    group('Permission Management', () {
      test('should return true when permissions are authorized', () async {
        // Arrange
        when(mockNotificationSettings.authorizationStatus)
            .thenReturn(AuthorizationStatus.authorized);
        
        await notificationService.initialize();
        
        // Act
        final result = await notificationService.requestPermissions();
        
        // Assert
        expect(result, isTrue);
      });

      test('should return true when permissions are provisional', () async {
        // Arrange
        when(mockNotificationSettings.authorizationStatus)
            .thenReturn(AuthorizationStatus.provisional);
        
        await notificationService.initialize();
        
        // Act
        final result = await notificationService.requestPermissions();
        
        // Assert
        expect(result, isTrue);
      });

      test('should return false when permissions are denied', () async {
        // Arrange
        when(mockNotificationSettings.authorizationStatus)
            .thenReturn(AuthorizationStatus.denied);
        
        await notificationService.initialize();
        
        // Act
        final result = await notificationService.requestPermissions();
        
        // Assert
        expect(result, isFalse);
      });

      test('should check if notifications are enabled', () async {
        // Arrange
        when(mockFirebaseMessaging.getNotificationSettings())
            .thenAnswer((_) async => mockNotificationSettings);
        when(mockNotificationSettings.authorizationStatus)
            .thenReturn(AuthorizationStatus.authorized);
        
        await notificationService.initialize();
        
        // Act
        final result = await notificationService.areNotificationsEnabled();
        
        // Assert
        expect(result, isTrue);
        verify(mockFirebaseMessaging.getNotificationSettings()).called(1);
      });
    });

    group('Local Notifications', () {
      test('should show local notification successfully', () async {
        // Arrange
        final testMessage = NotificationMessage(
          id: 'test_id',
          title: 'Test Title',
          body: 'Test Body',
          type: NotificationType.odStatusChange,
          data: {'key': 'value'},
          timestamp: DateTime.now(),
          priority: NotificationPriority.normal,
        );
        
        when(mockLocalNotifications.show(
          any,
          any,
          any,
          any,
          payload: anyNamed('payload'),
        )).thenAnswer((_) async {});
        
        await notificationService.initialize();
        
        // Act
        await notificationService.showLocalNotification(testMessage);
        
        // Assert
        verify(mockLocalNotifications.show(
          any,
          testMessage.title,
          testMessage.body,
          any,
          payload: anyNamed('payload'),
        )).called(1);
        
        verify(mockNotificationBox.put(testMessage.id, any)).called(1);
      });

      test('should handle notification tap correctly', () async {
        // Arrange
        final testMessage = NotificationMessage(
          id: 'test_id',
          title: 'Test Title',
          body: 'Test Body',
          type: NotificationType.odStatusChange,
          data: {'key': 'value'},
          timestamp: DateTime.now(),
        );
        
        await notificationService.initialize();
        
        // Act
        await notificationService.handleNotificationTap(testMessage);
        
        // Assert
        verify(mockNotificationBox.put(testMessage.id, any)).called(1);
      });
    });

    group('Notification History', () {
      test('should return empty list when no notifications stored', () async {
        // Arrange
        when(mockNotificationBox.keys).thenReturn([]);
        
        await notificationService.initialize();
        
        // Act
        final history = await notificationService.getNotificationHistory();
        
        // Assert
        expect(history, isEmpty);
      });

      test('should return stored notifications sorted by timestamp', () async {
        // Arrange
        final now = DateTime.now();
        final older = now.subtract(const Duration(hours: 1));
        
        final notification1 = NotificationMessage(
          id: 'id1',
          title: 'Title 1',
          body: 'Body 1',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: older,
        );
        
        final notification2 = NotificationMessage(
          id: 'id2',
          title: 'Title 2',
          body: 'Body 2',
          type: NotificationType.newODRequest,
          data: {},
          timestamp: now,
        );
        
        when(mockNotificationBox.keys).thenReturn(['id1', 'id2']);
        when(mockNotificationBox.get('id1')).thenReturn(notification1.toJson());
        when(mockNotificationBox.get('id2')).thenReturn(notification2.toJson());
        
        await notificationService.initialize();
        
        // Act
        final history = await notificationService.getNotificationHistory();
        
        // Assert
        expect(history, hasLength(2));
        expect(history.first.id, equals('id2')); // Newer first
        expect(history.last.id, equals('id1'));
      });

      test('should filter out expired notifications', () async {
        // Arrange
        final now = DateTime.now();
        final expired = now.subtract(const Duration(days: 2));
        
        final expiredNotification = NotificationMessage(
          id: 'expired',
          title: 'Expired',
          body: 'Body',
          type: NotificationType.reminder,
          data: {},
          timestamp: expired,
          expiresAt: expired.add(const Duration(hours: 1)),
        );
        
        final validNotification = NotificationMessage(
          id: 'valid',
          title: 'Valid',
          body: 'Body',
          type: NotificationType.odStatusChange,
          data: {},
          timestamp: now,
        );
        
        when(mockNotificationBox.keys).thenReturn(['expired', 'valid']);
        when(mockNotificationBox.get('expired')).thenReturn(expiredNotification.toJson());
        when(mockNotificationBox.get('valid')).thenReturn(validNotification.toJson());
        
        await notificationService.initialize();
        
        // Act
        final history = await notificationService.getNotificationHistory();
        
        // Assert
        expect(history, hasLength(1));
        expect(history.first.id, equals('valid'));
      });
    });

    group('Clear Notifications', () {
      test('should clear all notifications successfully', () async {
        // Arrange
        when(mockLocalNotifications.cancelAll()).thenAnswer((_) async {});
        when(mockNotificationBox.clear()).thenAnswer((_) async => 0);
        
        await notificationService.initialize();
        
        // Act
        await notificationService.clearAllNotifications();
        
        // Assert
        verify(mockLocalNotifications.cancelAll()).called(1);
        verify(mockNotificationBox.clear()).called(1);
      });
    });
  });
}