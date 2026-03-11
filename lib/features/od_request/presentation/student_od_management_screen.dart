import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';
import 'package:odtrack_academia/providers/od_request_provider.dart';
import 'package:odtrack_academia/providers/staff_provider.dart';
import 'package:odtrack_academia/models/staff_member.dart';

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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'My OD Requests', 
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colorScheme.outlineVariant.withValues(alpha: 0.1), height: 1),
        ),
      ),
      body: studentRequests.isEmpty
          ? _buildEmptyState(context)
          : _buildRequestList(studentRequests),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            MdiIcons.clipboardText,
            size: 80,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No OD Requests Found',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'You haven\'t submitted any OD requests yet. Start by creating your first request.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push(AppConstants.newOdRoute),
            child: const Text('Create Request'),
          ),
        ],
      ),
    );
  }


  Widget _buildRequestList(List<ODRequest> requests) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(odRequestProvider.notifier).fetchRequests(),
          ref.read(staffProvider.notifier).fetchStaff(),
        ]);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color statusColor = _getStatusColor(request.status);
    IconData statusIcon = _getStatusIcon(request.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), 
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(16),
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
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
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
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
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Assigned',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.reason,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                ),
              ),
              if (request.rejectionReason != null && request.status == 'rejected')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        MdiIcons.alertCircleOutline,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Rejection Reason: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          request.rejectionReason!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[400], // Brighter red for visibility on black
                          ),
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
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  if (request.approvedAt != null && request.status == 'approved')
                    Text(
                      'Approved: ${_formatDateTime(request.approvedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStaffName(String? staffId, List<StaffMember> staffList) {
    if (staffId == null) return 'Not Assigned';
    final staff = staffList.where((s) => s.id == staffId).firstOrNull;
    return staff?.name ?? 'Unknown Staff';
  }

  void _showRequestDetails(ODRequest request) {
    if (request.status == 'pending') {
      _showEditDialog(request);
    } else {
      _showReadOnlyDetails(request);
    }
  }

  void _showReadOnlyDetails(ODRequest request) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black, // OLED Black
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'OD Request Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  _buildStatusBadge(request.status),
                ],
              ),
              const SizedBox(height: 24),
              _detailRow(Icons.calendar_today, 'Date', 
                '${request.date.day}/${request.date.month}/${request.date.year}'),
              _detailRow(Icons.timer_outlined, 'Periods', _formatPeriods(request.periods)),
               _detailRow(Icons.person_outline, 'Designated Staff', 
                _getStaffName(request.staffId, ref.read(staffProvider).maybeWhen(
                  data: (list) => list,
                  orElse: () => [],
                ))),
              const Divider(height: 32, color: Colors.white10),
              const Text(
                'Reason',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                request.reason,
                style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
              ),
              if (request.rejectionReason != null && request.status == 'rejected') ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rejection Reason',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.rejectionReason!,
                        style: TextStyle(color: Colors.red[200]),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(ODRequest request) {
    final reasonController = TextEditingController(text: request.reason);
    String? selectedStaffId = request.staffId;
    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black, // OLED Black
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              color: Colors.black, // Darken background
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.only(
                  left: 24, 
                  right: 24, 
                  top: 24, 
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Edit OD Request',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // OLED White
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Update the details of your pending request.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                  
                  // Date and Periods (Read-only for now as per plan, but shown)
                  Row(
                    children: [
                      Expanded(child: _detailRow(Icons.calendar_today, 'Date', 
                        '${request.date.day}/${request.date.month}/${request.date.year}')),
                      Expanded(child: _detailRow(Icons.timer_outlined, 'Periods', 
                        _formatPeriods(request.periods))),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Staff Selection Dropdown
                  const Text(
                    'Assigned Authority',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final theme = Theme.of(context);
                          
                      final staffAsync = ref.watch(staffProvider);
                      return staffAsync.when(
                        data: (staffList) {
                          final selectedStaff = staffList.where(
                            (s) => s.id == selectedStaffId,
                          ).firstOrNull ?? staffList.first;
                          
                          return InkWell(
                            onTap: () => _showStaffPicker(
                              context, 
                              staffList, 
                              selectedStaffId, 
                              (val) {
                                setModalState(() => selectedStaffId = val);
                              }
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person_search_outlined, color: theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Authority / Staff Member',
                                          style: TextStyle(
                                            fontSize: 12, 
                                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)
                                          ),
                                        ),
                                        Text(
                                          selectedStaffId != null ? selectedStaff.name : 'Select Staff Authority',
                                          style: const TextStyle(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                                ],
                              ),
                            ),
                          );
                        },
                        loading: () => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary)
                            ),
                          ),
                        ),
                        error: (e, _) => InkWell(
                          onTap: () => ref.refresh(staffProvider),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Text('Failed to load staff. Tap to retry.', style: TextStyle(color: Colors.red, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Reason Textfield
                  const Text(
                    'Reason for OD',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter valid reason...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            setModalState(() => isSaving = true);
                            try {
                              await ref.read(odRequestProvider.notifier).editRequest(
                                request.id,
                                {
                                  'reason': reasonController.text.trim(),
                                  if (selectedStaffId != null) 'staff_id': selectedStaffId,
                                },
                              );
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error updating: $e')),
                                );
                              }
                            }
                          },
                          child: isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                            : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
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

  void _showStaffPicker(
    BuildContext context, 
    List<StaffMember> staffList, 
    String? currentId, 
    void Function(String) onSelected
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
      isScrollControlled: true,
      shape: theme.bottomSheetTheme.shape,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Container(
            color: theme.bottomSheetTheme.backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Staff Authority',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.1)),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: staffList.length,
                    itemBuilder: (context, index) {
                      final staff = staffList[index];
                      final isSelected = staff.id == currentId;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          child: Text(
                            staff.name.isNotEmpty ? staff.name[0] : 'S',
                            style: TextStyle(
                              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          staff.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          staff.department,
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
                        ),
                        trailing: isSelected 
                          ? Icon(Icons.check_circle, color: colorScheme.primary)
                          : null,
                        onTap: () {
                          onSelected(staff.id);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}