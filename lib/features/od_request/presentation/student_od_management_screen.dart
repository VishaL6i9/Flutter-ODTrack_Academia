import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';
import 'package:odtrack_academia/providers/od_request_provider.dart';

class StudentOdManagementScreen extends ConsumerStatefulWidget {
  const StudentOdManagementScreen({super.key});

  @override
  ConsumerState<StudentOdManagementScreen> createState() => _StudentOdManagementScreenState();
}

class _StudentOdManagementScreenState extends ConsumerState<StudentOdManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final allRequests = ref.watch(odRequestProvider);

    // Filter requests for current student
    final studentRequests = allRequests
        .where((request) => request.studentId == user.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by latest first

    return Scaffold(
      appBar: AppBar(
        title: const Text('My OD Requests'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: studentRequests.isEmpty
          ? _buildEmptyState(context)
          : _buildRequestList(studentRequests),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            MdiIcons.clipboardText,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No OD Requests Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'You haven\'t submitted any OD requests yet. Start by creating your first request.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Create Request'),
          ),
        ],
      ),
    );
  }


  Widget _buildRequestList(List<ODRequest> requests) {
    return RefreshIndicator(
      onRefresh: () async {
        // In a real app, this would fetch latest data from the API
        // For now, we just wait to simulate a refresh
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(ODRequest request) {
    Color statusColor = _getStatusColor(request.status);
    IconData statusIcon = _getStatusIcon(request.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(request.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${request.date.day}/${request.date.month}/${request.date.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Periods: ${_formatPeriods(request.periods)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                if (request.staffId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Assigned',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.reason,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (request.rejectionReason != null && request.status == 'rejected')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      MdiIcons.alertCircleOutline,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Rejection Reason: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      request.rejectionReason!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Submitted: ${_formatDateTime(request.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (request.approvedAt != null && request.status == 'approved')
                  Text(
                    'Approved: ${_formatDateTime(request.approvedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return MdiIcons.clockOutline;
      case 'approved':
        return MdiIcons.checkCircleOutline;
      case 'rejected':
        return MdiIcons.closeCircleOutline;
      default:
        return MdiIcons.helpCircleOutline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status.toUpperCase();
    }
  }

  String _formatPeriods(List<int> periods) {
    if (periods.isEmpty) return 'No periods';
    
    if (periods.length == 1) {
      return 'Period ${periods.first}';
    }
    
    // Check if periods are consecutive
    List<String> periodStrings = [];
    for (int period in periods) {
      periodStrings.add(period.toString());
    }
    
    return periodStrings.join(', ');
  }

  String _formatDateTime(DateTime dateTime) {
    // Format as "Today at HH:MM" or "DD/MM/YYYY at HH:MM"
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      return 'Today at ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}