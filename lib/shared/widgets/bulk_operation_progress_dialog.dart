import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/providers/bulk_operation_provider.dart';

/// Dialog widget that shows bulk operation progress with cancellation option
class BulkOperationProgressDialog extends ConsumerWidget {
  final String title;
  final VoidCallback? onCancel;

  const BulkOperationProgressDialog({
    super.key,
    required this.title,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bulkState = ref.watch(bulkOperationProvider);
    final progress = bulkState.currentProgress;

    if (progress == null) {
      return const SizedBox.shrink();
    }

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress text
          Text(
            '${progress.processedItems} of ${progress.totalItems} items processed',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          
          // Progress percentage
          Text(
            '${(progress.progress * 100).toInt()}% complete',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          if (progress.message != null) ...[
            const SizedBox(height: 8),
            Text(
              progress.message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
          
          if (progress.currentItem.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Processing: ${progress.currentItem}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}

/// Shows a bulk operation progress dialog
Future<void> showBulkOperationProgressDialog({
  required BuildContext context,
  required String title,
  VoidCallback? onCancel,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => BulkOperationProgressDialog(
      title: title,
      onCancel: onCancel,
    ),
  );
}