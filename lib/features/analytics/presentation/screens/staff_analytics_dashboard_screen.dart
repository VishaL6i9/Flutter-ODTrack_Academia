import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/core/theme/app_theme.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/providers/staff_analytics_provider.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/staff_analytics/workload_analytics_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/staff_analytics/teaching_analytics_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/staff_analytics/time_allocation_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/staff_analytics/efficiency_metrics_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/staff_analytics/comparative_analytics_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/staff_analytics/staff_analytics_filter_widget.dart';
import 'package:odtrack_academia/shared/widgets/loading_widget.dart';

/// Enumeration for analytics tabs
enum StaffAnalyticsTab {
  workload,
  teaching,
  timeAllocation,
  efficiency,
  comparative,
}

/// Staff Analytics Dashboard Screen
class StaffAnalyticsDashboardScreen extends ConsumerStatefulWidget {
  final String? staffId;

  const StaffAnalyticsDashboardScreen({
    super.key,
    this.staffId,
  });

  @override
  ConsumerState<StaffAnalyticsDashboardScreen> createState() => _StaffAnalyticsDashboardScreenState();
}

class _StaffAnalyticsDashboardScreenState extends ConsumerState<StaffAnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late String _currentStaffId;
  DateRange _currentDateRange = DateRange(
    startDate: DateTime.now().subtract(const Duration(days: 180)), // Last 6 months
    endDate: DateTime.now(),
  );
  String _currentSemester = 'current';

  final List<StaffAnalyticsTab> _tabs = const [
    StaffAnalyticsTab.workload,
    StaffAnalyticsTab.teaching,
    StaffAnalyticsTab.timeAllocation,
    StaffAnalyticsTab.efficiency,
    StaffAnalyticsTab.comparative,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // Use provided staffId or get from auth provider
    _currentStaffId = widget.staffId ?? '';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeAnalytics() async {
    final authState = ref.read(authProvider);
    final analyticsService = ref.read(staffAnalyticsServiceProvider);
    
    // Prioritize passed staffId, otherwise use the logged-in user's ID.
    String? staffIdToLoad = widget.staffId;
    if (staffIdToLoad == null && authState.user != null) {
      staffIdToLoad = authState.user!.id;
    }

    // If still no staffId, try to get the first available staff member from the service.
    if (staffIdToLoad == null || staffIdToLoad.isEmpty) {
      staffIdToLoad = await analyticsService.getFirstStaffId();
    }
    
    // If we have a valid staff ID, load the analytics data.
    if (staffIdToLoad != null && staffIdToLoad.isNotEmpty) {
      setState(() {
        _currentStaffId = staffIdToLoad!;
      });
      await ref.read(staffAnalyticsProvider.notifier).initialize();
      await _loadAnalyticsData();
    }
    // If no staffId is available, the screen will show an empty/loading state.
  }

  Future<void> _loadAnalyticsData() async {
    await ref.read(staffAnalyticsProvider.notifier).loadStaffAnalytics(
      _currentStaffId,
      _currentDateRange,
      _currentSemester,
    );
  }

  Future<void> _refreshAnalytics() async {
    await ref.read(staffAnalyticsProvider.notifier).refreshAnalytics();
  }

  void _onDateRangeChanged(DateRange newDateRange) {
    setState(() {
      _currentDateRange = newDateRange;
    });
    _loadAnalyticsData();
  }

  void _onSemesterChanged(String newSemester) {
    setState(() {
      _currentSemester = newSemester;
    });
    _loadAnalyticsData();
  }

  String _getTabTitle(StaffAnalyticsTab tab) {
    switch (tab) {
      case StaffAnalyticsTab.workload:
        return 'Workload';
      case StaffAnalyticsTab.teaching:
        return 'Teaching';
      case StaffAnalyticsTab.timeAllocation:
        return 'Time Allocation';
      case StaffAnalyticsTab.efficiency:
        return 'Efficiency';
      case StaffAnalyticsTab.comparative:
        return 'Comparative';
    }
  }

  IconData _getTabIcon(StaffAnalyticsTab tab) {
    switch (tab) {
      case StaffAnalyticsTab.workload:
        return Icons.work_outline;
      case StaffAnalyticsTab.teaching:
        return Icons.school_outlined;
      case StaffAnalyticsTab.timeAllocation:
        return Icons.schedule_outlined;
      case StaffAnalyticsTab.efficiency:
        return Icons.trending_up_outlined;
      case StaffAnalyticsTab.comparative:
        return Icons.compare_arrows_outlined;
    }
  }

  Widget _buildTabContent(StaffAnalyticsTab tab) {
    switch (tab) {
      case StaffAnalyticsTab.workload:
        return WorkloadAnalyticsWidget(
          staffId: _currentStaffId,
          dateRange: _currentDateRange,
        );
      case StaffAnalyticsTab.teaching:
        return TeachingAnalyticsWidget(
          staffId: _currentStaffId,
          semester: _currentSemester,
        );
      case StaffAnalyticsTab.timeAllocation:
        return TimeAllocationWidget(
          staffId: _currentStaffId,
          dateRange: _currentDateRange,
        );
      case StaffAnalyticsTab.efficiency:
        return EfficiencyMetricsWidget(
          staffId: _currentStaffId,
          dateRange: _currentDateRange,
        );
      case StaffAnalyticsTab.comparative:
        return ComparativeAnalyticsWidget(
          staffId: _currentStaffId,
          semesters: const ['current', 'previous', 'previous-2'],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAnalyticsState = ref.watch(staffAnalyticsProvider);
    final isLoading = ref.watch(staffAnalyticsLoadingProvider);
    final error = ref.watch(staffAnalyticsErrorProvider);

    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Staff Analytics Dashboard'),
          elevation: 0,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: isLoading ? null : _refreshAnalytics,
              tooltip: 'Refresh Analytics',
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
              tooltip: 'Filter Options',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: _tabs.map((tab) => Tab(
              icon: Icon(_getTabIcon(tab)),
              text: _getTabTitle(tab),
            )).toList(),
          ),
        ),
        body: Column(
          children: [
            // Analytics Summary Header
            if (staffAnalyticsState.workloadAnalytics != null)
              _buildAnalyticsSummaryHeader(staffAnalyticsState.workloadAnalytics!),
            
            // Error Display
            if (error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.read(staffAnalyticsProvider.notifier).clearError(),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
            
            // Tab Content
            Expanded(
              child: isLoading
                  ? const LoadingWidget(message: 'Loading analytics data...')
                  : TabBarView(
                      controller: _tabController,
                      children: _tabs.map((tab) => _buildTabContent(tab)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummaryHeader(WorkloadAnalytics workloadAnalytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Hours',
              '${workloadAnalytics.totalWorkingHours.toStringAsFixed(1)}h',
              Icons.access_time,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Weekly Average',
              '${workloadAnalytics.weeklyAverageHours.toStringAsFixed(1)}h',
              Icons.calendar_view_week,
              AppTheme.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Trend',
              workloadAnalytics.trend.toString().split('.').last.toUpperCase(),
              _getTrendIcon(workloadAnalytics.trend),
              _getTrendColor(workloadAnalytics.trend),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Alerts',
              '${workloadAnalytics.alerts.length}',
              Icons.warning_outlined,
              workloadAnalytics.alerts.isNotEmpty ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getTrendIcon(WorkloadTrend trend) {
    switch (trend) {
      case WorkloadTrend.increasing:
        return Icons.trending_up;
      case WorkloadTrend.decreasing:
        return Icons.trending_down;
      case WorkloadTrend.stable:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(WorkloadTrend trend) {
    switch (trend) {
      case WorkloadTrend.increasing:
        return Colors.orange;
      case WorkloadTrend.decreasing:
        return Colors.red;
      case WorkloadTrend.stable:
        return Colors.green;
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => StaffAnalyticsFilterWidget(
        currentDateRange: _currentDateRange,
        currentSemester: _currentSemester,
        onDateRangeChanged: _onDateRangeChanged,
        onSemesterChanged: _onSemesterChanged,
      ),
    );
  }
}
