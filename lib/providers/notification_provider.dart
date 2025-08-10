import 'dart:async';
import 'package:flutter/foundation.dart';
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
  final int badgeCount;
  final bool isLoading;
  final String? error;
  final Map<String, int> notificationCounts;
  final DateTime? lastRefresh;
  final bool isRouting;

  const NotificationState({
    this.notifications = const [],
    this.isInitialized = false,
    this.deviceToken,
    this.permissionsGranted = false,
    this.unreadCount = 0,
    this.badgeCount = 0,
    this.isLoading = false,
    this.error,
    this.notificationCounts = const {},
    this.lastRefresh,
    this.isRouting = false,
  });

  NotificationState copyWith({
    List<NotificationMessage>? notifications,
    bool? isInitialized,
    String? deviceToken,
    bool? permissionsGranted,
    int? unreadCount,
    int? badgeCount,
    bool? isLoading,
    String? error,
    Map<String, int>? notificationCounts,
    DateTime? lastRefresh,
    bool? isRouting,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isInitialized: isInitialized ?? this.isInitialized,
      deviceToken: deviceToken ?? this.deviceToken,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      unreadCount: unreadCount ?? this.unreadCount,
      badgeCount: badgeCount ?? this.badgeCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      notificationCounts: notificationCounts ?? this.notificationCounts,
      lastRefresh: lastRefresh ?? this.lastRefresh,
      isRouting: isRouting ?? this.isRouting,
    );
  }

  /// Get notification count by type
  int getCountByType(NotificationType type) {
    return notificationCounts[type.toString()] ?? 0;
  }

  /// Check if there are any high priority unread notifications
  bool get hasHighPriorityUnread {
    return notifications.any((n) => 
      !n.isRead && 
      (n.priority == NotificationPriority.high || n.priority == NotificationPriority.urgent)
    );
  }

  /// Get grouped notifications by type
  Map<NotificationType, List<NotificationMessage>> get groupedNotifications {
    final grouped = <NotificationType, List<NotificationMessage>>{};
    for (final notification in notifications) {
      grouped.putIfAbsent(notification.type, () => []).add(notification);
    }
    return grouped;
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
      final badgeCount = notifications
          .where((n) => !n.isRead && NotificationRouter.shouldShowBadge(n))
          .length;
      final notificationCounts = _calculateNotificationCounts(notifications);
      
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
      
      // Set up periodic cleanup of expired notifications
      Timer.periodic(
        const Duration(hours: 1),
        (_) => removeExpiredNotifications(),
      );
      
      state = state.copyWith(
        isInitialized: true,
        permissionsGranted: permissionsGranted,
        deviceToken: deviceToken,
        notifications: notifications,
        unreadCount: unreadCount,
        badgeCount: badgeCount,
        notificationCounts: notificationCounts,
        lastRefresh: DateTime.now(),
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
      
      // Calculate badge count (only for notifications that should show badge)
      final badgeCount = updatedNotifications
          .where((n) => !n.isRead && NotificationRouter.shouldShowBadge(n))
          .length;
      
      // Update notification counts by type
      final notificationCounts = _calculateNotificationCounts(updatedNotifications);
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
        badgeCount: badgeCount,
        notificationCounts: notificationCounts,
        lastRefresh: DateTime.now(),
      );
      
      // Handle notification routing if app is active and not already routing
      // Note: We don't automatically mark as read here - that should be done when user actually interacts
      if (!state.isRouting) {
        await _routeNotificationWithoutMarkingRead(message);
      }
      
      if (kDebugMode) {
        print('Handled incoming notification: ${message.title}');
        print('Unread count: $unreadCount, Badge count: $badgeCount');
      }
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to handle notification: $e');
      if (kDebugMode) {
        print('Error handling incoming notification: $e');
      }
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
      final badgeCount = updatedNotifications
          .where((n) => !n.isRead && NotificationRouter.shouldShowBadge(n))
          .length;
      final notificationCounts = _calculateNotificationCounts(updatedNotifications);
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
        badgeCount: badgeCount,
        notificationCounts: notificationCounts,
        lastRefresh: DateTime.now(),
      );
      
      if (kDebugMode) {
        print('Marked notification as read: $notificationId');
        print('Updated unread count: $unreadCount, badge count: $badgeCount');
      }
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark notification as read: $e');
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final updatedNotifications = state.notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
      
      final notificationCounts = _calculateNotificationCounts(updatedNotifications);
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
        badgeCount: 0,
        notificationCounts: notificationCounts,
        lastRefresh: DateTime.now(),
      );
      
      if (kDebugMode) {
        print('Marked all notifications as read');
      }
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark all notifications as read: $e');
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _notificationService.clearAllNotifications();
      
      state = state.copyWith(
        notifications: [],
        unreadCount: 0,
        badgeCount: 0,
        notificationCounts: {},
        lastRefresh: DateTime.now(),
      );
      
      if (kDebugMode) {
        print('Cleared all notifications');
      }
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear notifications: $e');
      if (kDebugMode) {
        print('Error clearing notifications: $e');
      }
    }
  }

  /// Refresh notification history
  Future<void> _refreshNotifications() async {
    try {
      final notifications = await _notificationService.getNotificationHistory();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      final badgeCount = notifications
          .where((n) => !n.isRead && NotificationRouter.shouldShowBadge(n))
          .length;
      final notificationCounts = _calculateNotificationCounts(notifications);
      
      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        badgeCount: badgeCount,
        notificationCounts: notificationCounts,
        lastRefresh: DateTime.now(),
      );
      
      if (kDebugMode) {
        print('Refreshed notifications: ${notifications.length} total, $unreadCount unread');
      }
      
    } catch (e) {
      // Silently handle refresh errors to avoid disrupting user experience
      if (kDebugMode) {
        print('Error refreshing notifications: $e');
      }
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

  /// Route notification without marking as read (for incoming notifications)
  Future<void> _routeNotificationWithoutMarkingRead(NotificationMessage notification) async {
    try {
      state = state.copyWith(isRouting: true);
      
      // Use enhanced notification router
      await NotificationRouter.routeFromNotification(_router, notification);
      
      if (kDebugMode) {
        print('Successfully routed notification without marking as read: ${notification.id}');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error routing notification: $e');
      }
    } finally {
      state = state.copyWith(isRouting: false);
    }
  }

  /// Calculate notification counts by type
  Map<String, int> _calculateNotificationCounts(List<NotificationMessage> notifications) {
    final counts = <String, int>{};
    
    for (final notification in notifications) {
      final typeKey = notification.type.toString();
      counts[typeKey] = (counts[typeKey] ?? 0) + 1;
      
      // Also count unread notifications by type
      if (!notification.isRead) {
        final unreadTypeKey = '${typeKey}_unread';
        counts[unreadTypeKey] = (counts[unreadTypeKey] ?? 0) + 1;
      }
    }
    
    return counts;
  }

  /// Mark notifications as read by type
  Future<void> markAsReadByType(NotificationType type) async {
    try {
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.type == type && !notification.isRead) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();
      
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      final badgeCount = updatedNotifications
          .where((n) => !n.isRead && NotificationRouter.shouldShowBadge(n))
          .length;
      final notificationCounts = _calculateNotificationCounts(updatedNotifications);
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
        badgeCount: badgeCount,
        notificationCounts: notificationCounts,
        lastRefresh: DateTime.now(),
      );
      
      if (kDebugMode) {
        print('Marked notifications as read by type: $type');
      }
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark notifications as read by type: $e');
      if (kDebugMode) {
        print('Error marking notifications as read by type: $e');
      }
    }
  }

  /// Remove expired notifications
  Future<void> removeExpiredNotifications() async {
    try {
      final now = DateTime.now();
      final validNotifications = state.notifications
          .where((n) => n.expiresAt == null || n.expiresAt!.isAfter(now))
          .toList();
      
      if (validNotifications.length != state.notifications.length) {
        final unreadCount = validNotifications.where((n) => !n.isRead).length;
        final badgeCount = validNotifications
            .where((n) => !n.isRead && NotificationRouter.shouldShowBadge(n))
            .length;
        final notificationCounts = _calculateNotificationCounts(validNotifications);
        
        state = state.copyWith(
          notifications: validNotifications,
          unreadCount: unreadCount,
          badgeCount: badgeCount,
          notificationCounts: notificationCounts,
          lastRefresh: DateTime.now(),
        );
        
        if (kDebugMode) {
          print('Removed ${state.notifications.length - validNotifications.length} expired notifications');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error removing expired notifications: $e');
      }
    }
  }

  /// Get notification badge count for specific type
  int getBadgeCountByType(NotificationType type) {
    return state.notifications
        .where((n) => n.type == type && !n.isRead && NotificationRouter.shouldShowBadge(n))
        .length;
  }

  /// Handle notification action (for actionable notifications)
  Future<void> handleNotificationAction(String notificationId, String actionId) async {
    try {
      final notification = state.notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => throw Exception('Notification not found'),
      );
      
      final action = notification.actions?.firstWhere(
        (a) => a.id == actionId,
        orElse: () => throw Exception('Action not found'),
      );
      
      if (action != null) {
        // Mark notification as read
        await markAsRead(notificationId);
        
        // Handle the specific action based on action data
        if (action.data != null) {
          // Route to specific screen or perform action based on action data
          // This can be extended based on specific action requirements
          if (kDebugMode) {
            print('Handled notification action: $actionId for notification: $notificationId');
          }
        }
      }
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to handle notification action: $e');
      if (kDebugMode) {
        print('Error handling notification action: $e');
      }
    }
  }

  /// Force refresh notifications from service
  Future<void> forceRefresh() async {
    state = state.copyWith(isLoading: true);
    await _refreshNotifications();
    state = state.copyWith(isLoading: false);
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

/// Provider for notification badge count
final notificationBadgeCountProvider = Provider<int>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.badgeCount;
});

/// Provider for badge count by type
final badgeCountByTypeProvider = Provider.family<int, NotificationType>((ref, type) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.notifications
      .where((n) => n.type == type && !n.isRead && NotificationRouter.shouldShowBadge(n))
      .length;
});

/// Provider for high priority unread notifications
final highPriorityUnreadProvider = Provider<bool>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.hasHighPriorityUnread;
});

/// Provider for grouped notifications
final groupedNotificationsProvider = Provider<Map<NotificationType, List<NotificationMessage>>>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.groupedNotifications;
});

/// Provider for notification counts by type
final notificationCountsProvider = Provider<Map<String, int>>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.notificationCounts;
});

/// Provider for unread notifications by type
final unreadNotificationsByTypeProvider = Provider.family<List<NotificationMessage>, NotificationType>((ref, type) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.notifications
      .where((n) => n.type == type && !n.isRead)
      .toList();
});

/// Provider for actionable notifications
final actionableNotificationsProvider = Provider<List<NotificationMessage>>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.notifications
      .where((n) => n.hasActions && !n.isRead)
      .toList();
});
