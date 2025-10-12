import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/providers/export_provider.dart';

/// Widget for displaying export progress with enhanced details
class ExportProgressWidget extends ConsumerWidget {
  final String exportId;
  final bool showDetails;
  final VoidCallback? onCancel;

  const ExportProgressWidget({
    super.key,
    required this.exportId,
    this.showDetails = true,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(enhancedExportProgressProvider(exportId));
    final canCancel = ref.watch(canCancelExportProvider(exportId));
    final estimatedCompletion = ref.watch(estimatedCompletionTimeProvider(exportId));

    if (progress == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and cancel button
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Export Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canCancel && onCancel != null)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: onCancel,
                    tooltip: 'Cancel Export',
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress.isCompleted
                    ? Colors.green
                    : Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 8),

            // Progress percentage and current step
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progress.progressPercentage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (progress.isInProgress)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            // Current step
            Text(
              progress.currentStep,
              style: Theme.of(context).textTheme.bodySmall,
            ),

            if (showDetails) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Additional details
              if (progress.totalItems != null && progress.processedItems != null)
                _buildDetailRow(
                  context,
                  'Items Processed',
                  '${progress.processedItems}/${progress.totalItems}',
                ),

              if (estimatedCompletion != null && progress.isInProgress)
                _buildDetailRow(
                  context,
                  'Estimated Completion',
                  _formatEstimatedTime(estimatedCompletion),
                ),

              _buildDetailRow(
                context,
                'Started',
                _formatTime(progress.timestamp),
              ),

              if (progress.message != null && progress.message != progress.currentStep)
                _buildDetailRow(
                  context,
                  'Details',
                  progress.message!,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatEstimatedTime(DateTime estimatedTime) {
    final now = DateTime.now();
    final difference = estimatedTime.difference(now);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s remaining';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m remaining';
    } else {
      return '${difference.inHours}h ${difference.inMinutes % 60}m remaining';
    }
  }
}

/// Compact version of export progress widget for lists
class CompactExportProgressWidget extends ConsumerWidget {
  final String exportId;
  final VoidCallback? onTap;

  const CompactExportProgressWidget({
    super.key,
    required this.exportId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(enhancedExportProgressProvider(exportId));

    if (progress == null) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: CircularProgressIndicator(
        value: progress.progress,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(
          progress.isCompleted
              ? Colors.green
              : Theme.of(context).primaryColor,
        ),
      ),
      title: Text(progress.currentStep),
      subtitle: Text(progress.progressPercentage),
      trailing: progress.isInProgress
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              progress.isCompleted ? Icons.check_circle : Icons.error,
              color: progress.isCompleted ? Colors.green : Colors.red,
            ),
      onTap: onTap,
    );
  }
}