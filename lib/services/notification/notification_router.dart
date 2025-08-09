import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:odtrack_academia/models/notification_message.dart';

/// Handles routing based on notification data
class NotificationRouter {
  static const String _odRequestRoute = '/od-request';
  static const String _staffInboxRoute = '/staff/inbox';
  static const String _dashboardRoute = '/dashboard';
  static const String _profileRoute = '/profile';
  static const String _analyticsRoute = '/analytics';
  
  /// Route to appropriate screen based on notification type and data
  static Future<void> routeFromNotification(
    GoRouter router,
    NotificationMessage notification,
  ) async {
    try {
      final route = _determineRoute(notification);
      
      if (route != null) {
        // Navigate to the determined route
        router.go(route);
        
        if (kDebugMode) {
          print('Routed to: $route from notification: ${notification.id}');
        }
      } else {
        // Default to dashboard if no specific route determined
        router.go(_dashboardRoute);
        
        if (kDebugMode) {
          print('No specific route found, defaulting to dashboard');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error routing from notification: $e');
      }
      
      // Fallback to dashboard on error
      router.go(_dashboardRoute);
    }
  }
  
  /// Determine the appropriate route based on notification data
  static String? _determineRoute(NotificationMessage notification) {
    // Check if there's a direct action URL
    if (notification.actionUrl != null && notification.actionUrl!.isNotEmpty) {
      return notification.actionUrl;
    }
    
    // Route based on notification type
    switch (notification.type) {
      case NotificationType.odStatusChange:
        return _routeForODStatusChange(notification);
        
      case NotificationType.newODRequest:
        return _routeForNewODRequest(notification);
        
      case NotificationType.bulkOperationComplete:
        return _routeForBulkOperation(notification);
        
      case NotificationType.reminder:
        return _routeForReminder(notification);
        
      case NotificationType.systemUpdate:
        return _dashboardRoute;
    }
  }
  
  /// Route for OD status change notifications
  static String _routeForODStatusChange(NotificationMessage notification) {
    final requestId = notification.data['request_id'] as String?;
    
    if (requestId != null) {
      return '$_odRequestRoute/$requestId';
    }
    
    // If no specific request ID, go to user's OD requests list
    return '/od-requests';
  }
  
  /// Route for new OD request notifications (for staff)
  static String _routeForNewODRequest(NotificationMessage notification) {
    final requestId = notification.data['request_id'] as String?;
    
    if (requestId != null) {
      // Route to specific request in staff inbox
      return '$_staffInboxRoute?highlight=$requestId';
    }
    
    // Default to staff inbox
    return _staffInboxRoute;
  }
  
  /// Route for bulk operation completion notifications
  static String _routeForBulkOperation(NotificationMessage notification) {
    final operationType = notification.data['operation_type'] as String?;
    final resultSummary = notification.data['result_summary'] as String?;
    
    // Route to staff inbox with bulk operation results
    if (operationType != null) {
      return '$_staffInboxRoute?bulk_result=$operationType';
    }
    
    return _staffInboxRoute;
  }
  
  /// Route for reminder notifications
  static String _routeForReminder(NotificationMessage notification) {
    final reminderType = notification.data['reminder_type'] as String?;
    
    switch (reminderType) {
      case 'pending_approval':
        return _staffInboxRoute;
        
      case 'upcoming_od':
        final requestId = notification.data['request_id'] as String?;
        if (requestId != null) {
          return '$_odRequestRoute/$requestId';
        }
        return '/od-requests';
        
      case 'profile_incomplete':
        return _profileRoute;
        
      case 'analytics_available':
        return _analyticsRoute;
        
      default:
        return _dashboardRoute;
    }
  }
  
  /// Extract query parameters from notification data
  static Map<String, String> extractQueryParams(NotificationMessage notification) {
    final params = <String, String>{};
    
    // Add common parameters
    params['from_notification'] = 'true';
    params['notification_id'] = notification.id;
    
    // Add notification-specific parameters
    switch (notification.type) {
      case NotificationType.odStatusChange:
        final status = notification.data['new_status'] as String?;
        if (status != null) {
          params['status'] = status;
        }
        break;
        
      case NotificationType.newODRequest:
        final priority = notification.data['priority'] as String?;
        if (priority != null) {
          params['priority'] = priority;
        }
        break;
        
      case NotificationType.bulkOperationComplete:
        final operationType = notification.data['operation_type'] as String?;
        final successCount = notification.data['success_count'] as String?;
        final failureCount = notification.data['failure_count'] as String?;
        
        if (operationType != null) params['operation'] = operationType;
        if (successCount != null) params['success'] = successCount;
        if (failureCount != null) params['failures'] = failureCount;
        break;
        
      case NotificationType.reminder:
        final reminderType = notification.data['reminder_type'] as String?;
        if (reminderType != null) {
          params['reminder'] = reminderType;
        }
        break;
        
      case NotificationType.systemUpdate:
        final updateType = notification.data['update_type'] as String?;
        if (updateType != null) {
          params['update'] = updateType;
        }
        break;
    }
    
    return params;
  }
  
  /// Build full route with query parameters
  static String buildRouteWithParams(String basePath, Map<String, String> params) {
    if (params.isEmpty) {
      return basePath;
    }
    
    final queryString = params.entries
        .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
        .join('&');
    
    return '$basePath?$queryString';
  }
  
  /// Check if notification should show badge
  static bool shouldShowBadge(NotificationMessage notification) {
    switch (notification.type) {
      case NotificationType.odStatusChange:
      case NotificationType.newODRequest:
        return true;
        
      case NotificationType.bulkOperationComplete:
      case NotificationType.reminder:
        return notification.priority == NotificationPriority.high ||
               notification.priority == NotificationPriority.urgent;
        
      case NotificationType.systemUpdate:
        return false;
    }
  }
  
  /// Get notification grouping key for similar notifications
  static String? getGroupingKey(NotificationMessage notification) {
    switch (notification.type) {
      case NotificationType.odStatusChange:
        // Group by request ID
        return 'od_status_${notification.data['request_id']}';
        
      case NotificationType.newODRequest:
        // Group by department or staff member
        final department = notification.data['department'] as String?;
        return department != null ? 'new_requests_$department' : 'new_requests';
        
      case NotificationType.bulkOperationComplete:
        // Group by operation type
        final operationType = notification.data['operation_type'] as String?;
        return operationType != null ? 'bulk_$operationType' : 'bulk_operations';
        
      case NotificationType.reminder:
        // Group by reminder type
        final reminderType = notification.data['reminder_type'] as String?;
        return reminderType != null ? 'reminder_$reminderType' : 'reminders';
        
      case NotificationType.systemUpdate:
        return 'system_updates';
    }
  }
  
  /// Check if notification should auto-dismiss after routing
  static bool shouldAutoDismiss(NotificationMessage notification) {
    switch (notification.type) {
      case NotificationType.odStatusChange:
      case NotificationType.newODRequest:
        return false; // Keep these for reference
        
      case NotificationType.bulkOperationComplete:
      case NotificationType.reminder:
      case NotificationType.systemUpdate:
        return true; // These can be dismissed after viewing
    }
  }
}