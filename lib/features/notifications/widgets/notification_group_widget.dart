import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/models/notification_message.dart';
import 'package:odtrack_academia/features/notifications/widgets/notification_item_widget.dart';

/// Widget for displaying grouped notifications
class NotificationGroupWidget extends StatefulWidget {
  final NotificationType type;
  final List<NotificationMessage> notifications;
  final void Function(NotificationMessage) onTap;
  final void Function(NotificationMessage) onMarkAsRead;
  final VoidCallback onMarkGroupAsRead;

  const NotificationGroupWidget({
    super.key,
    required this.type,
    required this.notifications,
    required this.onTap,
    required this.onMarkAsRead,
    required this.onMarkGroupAsRead,
  });

  @override
  State<NotificationGroupWidget> createState() => _NotificationGroupWidgetState();
}

class _NotificationGroupWidgetState extends State<NotificationGroupWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = widget.notifications.where((n) => !n.isRead).length;
    final latestNotification = widget.notifications.first;
    final hasUnread = unreadCount > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasUnread ? 3 : 1,
      child: Column(
        children: [
          // Group header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: hasUnread
                    ? Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Group type icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getTypeColor(widget.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getTypeIcon(widget.type),
                      size: 24,
                      color: _getTypeColor(widget.type),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Group info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getGroupTitle(widget.type),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            
                            // Unread count badge
                            if (hasUnread)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Group summary
                        Text(
                          _getGroupSummary(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Latest notification time
                        Row(
                          children: [
                            Text(
                              'Latest: ${latestNotification.displayTime}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Total count
                            Text(
                              '${widget.notifications.length} notification${widget.notifications.length == 1 ? '' : 's'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mark group as read button
                      if (hasUnread)
                        IconButton(
                          onPressed: widget.onMarkGroupAsRead,
                          icon: const Icon(Icons.mark_email_read),
                          tooltip: 'Mark group as read',
                          iconSize: 20,
                        ),
                      
                      // Expand/collapse button
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: IconButton(
                          onPressed: _toggleExpanded,
                          icon: const Icon(Icons.expand_more),
                          tooltip: _isExpanded ? 'Collapse' : 'Expand',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Quick actions bar
                  if (_isExpanded && hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          Text(
                            '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                            style: theme.textTheme.bodySmall,
                          ),
                          
                          const Spacer(),
                          
                          TextButton.icon(
                            onPressed: widget.onMarkGroupAsRead,
                            icon: const Icon(Icons.mark_email_read, size: 16),
                            label: const Text('Mark all as read'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Individual notifications
                  if (_isExpanded)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.notifications.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notification = widget.notifications[index];
                        return NotificationItemWidget(
                          notification: notification,
                          onTap: () => widget.onTap(notification),
                          onMarkAsRead: () => widget.onMarkAsRead(notification),
                          isCompact: true,
                          showActions: false,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  String _getGroupTitle(NotificationType type) {
    switch (type) {
      case NotificationType.odStatusChange:
        return 'OD Status Updates';
      case NotificationType.newODRequest:
        return 'New OD Requests';
      case NotificationType.reminder:
        return 'Reminders';
      case NotificationType.bulkOperationComplete:
        return 'Bulk Operations';
      case NotificationType.systemUpdate:
        return 'System Updates';
    }
  }
  
  String _getGroupSummary() {
    final count = widget.notifications.length;
    final latestNotification = widget.notifications.first;
    
    String baseSummary;
    switch (widget.type) {
      case NotificationType.odStatusChange:
        baseSummary = count == 1
            ? 'OD request status changed'
            : '$count OD requests have status updates';
        break;
      case NotificationType.newODRequest:
        baseSummary = count == 1
            ? 'New OD request received'
            : '$count new OD requests received';
        break;
      case NotificationType.reminder:
        baseSummary = count == 1
            ? 'Reminder notification'
            : '$count reminder notifications';
        break;
      case NotificationType.bulkOperationComplete:
        baseSummary = count == 1
            ? 'Bulk operation completed'
            : '$count bulk operations completed';
        break;
      case NotificationType.systemUpdate:
        baseSummary = count == 1
            ? 'System notification'
            : '$count system notifications';
        break;
    }
    
    // Add latest notification preview
    if (latestNotification.body.isNotEmpty) {
      final preview = latestNotification.body.length > 50
          ? '${latestNotification.body.substring(0, 50)}...'
          : latestNotification.body;
      baseSummary += ' • $preview';
    }
    
    return baseSummary;
  }
  
  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.odStatusChange:
        return MdiIcons.fileDocumentEdit;
      case NotificationType.newODRequest:
        return MdiIcons.fileDocumentPlus;
      case NotificationType.reminder:
        return MdiIcons.bell;
      case NotificationType.bulkOperationComplete:
        return MdiIcons.checkboxMultipleMarked;
      case NotificationType.systemUpdate:
        return MdiIcons.update;
    }
  }
  
  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.odStatusChange:
        return Colors.blue;
      case NotificationType.newODRequest:
        return Colors.green;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.bulkOperationComplete:
        return Colors.purple;
      case NotificationType.systemUpdate:
        return Colors.grey;
    }
  }
}