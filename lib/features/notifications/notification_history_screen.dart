import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/models/notification_message.dart';
import 'package:odtrack_academia/providers/notification_provider.dart';
import 'package:odtrack_academia/features/notifications/widgets/notification_item_widget.dart';
import 'package:odtrack_academia/features/notifications/widgets/notification_filter_widget.dart';
import 'package:odtrack_academia/features/notifications/widgets/notification_group_widget.dart';
import 'package:odtrack_academia/shared/widgets/loading_widget.dart';
import 'package:odtrack_academia/shared/widgets/error_widget.dart' as custom_widgets;
import 'package:odtrack_academia/shared/widgets/empty_state_widget.dart';

/// Screen for displaying notification history and management
class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends ConsumerState<NotificationHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  NotificationFilter _currentFilter = const NotificationFilter();
  bool _showGrouped = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_showGrouped ? MdiIcons.viewList : MdiIcons.viewModule),
            onPressed: () {
              setState(() {
                _showGrouped = !_showGrouped;
              });
            },
            tooltip: _showGrouped ? 'Show individual notifications' : 'Show grouped notifications',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: ListTile(
                  leading: Icon(Icons.mark_email_read),
                  title: Text('Mark all as read'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Clear all'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Notification settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'All',
              icon: Badge(
                label: Text('${notificationState.notifications.length}'),
                child: const Icon(Icons.notifications),
              ),
            ),
            Tab(
              text: 'Unread',
              icon: Badge(
                label: Text('${notificationState.unreadCount}'),
                child: const Icon(Icons.notifications_active),
              ),
            ),
            Tab(
              text: 'Recent',
              icon: Badge(
                label: Text('${ref.watch(recentNotificationsProvider).length}'),
                child: const Icon(Icons.schedule),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter section
          NotificationFilterWidget(
            currentFilter: _currentFilter,
            onFilterChanged: (filter) {
              setState(() {
                _currentFilter = filter;
              });
            },
          ),
          
          // Statistics section
          if (notificationState.notifications.isNotEmpty)
            _buildStatisticsSection(notificationState),
          
          // Content section
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllNotifications(notificationState),
                _buildUnreadNotifications(notificationState),
                _buildRecentNotifications(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: notificationState.unreadCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => _markAllAsRead(),
              icon: const Icon(Icons.mark_email_read),
              label: Text('Mark ${notificationState.unreadCount} as read'),
            )
          : null,
    );
  }
  
  Widget _buildStatisticsSection(NotificationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            state.notifications.length.toString(),
            Icons.notifications,
          ),
          _buildStatItem(
            'Unread',
            state.unreadCount.toString(),
            Icons.notifications_active,
            color: Theme.of(context).colorScheme.error,
          ),
          _buildStatItem(
            'High Priority',
            state.notifications
                .where((n) => n.priority == NotificationPriority.high || 
                             n.priority == NotificationPriority.urgent)
                .length
                .toString(),
            Icons.priority_high,
            color: Theme.of(context).colorScheme.primary,
          ),
          _buildStatItem(
            'Today',
            state.notifications
                .where((n) => _isToday(n.timestamp))
                .length
                .toString(),
            Icons.today,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAllNotifications(NotificationState state) {
    final filteredNotifications = _applyFilter(state.notifications);
    
    if (state.isLoading) {
      return const LoadingWidget(message: 'Loading notifications...');
    }
    
    if (state.error != null) {
      return custom_widgets.CustomErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(notificationProvider.notifier).forceRefresh(),
      );
    }
    
    if (filteredNotifications.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.notifications_none,
        title: 'No notifications',
        message: 'You don\'t have any notifications matching the current filter.',
      );
    }
    
    return _showGrouped
        ? _buildGroupedNotifications(filteredNotifications)
        : _buildIndividualNotifications(filteredNotifications);
  }
  
  Widget _buildUnreadNotifications(NotificationState state) {
    final unreadNotifications = _applyFilter(
      state.notifications.where((n) => !n.isRead).toList(),
    );
    
    if (unreadNotifications.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.mark_email_read,
        title: 'All caught up!',
        message: 'You have no unread notifications.',
      );
    }
    
    return _showGrouped
        ? _buildGroupedNotifications(unreadNotifications)
        : _buildIndividualNotifications(unreadNotifications);
  }
  
  Widget _buildRecentNotifications() {
    final recentNotifications = _applyFilter(ref.watch(recentNotificationsProvider));
    
    if (recentNotifications.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.schedule,
        title: 'No recent notifications',
        message: 'You don\'t have any notifications from the last 24 hours.',
      );
    }
    
    return _showGrouped
        ? _buildGroupedNotifications(recentNotifications)
        : _buildIndividualNotifications(recentNotifications);
  }
  
  Widget _buildGroupedNotifications(List<NotificationMessage> notifications) {
    final groupedNotifications = _groupNotifications(notifications);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedNotifications.length,
      itemBuilder: (context, index) {
        final entry = groupedNotifications.entries.elementAt(index);
        final groupType = entry.key;
        final groupNotifications = entry.value;
        
        return NotificationGroupWidget(
          type: groupType,
          notifications: groupNotifications,
          onTap: (notification) => _handleNotificationTap(notification),
          onMarkAsRead: (notification) => _markAsRead(notification.id),
          onMarkGroupAsRead: () => _markGroupAsRead(groupNotifications),
        );
      },
    );
  }
  
  Widget _buildIndividualNotifications(List<NotificationMessage> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        
        return NotificationItemWidget(
          notification: notification,
          onTap: () => _handleNotificationTap(notification),
          onMarkAsRead: () => _markAsRead(notification.id),
          onDismiss: () => _dismissNotification(notification.id),
        );
      },
    );
  }
  
  Map<NotificationType, List<NotificationMessage>> _groupNotifications(
    List<NotificationMessage> notifications,
  ) {
    final grouped = <NotificationType, List<NotificationMessage>>{};
    
    for (final notification in notifications) {
      grouped.putIfAbsent(notification.type, () => []).add(notification);
    }
    
    // Sort each group by timestamp (newest first)
    for (final group in grouped.values) {
      group.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    
    return grouped;
  }
  
  List<NotificationMessage> _applyFilter(List<NotificationMessage> notifications) {
    return notifications.where((notification) {
      // Filter by type
      if (_currentFilter.types.isNotEmpty && 
          !_currentFilter.types.contains(notification.type)) {
        return false;
      }
      
      // Filter by priority
      if (_currentFilter.priorities.isNotEmpty && 
          !_currentFilter.priorities.contains(notification.priority)) {
        return false;
      }
      
      // Filter by date range
      if (_currentFilter.startDate != null && 
          notification.timestamp.isBefore(_currentFilter.startDate!)) {
        return false;
      }
      
      if (_currentFilter.endDate != null && 
          notification.timestamp.isAfter(_currentFilter.endDate!)) {
        return false;
      }
      
      // Filter by read status
      if (_currentFilter.showOnlyUnread && notification.isRead) {
        return false;
      }
      
      // Filter by search query
      if (_currentFilter.searchQuery.isNotEmpty) {
        final query = _currentFilter.searchQuery.toLowerCase();
        return notification.title.toLowerCase().contains(query) ||
               notification.body.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }
  
  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        _markAllAsRead();
        break;
      case 'clear_all':
        _clearAllNotifications();
        break;
      case 'settings':
        _openNotificationSettings();
        break;
    }
  }
  
  void _handleNotificationTap(NotificationMessage notification) {
    // Mark as read if not already read
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }
    
    // Handle routing through notification router
    // This will be handled by the notification provider
  }
  
  void _markAsRead(String notificationId) {
    ref.read(notificationProvider.notifier).markAsRead(notificationId);
  }
  
  void _markGroupAsRead(List<NotificationMessage> notifications) {
    for (final notification in notifications) {
      if (!notification.isRead) {
        _markAsRead(notification.id);
      }
    }
  }
  
  void _markAllAsRead() {
    ref.read(notificationProvider.notifier).markAllAsRead();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _clearAllNotifications() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(notificationProvider.notifier).clearAllNotifications();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
  
  void _dismissNotification(String notificationId) {
    // For now, just mark as read
    // In the future, this could remove the notification entirely
    _markAsRead(notificationId);
  }
  
  void _openNotificationSettings() {
    // Navigate to notification settings screen
    context.push('/settings/notifications');
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
}

/// Filter configuration for notifications
class NotificationFilter {
  final List<NotificationType> types;
  final List<NotificationPriority> priorities;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool showOnlyUnread;
  final String searchQuery;
  
  const NotificationFilter({
    this.types = const [],
    this.priorities = const [],
    this.startDate,
    this.endDate,
    this.showOnlyUnread = false,
    this.searchQuery = '',
  });
  
  NotificationFilter copyWith({
    List<NotificationType>? types,
    List<NotificationPriority>? priorities,
    DateTime? startDate,
    DateTime? endDate,
    bool? showOnlyUnread,
    String? searchQuery,
  }) {
    return NotificationFilter(
      types: types ?? this.types,
      priorities: priorities ?? this.priorities,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      showOnlyUnread: showOnlyUnread ?? this.showOnlyUnread,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}