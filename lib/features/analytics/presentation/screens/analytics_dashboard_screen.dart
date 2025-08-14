import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/providers/analytics_provider.dart';
import 'package:odtrack_academia/providers/export_provider.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/charts/bar_chart_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/charts/line_chart_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/charts/pie_chart_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/filters/analytics_filter_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/services/chart_data_service.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/export_dialog_widget.dart';

/// Analytics dashboard screen displaying various charts and analytics
class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AnalyticsFilter _currentFilter = const AnalyticsFilter();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeAnalytics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).initialize();
      _loadAnalyticsData();
    });
  }

  void _loadAnalyticsData() {
    final dateRange = _currentFilter.dateRange ?? DateRange(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
    
    ref.read(analyticsProvider.notifier).loadODRequestAnalytics(dateRange);
    ref.read(analyticsProvider.notifier).loadTrendAnalysis(AnalyticsType.requests);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Toggle Filters',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportDialog,
            tooltip: 'Export Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAnalytics,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
            Tab(text: 'Departments', icon: Icon(Icons.business)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFiltersSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrendsTab(),
                _buildDepartmentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return AnalyticsFilterWidget(
      initialFilter: _currentFilter,
      onFilterChanged: _onFilterChanged,
      availableDepartments: const [
        'Computer Science',
        'Electronics',
        'Mechanical',
        'Civil',
        'Chemical',
      ],
      availableYears: const [
        '2023-24',
        '2024-25',
        '2025-26',
      ],
    );
  }

  Widget _buildOverviewTab() {
    final analyticsState = ref.watch(analyticsProvider);
    
    if (analyticsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (analyticsState.error != null) {
      return _buildErrorWidget(analyticsState.error!);
    }

    final analyticsData = analyticsState.analyticsData;
    if (analyticsData == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildSummaryCards(analyticsData),
          const SizedBox(height: 16),
          _buildStatusDistributionChart(analyticsData),
          const SizedBox(height: 16),
          _buildMonthlyRequestsChart(analyticsData),
          const SizedBox(height: 16),
          _buildRejectionReasonsChart(analyticsData),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final trendData = ref.watch(trendDataProvider(AnalyticsType.requests));
    
    if (trendData == null || trendData.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildTrendChart(trendData.first),
          const SizedBox(height: 16),
          _buildTrendSummary(trendData),
        ],
      ),
    );
  }

  Widget _buildDepartmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildDepartmentComparisonChart(),
          const SizedBox(height: 16),
          _buildDepartmentList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AnalyticsData analyticsData) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Requests',
            analyticsData.totalRequests.toString(),
            Icons.assignment,
            Colors.blue,
          ),
        ),
        Expanded(
          child: _buildSummaryCard(
            'Approval Rate',
            '${analyticsData.approvalRate.toStringAsFixed(1)}%',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        Expanded(
          child: _buildSummaryCard(
            'Pending',
            analyticsData.pendingRequests.toString(),
            Icons.pending,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistributionChart(AnalyticsData analyticsData) {
    final chartData = ChartDataService.prepareBarChartData(
      analyticsData,
      ChartType.bar,
    );

    return AnalyticsPieChart(
      data: chartData,
      title: 'Request Status Distribution',
      showPercentages: true,
      onRefresh: _refreshAnalytics,
    );
  }

  Widget _buildMonthlyRequestsChart(AnalyticsData analyticsData) {
    final chartData = ChartDataService.prepareMonthlyChartData(
      analyticsData.requestsByMonth,
      ChartType.bar,
    );

    return AnalyticsBarChart(
      data: chartData,
      title: 'Monthly Request Volume',
      onRefresh: _refreshAnalytics,
    );
  }

  Widget _buildRejectionReasonsChart(AnalyticsData analyticsData) {
    final chartData = ChartDataService.prepareRejectionReasonsChartData(
      analyticsData.topRejectionReasons,
      ChartType.pie,
    );

    final limitedData = ChartDataService.limitChartData(chartData, 6);

    return AnalyticsPieChart(
      data: limitedData,
      title: 'Top Rejection Reasons',
      showPercentages: true,
      showLegendBelowChart: true,
      onRefresh: _refreshAnalytics,
    );
  }

  Widget _buildTrendChart(TrendData trendData) {
    final chartData = ChartDataService.prepareTrendChartData([trendData], ChartType.line);

    return AnalyticsLineChart(
      data: chartData,
      title: 'Request Trends Over Time',
      showDots: true,
      showArea: true,
      onRefresh: _refreshAnalytics,
    );
  }

  Widget _buildTrendSummary(List<TrendData> trendData) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...trendData.map((trend) => _buildTrendItem(trend)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(TrendData trend) {
    final isPositive = trend.direction == TrendDirection.up;
    final isNegative = trend.direction == TrendDirection.down;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : 
            isNegative ? Icons.trending_down : Icons.trending_flat,
            color: isPositive ? Colors.green : 
                   isNegative ? Colors.red : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(trend.label),
          ),
          Text(
            '${isPositive ? '+' : isNegative ? '-' : ''}${trend.changePercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isPositive ? Colors.green : 
                     isNegative ? Colors.red : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentComparisonChart() {
    // This would be populated with actual department data
    final mockData = [
      const ChartData(label: 'CS', value: 45),
      const ChartData(label: 'ECE', value: 38),
      const ChartData(label: 'ME', value: 32),
      const ChartData(label: 'CE', value: 28),
      const ChartData(label: 'CH', value: 22),
    ];

    return AnalyticsBarChart(
      data: mockData,
      title: 'Requests by Department',
      onRefresh: _refreshAnalytics,
    );
  }

  Widget _buildDepartmentList() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Department Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDepartmentListItem('Computer Science', 45, 85.5),
            _buildDepartmentListItem('Electronics', 38, 78.9),
            _buildDepartmentListItem('Mechanical', 32, 81.2),
            _buildDepartmentListItem('Civil', 28, 75.0),
            _buildDepartmentListItem('Chemical', 22, 90.9),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentListItem(String name, int requests, double approvalRate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(name),
          ),
          Expanded(
            child: Text('$requests requests'),
          ),
          Expanded(
            child: Text(
              '${approvalRate.toStringAsFixed(1)}%',
              style: TextStyle(
                color: approvalRate >= 80 ? Colors.green : 
                       approvalRate >= 60 ? Colors.orange : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshAnalytics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No analytics data available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or check back later',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshAnalytics,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _onFilterChanged(AnalyticsFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
    _loadAnalyticsData();
  }

  void _refreshAnalytics() {
    ref.read(analyticsProvider.notifier).refreshAnalyticsCache();
    _loadAnalyticsData();
  }

  void _showExportDialog() {
    final analyticsData = ref.read(analyticsProvider).analyticsData;
    if (analyticsData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No analytics data available to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => ExportDialogWidget(
        title: 'Export Analytics Report',
        onExport: (format, options) => _exportAnalytics(format, options),
        availableFormats: const [ExportFormat.pdf, ExportFormat.csv],
      ),
    );
  }

  Future<void> _exportAnalytics(ExportFormat format, ExportOptions options) async {
    final analyticsData = ref.read(analyticsProvider).analyticsData;
    if (analyticsData == null) return;

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Exporting analytics report...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final result = await ref.read(exportProvider.notifier).exportAnalyticsReport(
        analyticsData,
        options,
      );

      if (mounted && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analytics report exported successfully: ${result.fileName}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => ref.read(exportProvider.notifier).openExportedFile(result.filePath),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${result.errorMessage ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}