import 'dart:async';
import '../../models/notification_message.dart';

/// Abstract interface for push notification service
/// Handles Firebase Cloud Messaging and local notifications
abstract class NotificationService {
  /// Initialize the notification service
  Future<void> initialize();
  
  /// Get the device FCM token
  Future<String?> getDeviceToken();
  
  /// Subscribe to a notification topic
  Future<void> subscribeToTopic(String topic);
  
  /// Unsubscribe from a notification topic
  Future<void> unsubscribeFromTopic(String topic);
  
  /// Stream of incoming notification messages
  Stream<NotificationMessage> get onMessageReceived;
  
  /// Show a local notification
  Future<void> showLocalNotification(NotificationMessage message);
  
  /// Handle notification tap events
  Future<void> handleNotificationTap(NotificationMessage message);
  
  /// Request notification permissions
  Future<bool> requestPermissions();
  
  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled();
  
  /// Clear all notifications
  Future<void> clearAllNotifications();
  
  /// Get notification history
  Future<List<NotificationMessage>> getNotificationHistory();
}