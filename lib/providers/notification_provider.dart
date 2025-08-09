import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odtrack_academia/models/notification_message.dart';
import 'package:odtrack_academia/services/notification/notification_service.dart';
import 'package:odtrack_academia/services/notification/notification_router.dart';
import 'package:odtrack_academia/core/services/service_registry.dart';

/// State class for notification management
class NotificationState {
  final List<NotificationMessage> notifications;
  final bool isInitialized;
  final String? deviceToken;
  final bool permissionsGranted;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isInitialized = false,
    this.deviceToken,
    this.permissionsGranted = false,
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationMessage>? notifications,
    bool? isInitialized,
    String? deviceToken,
    bool? permissionsGranted,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isInitialized: isInitialized ?? this.isInitialized,
      deviceToken: deviceToken ?? this.deviceToken,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notification provider for managing push notifications and state
class NotificationProvider extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;
  final GoRouter _router;
  
  StreamSubscription<NotificationMessage>? _messageSubscription;
  Timer? _refreshTimer;

  NotificationProvider(this._notificationService, this._router) 
      : super(const NotificationState()) {
    _initialize();
  }

  /// Initialize the notification provider
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Initialize notification service
      await _notificationService.initialize();
      
      // Request permissions
      final permissionsGranted = await _notificationService.requestPermissions();
      
      // Get device token
      final deviceToken = await _notificationService.getDeviceToken();
      
      // Load notification history
      final notifications = await _notificationService.getNotificationHistory();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      
      // Subscribe to incoming messages
      _messageSubscription = _notificationService.onMessageReceived.listen(
        _handleIncomingNotification,
        onError: _handleNotificationError,
      );
      
      // Set up periodic refresh for notification history
      _refreshTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _refreshNotifications(),
      );
      
      state = state.copyWith(
        isInitialized: true,
        permissionsGranted: permissionsGranted,
        deviceToken: deviceToken,
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
      
      // Subscribe to relevant topics based on user role
      await _subscribeToTopics();
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize notifications: $e',
      );
    }
  }

  /// Handle incoming notification messages
  Future<void> _handleIncomingNotification(NotificationMessage message) async {
    try {
      // Add to notifications list
      final updatedNotifications = [message, ...state.notifications];
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
      
      // Handle notification routing if app is active
      await NotificationRouter.routeFromNotification(_router, message);
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to handle notification: $e');
    }
  }

  /// Handle notification errors
  void _handleNotificationError(dynamic error) {
    state = state.copyWith(error: 'Notification error: $error');
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();
      
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final updatedNotifications = state.notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark all notifications as read: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _notificationService.clearAllNotifications();
      
      state = state.copyWith(
        notifications: [],
        unreadCount: 0,
      );
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear notifications: $e');
    }
  }

  /// Refresh notification history
  Future<void> _refreshNotifications() async {
    try {
      final notifications = await _notificationService.getNotificationHistory();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
      );
      
    } catch (e) {
      // Silently handle refresh errors to avoid disrupting user experience
    }
  }

  /// Subscribe to notification topics based on user role
  Future<void> _subscribeToTopics() async {
    try {
      // Subscribe to general topics
      await _notificationService.subscribeToTopic('general');
      await _notificationService.subscribeToTopic('system_updates');
      
      // TODO: Subscribe to user-specific topics based on role and department
      // This will be implemented when user authentication is integrated
      
    } catch (e) {
      // Handle topic subscription errors silently
    }
  }

  /// Subscribe to a specific topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _notificationService.subscribeToTopic(topic);
    } catch (e) {
      state = state.copyWith(error: 'Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from a specific topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _notificationService.unsubscribeFromTopic(topic);
    } catch (e) {
      state = state.copyWith(error: 'Failed to unsubscribe from topic: $e');
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      final granted = await _notificationService.requestPermissions();
      
      state = state.copyWith(permissionsGranted: granted);
      
      return granted;
    } catch (e) {
      state = state.copyWith(error: 'Failed to request permissions: $e');
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      return await _notificationService.areNotificationsEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Get notifications by type
  List<NotificationMessage> getNotificationsByType(NotificationType type) {
    return state.notifications.where((n) => n.type == type).toList();
  }

  /// Get unread notifications
  List<NotificationMessage> get unreadNotifications {
    return state.notifications.where((n) => !n.isRead).toList();
  }

  /// Get recent notifications (last 24 hours)
  List<NotificationMessage> get recentNotifications {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return state.notifications
        .where((n) => n.timestamp.isAfter(yesterday))
        .toList();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return ServiceRegistry.instance.notificationService;
});

/// Provider for router (to be injected)
final routerProvider = Provider<GoRouter>((ref) {
  throw UnimplementedError('Router provider must be overridden');
});

/// Provider for notification state management
final notificationProvider = StateNotifierProvider<NotificationProvider, NotificationState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final router = ref.watch(routerProvider);
  
  return NotificationProvider(notificationService, router);
});

/// Provider for unread notification count
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.unreadCount;
});

/// Provider for recent notifications
final recentNotificationsProvider = Provider<List<NotificationMessage>>((ref) {
  final notificationState = ref.watch(notificationProvider);
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  
  return notificationState.notifications
      .where((n) => n.timestamp.isAfter(yesterday))
      .toList();
});

/// Provider for notifications by type
final notificationsByTypeProvider = Provider.family<List<NotificationMessage>, NotificationType>((ref, type) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.notifications.where((n) => n.type == type).toList();
});
