import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';
import 'package:odtrack_academia/providers/od_request_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.name.split(' ')[0]}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user.name.split(' ').map((n) => n[0]).take(2).join(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                child: const Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go(AppConstants.loginRoute);
                },
              ),
            ],
          ),
        ],
      ),
      body: user.isStudent ? _buildStudentDashboard(context, ref) : _buildStaffDashboard(context, ref),
    );
  }

  Widget _buildStudentDashboard(BuildContext context, WidgetRef ref) {
    final odRequests = ref.watch(odRequestProvider);
    final pendingRequests = odRequests.where((r) => r.isPending).length;
    final approvedRequests = odRequests.where((r) => r.isApproved).length;
    final rejectedRequests = odRequests.where((r) => r.isRejected).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats([
            _StatCard(
              title: 'Pending',
              value: pendingRequests.toString(),
              icon: MdiIcons.clockOutline,
              color: Colors.orange,
            ),
            _StatCard(
              title: 'Approved',
              value: approvedRequests.toString(),
              icon: MdiIcons.checkCircleOutline,
              color: Colors.green,
            ),
            _StatCard(
              title: 'Rejected',
              value: rejectedRequests.toString(),
              icon: MdiIcons.closeCircleOutline,
              color: Colors.red,
            ),
          ]),
          const SizedBox(height: 24),
          _buildQuickActions(context, [
            _ActionCard(
              title: 'New OD Request',
              subtitle: 'Submit a new OD request',
              icon: MdiIcons.plus,
              color: Colors.blue,
              onTap: () => context.push(AppConstants.newOdRoute),
            ),
            _ActionCard(
              title: 'View Timetable',
              subtitle: 'Check your class schedule',
              icon: MdiIcons.timetable,
              color: Colors.purple,
              onTap: () => context.push(AppConstants.timetableRoute),
            ),
            _ActionCard(
              title: 'Staff Directory',
              subtitle: 'Browse faculty contacts',
              icon: MdiIcons.accountGroup,
              color: Colors.teal,
              onTap: () => context.push(AppConstants.staffDirectoryRoute),
            ),
          ]),
          const SizedBox(height: 24),
          _buildRecentRequests(context, odRequests.take(3).toList()),
        ],
      ),
    );
  }

  Widget _buildStaffDashboard(BuildContext context, WidgetRef ref) {
    final odRequests = ref.watch(odRequestProvider);
    final pendingRequests = odRequests.where((r) => r.isPending).length;
    final totalRequests = odRequests.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats([
            _StatCard(
              title: 'Pending Review',
              value: pendingRequests.toString(),
              icon: MdiIcons.clockOutline,
              color: Colors.orange,
            ),
            _StatCard(
              title: 'Total Requests',
              value: totalRequests.toString(),
              icon: MdiIcons.fileDocumentOutline,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Today',
              value: '0',
              icon: MdiIcons.calendarToday,
              color: Colors.green,
            ),
          ]),
          const SizedBox(height: 24),
          _buildQuickActions(context, [
            _ActionCard(
              title: 'OD Inbox',
              subtitle: 'Review pending requests',
              icon: MdiIcons.inbox,
              color: Colors.blue,
              onTap: () => context.push(AppConstants.staffInboxRoute),
            ),
            _ActionCard(
              title: 'My Schedule',
              subtitle: 'View your timetable',
              icon: MdiIcons.timetable,
              color: Colors.purple,
              onTap: () => context.push(AppConstants.timetableRoute),
            ),
            _ActionCard(
              title: 'Staff Directory',
              subtitle: 'Browse colleague contacts',
              icon: MdiIcons.accountGroup,
              color: Colors.teal,
              onTap: () => context.push(AppConstants.staffDirectoryRoute),
            ),
          ]),
          const SizedBox(height: 24),
          _buildRecentRequests(context, odRequests.where((r) => r.isPending).take(3).toList()),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List<_StatCard> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: stats.map((stat) => Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(stat.icon, color: stat.color, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        stat.value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        stat.title,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, List<_ActionCard> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...actions.map((action) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: action.color.withValues(alpha: 0.1),
              child: Icon(action.icon, color: action.color),
            ),
            title: Text(action.title),
            subtitle: Text(action.subtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: action.onTap,
          ),
        )),
      ],
    );
  }

  Widget _buildRecentRequests(BuildContext context, List<dynamic> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Requests',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (requests.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No recent requests'),
              ),
            ),
          )
        else
          ...requests.map((request) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(request.status as String).withValues(alpha: 0.1),
                child: Icon(
                  _getStatusIcon(request.status as String),
                  color: _getStatusColor(request.status as String),
                ),
              ),
              title: Text('${(request.date as DateTime).day}/${(request.date as DateTime).month}/${(request.date as DateTime).year}'),
              subtitle: Text(request.reason as String),
              trailing: Chip(
                label: Text(
                  (request.status as String).toUpperCase(),
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: _getStatusColor(request.status as String).withValues(alpha: 0.1),
              ),
            ),
          )),
      ],
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
        return MdiIcons.fileDocumentOutline;
    }
  }
}

class _StatCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _ActionCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}