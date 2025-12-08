import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';
import 'package:odtrack_academia/features/timetable/presentation/staff_timetable_screen.dart';
import 'package:odtrack_academia/features/staff_profile/presentation/staff_profile_screen.dart';
import 'package:odtrack_academia/providers/od_request_provider.dart';
import 'package:odtrack_academia/shared/widgets/loading_widget.dart';
import 'package:odtrack_academia/shared/widgets/animated_widgets.dart';
import 'package:odtrack_academia/shared/widgets/custom_refresh_indicator.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Simulate loading time for better UX
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    // Refresh data
    await Future<void>.delayed(const Duration(seconds: 1));
    // Trigger provider refresh if needed
    ref.invalidate(odRequestProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Welcome, ${user.name.split(' ')[0]}'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const LoadingWidget.dashboard(),
      );
    }

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
              if (user.isStaff) ...[
                PopupMenuItem<String>(
                  child: const Row(
                    children: [
                      Icon(Icons.home),
                      SizedBox(width: 8),
                      Text('Home'),
                    ],
                  ),
                  onTap: () {
                    context.go(AppConstants.dashboardRoute);
                  },
                ),
                PopupMenuItem<String>(
                  child: const Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('My Profile'),
                    ],
                  ),
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const StaffProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
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
      body: CustomRefreshIndicator(
        onRefresh: _onRefresh,
        child: user.isStudent ? _buildStudentDashboard(context, ref) : _buildStaffDashboard(context, ref),
      ),
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
          AnimatedListItem(
            index: 0,
            child: _buildQuickStats([
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
          ),
          const SizedBox(height: 24),

          AnimatedListItem(
            index: 1,
            child: _buildQuickActions(context, [
              _ActionCard(
                title: 'New OD Request',
                subtitle: 'Submit a new OD request',
                icon: MdiIcons.plus,
                color: Colors.blue,
                onTap: () => context.push(AppConstants.newOdRoute),
              ),
              _ActionCard(
                title: 'View Selected Timetable',
                subtitle: 'Check the schedule for selected year/section',
                icon: MdiIcons.timetable,
                color: Colors.purple,
                onTap: () {
                  context.push(AppConstants.timetableRoute);
                },
              ),
              _ActionCard(
                title: 'Staff Directory',
                subtitle: 'Browse faculty contacts',
                icon: MdiIcons.accountGroup,
                color: Colors.teal,
                onTap: () => context.push(AppConstants.staffDirectoryRoute),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          AnimatedListItem(
            index: 2,
            child: _buildRecentRequests(context, odRequests.take(3).toList()),
          ),
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
          AnimatedListItem(
            index: 0,
            child: _buildQuickStats([
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
          ),
          const SizedBox(height: 24),

          AnimatedListItem(
            index: 1,
            child: _buildQuickActions(context, [
              _ActionCard(
                title: 'OD Inbox',
                subtitle: 'Review pending requests',
                icon: MdiIcons.inbox,
                color: Colors.blue,
                onTap: () => context.push(AppConstants.staffInboxRoute),
              ),
              _ActionCard(
                title: 'My Timetable',
                subtitle: 'View your weekly schedule',
                icon: MdiIcons.calendarAccount,
                color: Colors.green,
                onTap: () {
                  final staffId = ref.read(authProvider).user?.id;
                  if (staffId != null) {
                    // It's better to have a dedicated route for this
                    // For now, we'll push the screen directly.
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => StaffTimetableScreen(staffId: staffId),
                      ),
                    );
                  }
                },
              ),
              _ActionCard(
                title: 'View Class Timetable',
                subtitle: 'Check the schedule for any class',
                icon: MdiIcons.timetable,
                color: Colors.purple,
                onTap: () {
                  context.push(AppConstants.timetableRoute);
                },
              ),
              _ActionCard(
                title: 'Staff Directory',
                subtitle: 'Browse colleague contacts',
                icon: MdiIcons.accountGroup,
                color: Colors.teal,
                onTap: () => context.push(AppConstants.staffDirectoryRoute),
              ),
              _ActionCard(
                title: 'Analytics Dashboard',
                subtitle: 'View comprehensive staff analytics',
                icon: MdiIcons.chartLine,
                color: Colors.indigo,
                onTap: () {
                  final staffId = ref.read(authProvider).user?.id;
                  if (staffId != null) {
                    context.push('${AppConstants.staffAnalyticsRoute}?staffId=$staffId');
                  }
                },
              ),
              _ActionCard(
                title: 'Export Reports',
                subtitle: 'Generate and download reports',
                icon: MdiIcons.fileDownloadOutline,
                color: Colors.brown,
                onTap: () => context.push(AppConstants.exportRoute),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          AnimatedListItem(
            index: 2,
            child: _buildRecentRequests(context, odRequests.where((r) => r.isPending).take(3).toList()),
          ),
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
                      AnimatedCounter(
                        value: int.tryParse(stat.value) ?? 0,
                        textStyle: const TextStyle(
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
        ...actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          return AnimatedListItem(
            index: index,
            delay: const Duration(milliseconds: 100),
            child: AnimatedButton(
              onPressed: action.onTap,
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: action.color.withValues(alpha: 0.1),
                    child: Icon(action.icon, color: action.color),
                  ),
                  title: Text(action.title),
                  subtitle: Text(action.subtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            ),
          );
        }),
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
