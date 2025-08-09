import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/models/notification_message.dart';
import 'package:odtrack_academia/services/notification/notification_service.dart';

/// Firebase Cloud Messaging implementation of NotificationService
class FirebaseNotificationService implements NotificationService {
  static const String _notificationBoxKey = 'notifications_box';
  static const String _deviceTokenKey = 'device_token';
  static const String _notificationChannelId = 'odtrack_notifications';
  static const String _notificationChannelName = 'ODTrack Notifications';
  static const String _notificationChannelDescription = 'Notifications for OD request updates';
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  late Box<dynamic> _notificationBox;
  late StreamController<NotificationMessage> _messageController;
  
  bool _isInitialized = false;
  String? _cachedDeviceToken;
  
  @override
  Stream<NotificationMessage> get onMessageReceived => _messageController.stream;
  
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize message stream controller
      _messageController = StreamController<NotificationMessage>.broadcast();
      
      // Open notification storage box
      _notificationBox = await Hive.openBox<dynamic>(_notificationBoxKey);
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();
      
      // Setup message handlers
      _setupMessageHandlers();
      
      // Get and cache device token
      _cachedDeviceToken = await _getDeviceTokenFromFirebase();
      if (_cachedDeviceToken != null) {
        await _notificationBox.put(_deviceTokenKey, _cachedDeviceToken);
      }
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('FirebaseNotificationService initialized successfully');
        print('Device token: $_cachedDeviceToken');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing FirebaseNotificationService: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<String?> getDeviceToken() async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }
    
    // Return cached token if available
    if (_cachedDeviceToken != null) {
      return _cachedDeviceToken;
    }
    
    // Try to get from storage
    final storedToken = _notificationBox.get(_deviceTokenKey) as String?;
    if (storedToken != null) {
      _cachedDeviceToken = storedToken;
      return storedToken;
    }
    
    // Get fresh token from Firebase
    _cachedDeviceToken = await _getDeviceTokenFromFirebase();
    if (_cachedDeviceToken != null) {
      await _notificationBox.put(_deviceTokenKey, _cachedDeviceToken);
    }
    
    return _cachedDeviceToken;
  }
  
  @override
  Future<void> subscribeToTopic(String topic) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }
    
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic $topic: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }
    
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic $topic: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<void> showLocalNotification(NotificationMessage message) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }
    
    try {
      final androidDetails = AndroidNotificationDetails(
        _notificationChannelId,
        _notificationChannelName,
        channelDescription: _notificationChannelDescription,
        importance: _getAndroidImportance(message.priority),
        priority: _getAndroidPriority(message.priority),
        showWhen: true,
        when: message.timestamp.millisecondsSinceEpoch,
        groupKey: message.groupId,
        setAsGroupSummary: message.groupId != null,
        autoCancel: true,
        enableVibration: true,
        playSound: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        message.id.hashCode,
        message.title,
        message.body,
        notificationDetails,
        payload: jsonEncode(message.toJson()),
      );
      
      // Store notification in local storage
      await _storeNotification(message);
      
      if (kDebugMode) {
        print('Local notification shown: ${message.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing local notification: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<void> handleNotificationTap(NotificationMessage message) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }
    
    try {
      // Mark notification as read
      final updatedMessage = message.copyWith(isRead: true);
      await _updateNotification(updatedMessage);
      
      // Add to message stream for routing
      _messageController.add(updatedMessage);
      
      if (kDebugMode) {
        print('Notification tapped: ${message.title}');
        print('Action URL: ${message.actionUrl}');
        print('Data: ${message.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification tap: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }
    
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      
      if (kDebugMode) {
        print('Notification permission status: ${settings.authorizationStatus}');
      }
      
      return isAuthorized;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permissions: $e');
      }
      return false;
    }
  }
  
  @override
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }
    
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking notification settings: $e');
      }
      return false;
    }
  }
  
  @override
  Future<void> clearAllNotifications() async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }
    
    try {
      // Clear local notifications
      await _localNotifications.cancelAll();
      
      // Clear stored notifications
      await _notificationBox.clear();
      
      if (kDebugMode) {
        print('All notifications cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing notifications: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<List<NotificationMessage>> getNotificationHistory() async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }
    
    try {
      final notifications = <NotificationMessage>[];
      
      for (final key in _notificationBox.keys) {
        if (key != _deviceTokenKey) {
          final data = _notificationBox.get(key);
          if (data is Map<String, dynamic>) {
            try {
              final notification = NotificationMessage.fromJson(data);
              if (!notification.isExpired) {
                notifications.add(notification);
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing stored notification: $e');
              }
            }
          }
        }
      }
      
      // Sort by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return notifications;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notification history: $e');
      }
      return [];
    }
  }
  
  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );
    
    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: _notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }
  
  /// Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Set foreground notification presentation options
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
  
  /// Setup message handlers for different states
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);
    
    // Handle initial message when app is launched from notification
    _handleInitialMessage();
  }
  
  /// Handle messages received while app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final notificationMessage = _convertRemoteMessageToNotificationMessage(message);
      
      // Show local notification for foreground messages
      await showLocalNotification(notificationMessage);
      
      // Add to stream
      _messageController.add(notificationMessage);
      
      if (kDebugMode) {
        print('Foreground message received: ${message.messageId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling foreground message: $e');
      }
    }
  }
  
  /// Handle notification taps when app is opened from background
  Future<void> _handleNotificationOpenedApp(RemoteMessage message) async {
    try {
      final notificationMessage = _convertRemoteMessageToNotificationMessage(message);
      await handleNotificationTap(notificationMessage);
      
      if (kDebugMode) {
        print('Notification opened app: ${message.messageId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling notification opened app: $e');
      }
    }
  }
  
  /// Handle initial message when app is launched from notification
  Future<void> _handleInitialMessage() async {
    try {
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        final notificationMessage = _convertRemoteMessageToNotificationMessage(initialMessage);
        await handleNotificationTap(notificationMessage);
        
        if (kDebugMode) {
          print('App launched from notification: ${initialMessage.messageId}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling initial message: $e');
      }
    }
  }
  
  /// Handle local notification taps
  void _onLocalNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final message = NotificationMessage.fromJson(data);
        handleNotificationTap(message);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling local notification tap: $e');
      }
    }
  }
  
  /// Get device token from Firebase
  Future<String?> _getDeviceTokenFromFirebase() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device token: $e');
      }
      return null;
    }
  }
  
  /// Convert RemoteMessage to NotificationMessage
  NotificationMessage _convertRemoteMessageToNotificationMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    
    return NotificationMessage(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? 'ODTrack Notification',
      body: notification?.body ?? 'You have a new notification',
      type: _parseNotificationType(data['type'] as String?),
      data: data,
      timestamp: message.sentTime ?? DateTime.now(),
      imageUrl: notification?.android?.imageUrl ?? notification?.apple?.imageUrl,
      priority: _parseNotificationPriority(data['priority'] as String?),
      groupId: data['group_id'] as String?,
      actionUrl: data['action_url'] as String?,
      expiresAt: data['expires_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(data['expires_at'] as String))
          : null,
    );
  }
  
  /// Parse notification type from string
  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'od_status_change':
        return NotificationType.odStatusChange;
      case 'new_od_request':
        return NotificationType.newODRequest;
      case 'reminder':
        return NotificationType.reminder;
      case 'system_update':
        return NotificationType.systemUpdate;
      case 'bulk_operation_complete':
        return NotificationType.bulkOperationComplete;
      default:
        return NotificationType.systemUpdate;
    }
  }
  
  /// Parse notification priority from string
  NotificationPriority _parseNotificationPriority(String? priority) {
    switch (priority) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }
  
  /// Get Android importance from notification priority
  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }
  
  /// Get Android priority from notification priority
  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.urgent:
        return Priority.max;
    }
  }
  
  /// Store notification in local storage
  Future<void> _storeNotification(NotificationMessage message) async {
    try {
      await _notificationBox.put(message.id, message.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Error storing notification: $e');
      }
    }
  }
  
  /// Update stored notification
  Future<void> _updateNotification(NotificationMessage message) async {
    try {
      await _notificationBox.put(message.id, message.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating notification: $e');
      }
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _messageController.close();
    await _notificationBox.close();
  }
}
