import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/bulk_operation_models.dart';

/// Dialog widget that shows detailed bulk operation results
class BulkOperationResultDialog extends ConsumerWidget {
  final BulkOperationResult result;
  final VoidCallback? onRetryFailed;
  final VoidCallback? onUndo;

  const BulkOperationResultDialog({
    super.key,
    required this.result,
    this.onRetryFailed,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuccess = result.failedItems == 0;
    final hasErrors = result.errors.isNotEmpty;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.warning,
            color: isSuccess ? Colors.green : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSuccess ? 'Operation Completed' : 'Operation Completed with Issues',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary section
            _buildSummarySection(context),
            
            if (hasErrors) ...[
              const SizedBox(height: 20),
              _buildErrorSection(context),
            ],
            
            // Operation details
            const SizedBox(height: 16),
            _buildDetailsSection(context),
          ],
        ),
      ),
      actions: [
        // Retry failed button
        if (result.failedItems > 0 && onRetryFailed != null)
          TextButton.icon(
            onPressed: onRetryFailed,
            icon: const Icon(Icons.refresh),
            label: Text('Retry Failed (${result.failedItems})'),
          ),
        
        // Undo button
        if (result.canUndo && onUndo != null)
          TextButton.icon(
            onPressed: onUndo,
            icon: const Icon(Icons.undo),
            label: const Text('Undo'),
          ),
        
        // Close button
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Success count
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text('Successful: ${result.successfulItems}'),
              ],
            ),
            const SizedBox(height: 4),
            
            // Failed count
            if (result.failedItems > 0)
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text('Failed: ${result.failedItems}'),
                ],
              ),
            
            const SizedBox(height: 8),
            
            // Total and percentage
            Text(
              'Total: ${result.totalItems} items',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            
            if (result.totalItems > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Success rate: ${((result.successfulItems / result.totalItems) * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Errors (${result.errors.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Error list
            ...result.errors.take(5).map((error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: Colors.red[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
            
            // Show more errors indicator
            if (result.errors.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... and ${result.errors.length - 5} more errors',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final duration = result.endTime != null 
        ? result.endTime!.difference(result.startTime)
        : Duration.zero;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operation Details',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        _buildDetailRow(
          context,
          'Operation Type',
          _getOperationTypeDisplayName(result.type),
        ),
        
        _buildDetailRow(
          context,
          'Started',
          _formatDateTime(result.startTime),
        ),
        
        if (result.endTime != null)
          _buildDetailRow(
            context,
            'Completed',
            _formatDateTime(result.endTime!),
          ),
        
        if (duration.inSeconds > 0)
          _buildDetailRow(
            context,
            'Duration',
            _formatDuration(duration),
          ),
        
        _buildDetailRow(
          context,
          'Operation ID',
          result.operationId,
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  String _getOperationTypeDisplayName(BulkOperationType type) {
    switch (type) {
      case BulkOperationType.approval:
        return 'Bulk Approval';
      case BulkOperationType.rejection:
        return 'Bulk Rejection';
      case BulkOperationType.export:
        return 'Bulk Export';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

/// Shows a bulk operation result dialog
Future<void> showBulkOperationResultDialog({
  required BuildContext context,
  required BulkOperationResult result,
  VoidCallback? onRetryFailed,
  VoidCallback? onUndo,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => BulkOperationResultDialog(
      result: result,
      onRetryFailed: onRetryFailed,
      onUndo: onUndo,
    ),
  );
}