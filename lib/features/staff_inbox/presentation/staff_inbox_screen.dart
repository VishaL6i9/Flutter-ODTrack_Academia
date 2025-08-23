import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/providers/od_request_provider.dart';
import 'package:odtrack_academia/providers/bulk_operation_provider.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/bulk_operation_models.dart';

class StaffInboxScreen extends ConsumerStatefulWidget {
  const StaffInboxScreen({super.key});

  @override
  ConsumerState<StaffInboxScreen> createState() => _StaffInboxScreenState();
}

class _StaffInboxScreenState extends ConsumerState<StaffInboxScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final allRequests = ref.watch(odRequestProvider);
    final bulkOperationState = ref.watch(bulkOperationProvider);
    final filteredRequests = _getFilteredRequests(allRequests);

    return Scaffold(
      appBar: _buildAppBar(context, bulkOperationState),
      body: Column(
        children: [
          if (!bulkOperationState.isSelectionMode) _buildFilterTabs(),
          if (!bulkOperationState.isSelectionMode) _buildStats(allRequests),
          if (bulkOperationState.isSelectionMode) _buildSelectionHeader(bulkOperationState, filteredRequests),
          Expanded(
            child: _buildRequestsList(filteredRequests, bulkOperationState),
          ),
          if (bulkOperationState.isSelectionMode && bulkOperationState.hasSelection)
            _buildBulkActionBar(context, bulkOperationState),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, BulkOperationState bulkState) {
    if (bulkState.isSelectionMode) {
      return AppBar(
        title: Text('${bulkState.selectionCount} selected'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(bulkOperationProvider.notifier).toggleSelectionMode();
          },
        ),
        actions: [
          if (bulkState.selectionCount > 0)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                ref.read(bulkOperationProvider.notifier).clearSelection();
              },
              tooltip: 'Clear selection',
            ),
        ],
      );
    }

    return AppBar(
      title: const Text('OD Inbox'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        IconButton(
          icon: const Icon(Icons.checklist),
          onPressed: () {
            ref.read(bulkOperationProvider.notifier).toggleSelectionMode();
          },
          tooltip: 'Multi-select mode',
        ),
      ],
    );
  }

  Widget _buildSelectionHeader(BulkOperationState bulkState, List<ODRequest> requests) {
    final pendingRequests = requests.where((r) => r.isPending).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${bulkState.selectionCount} of ${requests.length} requests selected',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton.icon(
            onPressed: pendingRequests.isEmpty ? null : () {
              ref.read(bulkOperationProvider.notifier).selectAll(
                pendingRequests.map((r) => r.id).toList(),
              );
            },
            icon: const Icon(Icons.select_all),
            label: const Text('Select All'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar(BuildContext context, BulkOperationState bulkState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: bulkState.currentProgress != null ? null : () {
                _showBulkRejectionDialog(context, bulkState.selectionCount);
              },
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Reject All', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: bulkState.currentProgress != null ? null : () {
                _showBulkApprovalDialog(context, bulkState.selectionCount);
              },
              icon: const Icon(Icons.check),
              label: const Text('Approve All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: bulkState.currentProgress != null ? null : () {
              _showBulkExportDialog(context, bulkState.selectionCount);
            },
            icon: const Icon(Icons.download),
            tooltip: 'Export selected',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  filter,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStats(List<ODRequest> requests) {
    final pending = requests.where((r) => r.isPending).length;
    final approved = requests.where((r) => r.isApproved).length;
    final rejected = requests.where((r) => r.isRejected).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard('Pending', pending, Colors.orange),
          _buildStatCard('Approved', approved, Colors.green),
          _buildStatCard('Rejected', rejected, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<ODRequest> requests, BulkOperationState bulkState) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MdiIcons.inboxOutline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_selectedFilter.toLowerCase()} requests',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(request, bulkState);
      },
    );
  }

  Widget _buildRequestCard(ODRequest request, BulkOperationState bulkState) {
    final isSelected = bulkState.isSelectionMode && 
                      ref.read(bulkOperationProvider.notifier).isRequestSelected(request.id);
    final canSelect = bulkState.isSelectionMode && request.isPending;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: bulkState.isSelectionMode && canSelect ? () {
          ref.read(bulkOperationProvider.notifier).toggleRequestSelection(request.id);
        } : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (bulkState.isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: canSelect ? (value) {
                        ref.read(bulkOperationProvider.notifier).toggleRequestSelection(request.id);
                      } : null,
                    ),
                    const SizedBox(width: 8),
                  ],
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      request.studentName.split(' ').map((n) => n[0]).take(2).join(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.studentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Reg: ${request.registerNumber}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(request.status),
                ],
              ),
            const SizedBox(height: 12),
            _buildInfoRow(MdiIcons.calendar, 'Date', 
                '${request.date.day}/${request.date.month}/${request.date.year}'),
            _buildInfoRow(MdiIcons.clockOutline, 'Periods', 
                request.periods.map((p) => 'P$p').join(', ')),
            _buildInfoRow(MdiIcons.textBox, 'Reason', request.reason),
            _buildInfoRow(MdiIcons.clockOutline, 'Submitted', 
                _formatDateTime(request.createdAt)),
            
              if (request.isPending && !bulkState.isSelectionMode) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleReject(request),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleApprove(request),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<ODRequest> _getFilteredRequests(List<ODRequest> requests) {
    switch (_selectedFilter) {
      case 'Pending':
        return requests.where((r) => r.isPending).toList();
      case 'Approved':
        return requests.where((r) => r.isApproved).toList();
      case 'Rejected':
        return requests.where((r) => r.isRejected).toList();
      default:
        return requests;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleApprove(ODRequest request) {
    _showApprovalDialog(request);
  }

  void _handleReject(ODRequest request) {
    _showRejectionDialog(request);
  }

  void _showApprovalDialog(ODRequest request) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approve OD Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: ${request.studentName}'),
              Text('Register: ${request.registerNumber}'),
              Text('Date: ${request.date.day}/${request.date.month}/${request.date.year}'),
              Text('Periods: ${request.periods.map((p) => 'P$p').join(', ')}'),
              const SizedBox(height: 16),
              const Text('Are you sure you want to approve this request?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processApproval(request);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  void _showRejectionDialog(ODRequest request) {
    final reasonController = TextEditingController();
    
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject OD Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: ${request.studentName}'),
              Text('Register: ${request.registerNumber}'),
              const SizedBox(height: 16),
              const Text('Reason for rejection:'),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter reason for rejection...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _processRejection(request, reasonController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  void _processApproval(ODRequest request) {
    // Update request status
    ref.read(odRequestProvider.notifier).updateRequestStatus(request.id, 'approved');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Request by ${request.studentName} approved'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _processRejection(ODRequest request, String reason) {
    // Update request status with rejection reason
    ref.read(odRequestProvider.notifier).updateRequestStatus(request.id, 'rejected', reason: reason);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.white),
            const SizedBox(width: 8),
            Text('Request by ${request.studentName} rejected'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showBulkApprovalDialog(BuildContext context, int count) {
    final reasonController = TextEditingController();
    
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Approve $count Requests'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You are about to approve $count OD requests.'),
              const SizedBox(height: 16),
              const Text('Approval reason (optional):'),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Enter approval reason...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processBulkApproval(reasonController.text.trim().isEmpty 
                    ? 'Bulk approval' 
                    : reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve All'),
            ),
          ],
        );
      },
    );
  }

  void _showBulkRejectionDialog(BuildContext context, int count) {
    final reasonController = TextEditingController();
    
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reject $count Requests'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You are about to reject $count OD requests.'),
              const SizedBox(height: 16),
              const Text('Rejection reason (required):'),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter reason for rejection...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _processBulkRejection(reasonController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject All'),
            ),
          ],
        );
      },
    );
  }

  void _showBulkExportDialog(BuildContext context, int count) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Export $count Requests'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose export format for $count selected requests:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF Report'),
                onTap: () {
                  Navigator.of(context).pop();
                  _processBulkExport(ExportFormat.pdf);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('CSV Spreadsheet'),
                onTap: () {
                  Navigator.of(context).pop();
                  _processBulkExport(ExportFormat.csv);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processBulkApproval(String reason) async {
    try {
      await ref.read(bulkOperationProvider.notifier).performBulkApproval(reason);
      
      final result = ref.read(bulkOperationProvider).lastResult;
      if (result != null) {
        _showBulkOperationResult(result);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to perform bulk approval: $e');
    }
  }

  Future<void> _processBulkRejection(String reason) async {
    try {
      await ref.read(bulkOperationProvider.notifier).performBulkRejection(reason);
      
      final result = ref.read(bulkOperationProvider).lastResult;
      if (result != null) {
        _showBulkOperationResult(result);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to perform bulk rejection: $e');
    }
  }

  Future<void> _processBulkExport(ExportFormat format) async {
    try {
      await ref.read(bulkOperationProvider.notifier).performBulkExport(format);
      
      final result = ref.read(bulkOperationProvider).lastResult;
      if (result != null) {
        _showBulkOperationResult(result);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to perform bulk export: $e');
    }
  }

  void _showBulkOperationResult(BulkOperationResult result) {
    final isSuccess = result.failedItems == 0;
    final message = isSuccess
        ? 'Successfully processed ${result.successfulItems} requests'
        : 'Processed ${result.successfulItems} requests, ${result.failedItems} failed';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.warning,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
            if (result.canUndo)
              TextButton(
                onPressed: () {
                  ref.read(bulkOperationProvider.notifier).undoLastOperation();
                },
                child: const Text('UNDO', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
