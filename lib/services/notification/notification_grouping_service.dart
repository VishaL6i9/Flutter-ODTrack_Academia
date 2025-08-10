import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/models/notification_message.dart';

/// Service for managing notification grouping to prevent spam
class NotificationGroupingService {
  static const String _groupingBoxKey = 'notification_grouping_box';
  static const Duration _groupingWindow = Duration(minutes: 5);
  static const int _maxNotificationsPerGroup = 5;

  
  late Box<dynamic> _groupingBox;
  bool _isInitialized = false;
  
  final Map<String, List<NotificationMessage>> _activeGroups = {};
  final Map<String, Timer> _groupTimers = {};
  
  /// Initialize the grouping service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _groupingBox = await Hive.openBox<dynamic>(_groupingBoxKey);
      await _loadActiveGroups();
      _isInitialized = true;
      
      if (kDebugMode) {
        print('NotificationGroupingService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationGroupingService: $e');
      }
      rethrow;
    }
  }
  
  /// Check if notification should be grouped and return group info
  Future<NotificationGroupResult> shouldGroupNotification(NotificationMessage message) async {
    if (!_isInitialized) {
      throw StateError('NotificationGroupingService not initialized');
    }
    
    try {
      final groupKey = _generateGroupKey(message);
      if (groupKey == null) {
        return const NotificationGroupResult(
          shouldGroup: false,
          groupKey: null,
          groupSize: 0,
          isSpamPrevention: false,
        );
      }
      
      // Check if we already have an active group for this key
      final existingGroup = _activeGroups[groupKey];
      if (existingGroup == null) {
        // Start new group
        await _startNewGroup(groupKey, message);
        return NotificationGroupResult(
          shouldGroup: true,
          groupKey: groupKey,
          groupSize: 1,
          isSpamPrevention: false,
        );
      }
      
      // Check if group is within time window
      final latestMessage = existingGroup.last;
      final timeDifference = message.timestamp.difference(latestMessage.timestamp);
      
      if (timeDifference > _groupingWindow) {
        // Start new group (old one expired)
        await _startNewGroup(groupKey, message);
        return NotificationGroupResult(
          shouldGroup: true,
          groupKey: groupKey,
          groupSize: 1,
          isSpamPrevention: false,
        );
      }
      
      // Add to existing group
      existingGroup.add(message);
      await _saveGroup(groupKey, existingGroup);
      
      // Check if this is spam prevention
      final isSpamPrevention = existingGroup.length > _maxNotificationsPerGroup;
      
      return NotificationGroupResult(
        shouldGroup: true,
        groupKey: groupKey,
        groupSize: existingGroup.length,
        isSpamPrevention: isSpamPrevention,
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('Error checking notification grouping: $e');
      }
      return const NotificationGroupResult(
        shouldGroup: false,
        groupKey: null,
        groupSize: 0,
        isSpamPrevention: false,
      );
    }
  }
  
  /// Get grouped notifications for a specific key
  List<NotificationMessage> getGroupedNotifications(String groupKey) {
    return _activeGroups[groupKey] ?? [];
  }
  
  /// Get all active groups
  Map<String, List<NotificationMessage>> getAllActiveGroups() {
    return Map.from(_activeGroups);
  }
  
  /// Get group summary for display
  NotificationGroupSummary getGroupSummary(String groupKey) {
    final notifications = _activeGroups[groupKey] ?? [];
    if (notifications.isEmpty) {
      return NotificationGroupSummary(
        groupKey: groupKey,
        count: 0,
        latestMessage: null,
        type: null,
        title: '',
        summary: '',
      );
    }
    
    final latestMessage = notifications.last;
    final count = notifications.length;
    final type = latestMessage.type;
    
    String title;
    String summary;
    
    switch (type) {
      case NotificationType.odStatusChange:
        title = 'OD Status Updates';
        summary = count == 1 
            ? '1 OD request status updated'
            : '$count OD requests have status updates';
        break;
        
      case NotificationType.newODRequest:
        title = 'New OD Requests';
        summary = count == 1
            ? '1 new OD request'
            : '$count new OD requests received';
        break;
        
      case NotificationType.reminder:
        title = 'Reminders';
        summary = count == 1
            ? '1 reminder'
            : '$count reminders pending';
        break;
        
      case NotificationType.bulkOperationComplete:
        title = 'Bulk Operations';
        summary = count == 1
            ? '1 bulk operation completed'
            : '$count bulk operations completed';
        break;
        
      case NotificationType.systemUpdate:
        title = 'System Updates';
        summary = count == 1
            ? '1 system notification'
            : '$count system notifications';
        break;
    }
    
    return NotificationGroupSummary(
      groupKey: groupKey,
      count: count,
      latestMessage: latestMessage,
      type: type,
      title: title,
      summary: summary,
    );
  }
  
  /// Clear expired groups
  Future<void> clearExpiredGroups() async {
    if (!_isInitialized) return;
    
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];
      
      for (final entry in _activeGroups.entries) {
        final groupKey = entry.key;
        final notifications = entry.value;
        
        if (notifications.isNotEmpty) {
          final latestMessage = notifications.last;
          final timeDifference = now.difference(latestMessage.timestamp);
          
          if (timeDifference > _groupingWindow) {
            expiredKeys.add(groupKey);
          }
        }
      }
      
      // Remove expired groups
      for (final key in expiredKeys) {
        await _removeGroup(key);
      }
      
      if (kDebugMode && expiredKeys.isNotEmpty) {
        debugPrint('Cleared ${expiredKeys.length} expired notification groups');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing expired groups: $e');
      }
    }
  }
  
  /// Clear all groups
  Future<void> clearAllGroups() async {
    if (!_isInitialized) return;
    
    try {
      // Cancel all timers
      for (final timer in _groupTimers.values) {
        timer.cancel();
      }
      _groupTimers.clear();
      
      // Clear active groups
      _activeGroups.clear();
      
      // Clear storage
      await _groupingBox.clear();
      
      if (kDebugMode) {
        print('Cleared all notification groups');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all groups: $e');
      }
    }
  }
  
  /// Get spam prevention statistics
  NotificationSpamStats getSpamStats() {
    int totalGroups = _activeGroups.length;
    int spamPreventedCount = 0;
    int totalNotifications = 0;
    
    for (final notifications in _activeGroups.values) {
      totalNotifications += notifications.length;
      if (notifications.length > _maxNotificationsPerGroup) {
        spamPreventedCount += notifications.length - _maxNotificationsPerGroup;
      }
    }
    
    return NotificationSpamStats(
      totalGroups: totalGroups,
      totalNotifications: totalNotifications,
      spamPreventedCount: spamPreventedCount,
      groupingEfficiency: totalGroups > 0 
          ? (totalNotifications - totalGroups) / totalNotifications 
          : 0.0,
    );
  }
  
  /// Generate group key for notification
  String? _generateGroupKey(NotificationMessage message) {
    switch (message.type) {
      case NotificationType.odStatusChange:
        // Group by request ID to prevent multiple status updates for same request
        final requestId = message.data['request_id'] as String?;
        return requestId != null ? 'od_status_$requestId' : 'od_status_general';
        
      case NotificationType.newODRequest:
        // Group by department or staff member
        final department = message.data['department'] as String?;
        final staffId = message.data['staff_id'] as String?;
        if (staffId != null) {
          return 'new_requests_staff_$staffId';
        } else if (department != null) {
          return 'new_requests_dept_$department';
        }
        return 'new_requests_general';
        
      case NotificationType.reminder:
        // Group by reminder type
        final reminderType = message.data['reminder_type'] as String?;
        return reminderType != null ? 'reminder_$reminderType' : 'reminder_general';
        
      case NotificationType.bulkOperationComplete:
        // Group by operation type and staff member
        final operationType = message.data['operation_type'] as String?;
        final staffId = message.data['staff_id'] as String?;
        if (operationType != null && staffId != null) {
          return 'bulk_${operationType}_$staffId';
        }
        return 'bulk_operations_general';
        
      case NotificationType.systemUpdate:
        // Group by update type
        final updateType = message.data['update_type'] as String?;
        return updateType != null ? 'system_$updateType' : 'system_general';
    }
  }
  
  /// Start a new group
  Future<void> _startNewGroup(String groupKey, NotificationMessage message) async {
    // Cancel existing timer if any
    _groupTimers[groupKey]?.cancel();
    
    // Create new group
    _activeGroups[groupKey] = [message];
    
    // Save to storage
    await _saveGroup(groupKey, [message]);
    
    // Set timer to clean up group after window expires
    _groupTimers[groupKey] = Timer(_groupingWindow, () {
      _removeGroup(groupKey);
    });
    
    if (kDebugMode) {
      print('Started new notification group: $groupKey');
    }
  }
  
  /// Remove a group
  Future<void> _removeGroup(String groupKey) async {
    // Cancel timer
    _groupTimers[groupKey]?.cancel();
    _groupTimers.remove(groupKey);
    
    // Remove from active groups
    _activeGroups.remove(groupKey);
    
    // Remove from storage
    await _groupingBox.delete(groupKey);
    
    if (kDebugMode) {
      print('Removed notification group: $groupKey');
    }
  }
  
  /// Save group to storage
  Future<void> _saveGroup(String groupKey, List<NotificationMessage> notifications) async {
    try {
      final data = notifications.map((n) => n.toJson()).toList();
      await _groupingBox.put(groupKey, data);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notification group: $e');
      }
    }
  }
  
  /// Load active groups from storage
  Future<void> _loadActiveGroups() async {
    try {
      for (final key in _groupingBox.keys) {
        final data = _groupingBox.get(key);
        if (data is List) {
          final notifications = <NotificationMessage>[];
          
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              try {
                final notification = NotificationMessage.fromJson(item);
                notifications.add(notification);
              } catch (e) {
                if (kDebugMode) {
                  print('Error parsing stored notification in group: $e');
                }
              }
            }
          }
          
          if (notifications.isNotEmpty) {
            _activeGroups[key as String] = notifications;
            
            // Set timer for cleanup if group is still within window
            final latestMessage = notifications.last;
            final timeDifference = DateTime.now().difference(latestMessage.timestamp);
            
            if (timeDifference < _groupingWindow) {
              final remainingTime = _groupingWindow - timeDifference;
              _groupTimers[key] = Timer(remainingTime, () {
                _removeGroup(key);
              });
            } else {
              // Group expired, remove it
              await _removeGroup(key);
            }
          }
        }
      }
      
      if (kDebugMode) {
        print('Loaded ${_activeGroups.length} active notification groups');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error loading active groups: $e');
      }
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    // Cancel all timers
    for (final timer in _groupTimers.values) {
      timer.cancel();
    }
    _groupTimers.clear();
    
    // Close storage
    await _groupingBox.close();
  }
}

/// Result of notification grouping check
class NotificationGroupResult {
  final bool shouldGroup;
  final String? groupKey;
  final int groupSize;
  final bool isSpamPrevention;
  
  const NotificationGroupResult({
    required this.shouldGroup,
    required this.groupKey,
    required this.groupSize,
    required this.isSpamPrevention,
  });
}

/// Summary of a notification group
class NotificationGroupSummary {
  final String groupKey;
  final int count;
  final NotificationMessage? latestMessage;
  final NotificationType? type;
  final String title;
  final String summary;
  
  const NotificationGroupSummary({
    required this.groupKey,
    required this.count,
    required this.latestMessage,
    required this.type,
    required this.title,
    required this.summary,
  });
}

/// Statistics about spam prevention
class NotificationSpamStats {
  final int totalGroups;
  final int totalNotifications;
  final int spamPreventedCount;
  final double groupingEfficiency;
  
  const NotificationSpamStats({
    required this.totalGroups,
    required this.totalNotifications,
    required this.spamPreventedCount,
    required this.groupingEfficiency,
  });
}