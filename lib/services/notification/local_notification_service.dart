import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:odtrack_academia/models/notification_message.dart';
import 'package:odtrack_academia/services/notification/notification_service.dart';

/// Local notification service for offline scenarios
/// Provides fallback notification functionality when FCM is unavailable
class LocalNotificationService implements NotificationService {
  static const String _notificationBoxKey = 'local_notifications_box';
  static const String _notificationChannelId = 'odtrack_local_notifications';
  static const String _notificationChannelName = 'ODTrack Local Notifications';
  static const String _notificationChannelDescription = 'Local notifications for offline scenarios';
  static const String _groupKey = 'odtrack_notification_group';
  
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  late Box<dynamic> _notificationBox;
  late StreamController<NotificationMessage> _messageController;
  
  bool _isInitialized = false;
  int _notificationIdCounter = 1000; // Start from 1000 to avoid conflicts
  final Map<String, List<NotificationMessage>> _groupedNotifications = {};
  
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
      
      // Load existing grouped notifications
      await _loadGroupedNotifications();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('LocalNotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing LocalNotificationService: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<String?> getDeviceToken() async {
    // Local notifications don't use device tokens
    return 'local_device_token';
  }
  
  @override
  Future<void> subscribeToTopic(String topic) async {
    // Local notifications don't support topics
    if (kDebugMode) {
      print('Local notifications do not support topic subscription: $topic');
    }
  }
  
  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    // Local notifications don't support topics
    if (kDebugMode) {
      print('Local notifications do not support topic unsubscription: $topic');
    }
  }
  
  @override
  Future<void> showLocalNotification(NotificationMessage message) async {
    if (!_isInitialized) {
      throw StateError('LocalNotificationService not initialized');
    }
    
    try {
      // Check if notification should be grouped
      final groupKey = _getGroupKey(message);
      if (groupKey != null) {
        await _showGroupedNotification(message, groupKey);
      } else {
        await _showSingleNotification(message);
      }
      
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
      throw StateError('LocalNotificationService not initialized');
    }
    
    try {
      // Mark notification as read
      final updatedMessage = message.copyWith(isRead: true);
      await _updateNotification(updatedMessage);
      
      // Add to message stream for routing
      _messageController.add(updatedMessage);
      
      if (kDebugMode) {
        print('Local notification tapped: ${message.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling local notification tap: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      throw StateError('LocalNotificationService not initialized');
    }
    
    try {
      // Request permissions for local notifications
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
      
      // For iOS, permissions are requested during initialization
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting local notification permissions: $e');
      }
      return false;
    }
  }
  
  @override
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) {
      throw StateError('LocalNotificationService not initialized');
    }
    
    try {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final enabled = await androidImplementation.areNotificationsEnabled();
        return enabled ?? false;
      }
      
      return true; // Assume enabled for other platforms
    } catch (e) {
      if (kDebugMode) {
        print('Error checking local notification settings: $e');
      }
      return false;
    }
  }
  
  @override
  Future<void> clearAllNotifications() async {
    if (!_isInitialized) {
      throw StateError('LocalNotificationService not initialized');
    }
    
    try {
      // Clear local notifications
      await _localNotifications.cancelAll();
      
      // Clear stored notifications
      await _notificationBox.clear();
      
      // Clear grouped notifications
      _groupedNotifications.clear();
      
      if (kDebugMode) {
        print('All local notifications cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing local notifications: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<List<NotificationMessage>> getNotificationHistory() async {
    if (!_isInitialized) {
      throw StateError('LocalNotificationService not initialized');
    }
    
    try {
      final notifications = <NotificationMessage>[];
      
      for (final key in _notificationBox.keys) {
        final data = _notificationBox.get(key);
        if (data is Map<String, dynamic>) {
          try {
            final notification = NotificationMessage.fromJson(data);
            if (!notification.isExpired) {
              notifications.add(notification);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing stored local notification: $e');
            }
          }
        }
      }
      
      // Sort by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return notifications;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local notification history: $e');
      }
      return [];
    }
  }
  
  /// Schedule a local notification for future delivery
  Future<void> scheduleNotification(
    NotificationMessage message,
    DateTime scheduledTime,
  ) async {
    if (!_isInitialized) {
      throw StateError('LocalNotificationService not initialized');
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
        autoCancel: true,
        enableVibration: true,
        playSound: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.zonedSchedule(
        _getNextNotificationId(),
        message.title,
        message.body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        payload: jsonEncode(message.toJson()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      // Store scheduled notification
      await _storeNotification(message);
      
      if (kDebugMode) {
        print('Local notification scheduled for: $scheduledTime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling local notification: $e');
      }
      rethrow;
    }
  }
  
  /// Cancel a scheduled notification
  Future<void> cancelNotification(String notificationId) async {
    if (!_isInitialized) {
      throw StateError('LocalNotificationService not initialized');
    }
    
    try {
      await _localNotifications.cancel(notificationId.hashCode);
      
      // Remove from storage
      await _notificationBox.delete(notificationId);
      
      if (kDebugMode) {
        print('Local notification cancelled: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling local notification: $e');
      }
      rethrow;
    }
  }
  
  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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
      groupId: _groupKey,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
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
  
  /// Show a single notification
  Future<void> _showSingleNotification(NotificationMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDescription,
      importance: _getAndroidImportance(message.priority),
      priority: _getAndroidPriority(message.priority),
      showWhen: true,
      when: message.timestamp.millisecondsSinceEpoch,
      autoCancel: true,
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      _getNextNotificationId(),
      message.title,
      message.body,
      notificationDetails,
      payload: jsonEncode(message.toJson()),
    );
  }
  
  /// Show a grouped notification to prevent spam
  Future<void> _showGroupedNotification(NotificationMessage message, String groupKey) async {
    // Add to grouped notifications
    _groupedNotifications.putIfAbsent(groupKey, () => []).add(message);
    
    final groupedMessages = _groupedNotifications[groupKey]!;
    final messageCount = groupedMessages.length;
    
    // Show individual notification
    final androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDescription,
      importance: _getAndroidImportance(message.priority),
      priority: _getAndroidPriority(message.priority),
      showWhen: true,
      when: message.timestamp.millisecondsSinceEpoch,
      groupKey: groupKey,
      autoCancel: true,
      enableVibration: true,
      playSound: messageCount == 1, // Only play sound for first notification in group
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      _getNextNotificationId(),
      message.title,
      message.body,
      notificationDetails,
      payload: jsonEncode(message.toJson()),
    );
    
    // Show group summary if we have multiple notifications
    if (messageCount > 1) {
      await _showGroupSummary(groupKey, groupedMessages);
    }
  }
  
  /// Show group summary notification
  Future<void> _showGroupSummary(String groupKey, List<NotificationMessage> messages) async {
    final messageCount = messages.length;
    final latestMessage = messages.last;
    
    String summaryTitle;
    String summaryBody;
    
    switch (latestMessage.type) {
      case NotificationType.odStatusChange:
        summaryTitle = 'OD Status Updates';
        summaryBody = '$messageCount OD requests have status updates';
        break;
      case NotificationType.newODRequest:
        summaryTitle = 'New OD Requests';
        summaryBody = '$messageCount new OD requests received';
        break;
      case NotificationType.reminder:
        summaryTitle = 'Reminders';
        summaryBody = '$messageCount reminders pending';
        break;
      case NotificationType.bulkOperationComplete:
        summaryTitle = 'Bulk Operations';
        summaryBody = '$messageCount bulk operations completed';
        break;
      case NotificationType.systemUpdate:
        summaryTitle = 'System Updates';
        summaryBody = '$messageCount system notifications';
        break;
    }
    
    final androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: _notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      groupKey: groupKey,
      setAsGroupSummary: true,
      autoCancel: true,
      enableVibration: false, // Don't vibrate for summary
      playSound: false, // Don't play sound for summary
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      groupKey.hashCode, // Use group key hash as ID for summary
      summaryTitle,
      summaryBody,
      notificationDetails,
      payload: jsonEncode({
        'type': 'group_summary',
        'group_key': groupKey,
        'message_count': messageCount,
      }),
    );
  }
  
  /// Get group key for notification grouping
  String? _getGroupKey(NotificationMessage message) {
    switch (message.type) {
      case NotificationType.odStatusChange:
        // Group by request ID to prevent multiple status updates for same request
        final requestId = message.data['request_id'] as String?;
        return requestId != null ? 'od_status_$requestId' : 'od_status_updates';
        
      case NotificationType.newODRequest:
        // Group by department or staff member
        final department = message.data['department'] as String?;
        return department != null ? 'new_requests_$department' : 'new_requests';
        
      case NotificationType.reminder:
        // Group by reminder type
        final reminderType = message.data['reminder_type'] as String?;
        return reminderType != null ? 'reminder_$reminderType' : 'reminders';
        
      case NotificationType.bulkOperationComplete:
        // Group bulk operation notifications
        return 'bulk_operations';
        
      case NotificationType.systemUpdate:
        // Group system updates
        return 'system_updates';
    }
  }
  
  /// Load existing grouped notifications from storage
  Future<void> _loadGroupedNotifications() async {
    try {
      final notifications = await getNotificationHistory();
      
      for (final notification in notifications) {
        final groupKey = _getGroupKey(notification);
        if (groupKey != null) {
          _groupedNotifications.putIfAbsent(groupKey, () => []).add(notification);
        }
      }
      
      if (kDebugMode) {
        print('Loaded ${_groupedNotifications.length} notification groups');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading grouped notifications: $e');
      }
    }
  }
  
  /// Get next available notification ID
  int _getNextNotificationId() {
    return _notificationIdCounter++;
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
        print('Error storing local notification: $e');
      }
    }
  }
  
  /// Update stored notification
  Future<void> _updateNotification(NotificationMessage message) async {
    try {
      await _notificationBox.put(message.id, message.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating local notification: $e');
      }
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _messageController.close();
    await _notificationBox.close();
  }
}