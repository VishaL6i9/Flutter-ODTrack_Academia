import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/models/notification_message.dart';

/// Widget for displaying individual notification items
class NotificationItemWidget extends StatelessWidget {
  final NotificationMessage notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDismiss;
  final bool showActions;
  final bool isCompact;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDismiss,
    this.showActions = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.onError,
        ),
      ),
      onDismissed: (_) => onDismiss?.call(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: isUnread ? 2 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isUnread
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Notification type icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getTypeColor(notification.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTypeIcon(notification.type),
                        size: 20,
                        color: _getTypeColor(notification.type),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Title and metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  maxLines: isCompact ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              // Priority indicator
                              if (notification.priority == NotificationPriority.high ||
                                  notification.priority == NotificationPriority.urgent)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(notification.priority),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    notification.priority == NotificationPriority.urgent
                                        ? 'URGENT'
                                        : 'HIGH',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 2),
                          
                          // Timestamp and read status
                          Row(
                            children: [
                              Text(
                                notification.displayTime,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              
                              if (isUnread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Actions menu
                    if (showActions)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onSelected: _handleAction,
                        itemBuilder: (context) => [
                          if (isUnread)
                            const PopupMenuItem(
                              value: 'mark_read',
                              child: ListTile(
                                leading: Icon(Icons.mark_email_read),
                                title: Text('Mark as read'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'dismiss',
                            child: ListTile(
                              leading: Icon(Icons.clear),
                              title: Text('Dismiss'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          if (notification.actionUrl != null)
                            const PopupMenuItem(
                              value: 'open',
                              child: ListTile(
                                leading: Icon(Icons.open_in_new),
                                title: Text('Open'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                
                // Body text
                if (!isCompact) ...[
                  const SizedBox(height: 12),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                // Image if available
                if (notification.imageUrl != null && !isCompact) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      notification.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        width: double.infinity,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
                
                // Action buttons for actionable notifications
                if (notification.hasActions && !isCompact) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: notification.actions!.map((action) {
                      return OutlinedButton.icon(
                        onPressed: () => _handleNotificationAction(action.id),
                        icon: action.icon != null
                            ? Icon(
                                _getActionIcon(action.icon!),
                                size: 16,
                              )
                            : const SizedBox.shrink(),
                        label: Text(action.title),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: action.destructive
                              ? theme.colorScheme.error
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
  
  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }
  
  IconData _getActionIcon(String iconName) {
    switch (iconName) {
      case 'approve':
        return Icons.check;
      case 'reject':
        return Icons.close;
      case 'view':
        return Icons.visibility;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.touch_app;
    }
  }
  
  void _handleAction(String action) {
    switch (action) {
      case 'mark_read':
        onMarkAsRead?.call();
        break;
      case 'dismiss':
        onDismiss?.call();
        break;
      case 'open':
        onTap?.call();
        break;
    }
  }
  
  void _handleNotificationAction(String actionId) {
    // This would be handled by the parent widget or provider
    // For now, just trigger the tap action
    onTap?.call();
  }
}