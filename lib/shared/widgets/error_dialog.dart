import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';
import 'package:odtrack_academia/core/errors/error_recovery_service.dart';

/// Enhanced error dialog with contextual actions and recovery options
class EnhancedErrorDialog extends StatelessWidget {
  final BaseError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showTechnicalDetails;

  const EnhancedErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showTechnicalDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recoveryService = ErrorRecoveryService.instance;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          _buildErrorIcon(theme),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getErrorTitle(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: _getErrorColor(theme),
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User-friendly error message
            Text(
              error.displayMessage,
              style: theme.textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 16),
            
            // Recovery suggestion
            _buildRecoverySuggestion(theme, recoveryService),
            
            // Technical details (if enabled)
            if (showTechnicalDetails) ...[
              const SizedBox(height: 16),
              _buildTechnicalDetails(theme),
            ],
          ],
        ),
      ),
      actions: _buildActions(context, recoveryService),
    );
  }

  Widget _buildErrorIcon(ThemeData theme) {
    IconData iconData;
    Color iconColor;
    
    switch (error.severity) {
      case ErrorSeverity.low:
        iconData = Icons.info_outline;
        iconColor = theme.colorScheme.primary;
        break;
      case ErrorSeverity.medium:
        iconData = Icons.warning_amber_outlined;
        iconColor = Colors.orange;
        break;
      case ErrorSeverity.high:
        iconData = Icons.error_outline;
        iconColor = theme.colorScheme.error;
        break;
      case ErrorSeverity.critical:
        iconData = Icons.dangerous_outlined;
        iconColor = Colors.red.shade700;
        break;
    }
    
    return Icon(iconData, color: iconColor, size: 28);
  }

  String _getErrorTitle() {
    switch (error.category) {
      case ErrorCategory.network:
        return 'Connection Problem';
      case ErrorCategory.storage:
        return 'Storage Issue';
      case ErrorCategory.permission:
        return 'Permission Required';
      case ErrorCategory.sync:
        return 'Sync Problem';
      case ErrorCategory.export:
        return 'Export Failed';
      case ErrorCategory.calendar:
        return 'Calendar Issue';
      case ErrorCategory.notification:
        return 'Notification Problem';
      case ErrorCategory.performance:
        return 'Performance Issue';
      case ErrorCategory.validation:
        return 'Input Error';
      case ErrorCategory.authentication:
        return 'Authentication Required';
      case ErrorCategory.unknown:
        return 'Unexpected Error';
    }
  }

  Color _getErrorColor(ThemeData theme) {
    switch (error.severity) {
      case ErrorSeverity.low:
        return theme.colorScheme.primary;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        return theme.colorScheme.error;
    }
  }

  Widget _buildRecoverySuggestion(ThemeData theme, ErrorRecoveryService recoveryService) {
    final suggestion = recoveryService.getRecoveryAction(error);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Action',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalDetails(ThemeData theme) {
    return ExpansionTile(
      title: Text(
        'Technical Details',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Error Code', error.code, theme),
              _buildDetailRow('Category', error.category.name, theme),
              _buildDetailRow('Severity', error.severity.name, theme),
              _buildDetailRow('Timestamp', _formatTimestamp(error.timestamp), theme),
              if (error.context != null && error.context!.isNotEmpty)
                _buildDetailRow('Context', error.context.toString(), theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} '
           '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  List<Widget> _buildActions(BuildContext context, ErrorRecoveryService recoveryService) {
    final actions = <Widget>[];
    
    // Copy error details action
    actions.add(
      TextButton.icon(
        onPressed: () => _copyErrorDetails(context),
        icon: const Icon(Icons.copy, size: 16),
        label: const Text('Copy Details'),
      ),
    );
    
    // Dismiss action
    actions.add(
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          onDismiss?.call();
        },
        child: const Text('Dismiss'),
      ),
    );
    
    // Retry action (if error is retryable)
    if (error.isRetryable && onRetry != null) {
      actions.add(
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onRetry!();
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry'),
        ),
      );
    }
    
    // Settings action (for permission errors)
    if (error.category == ErrorCategory.permission) {
      actions.add(
        FilledButton.icon(
          onPressed: () => _openSettings(context),
          icon: const Icon(Icons.settings, size: 16),
          label: const Text('Settings'),
        ),
      );
    }
    
    return actions;
  }

  void _copyErrorDetails(BuildContext context) {
    final details = '''
Error: ${error.displayMessage}
Code: ${error.code}
Category: ${error.category.name}
Severity: ${error.severity.name}
Timestamp: ${_formatTimestamp(error.timestamp)}
${error.context != null ? 'Context: ${error.context}' : ''}
''';
    
    Clipboard.setData(ClipboardData(text: details));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error details copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    // In a real implementation, this would open the app settings
    // For now, we'll show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please grant the required permission in device settings'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Static method to show the enhanced error dialog
  static Future<void> show(
    BuildContext context,
    BaseError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool showTechnicalDetails = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedErrorDialog(
        error: error,
        onRetry: onRetry,
        onDismiss: onDismiss,
        showTechnicalDetails: showTechnicalDetails,
      ),
    );
  }
}

/// Simplified error snackbar for less critical errors
class ErrorSnackBar {
  static void show(
    BuildContext context,
    BaseError error, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error.severity),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getErrorTitle(error.category),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    error.displayMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error.severity),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: error.isRetryable && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static IconData _getErrorIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Icons.info_outline;
      case ErrorSeverity.medium:
        return Icons.warning_amber_outlined;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        return Icons.error_outline;
    }
  }

  static String _getErrorTitle(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.network:
        return 'Connection Error';
      case ErrorCategory.storage:
        return 'Storage Error';
      case ErrorCategory.permission:
        return 'Permission Required';
      case ErrorCategory.sync:
        return 'Sync Error';
      case ErrorCategory.export:
        return 'Export Failed';
      case ErrorCategory.calendar:
        return 'Calendar Error';
      case ErrorCategory.notification:
        return 'Notification Error';
      case ErrorCategory.performance:
        return 'Performance Issue';
      case ErrorCategory.validation:
        return 'Input Error';
      case ErrorCategory.authentication:
        return 'Authentication Error';
      case ErrorCategory.unknown:
        return 'Error';
    }
  }

  static Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        return Colors.red;
    }
  }
}