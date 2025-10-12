import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:odtrack_academia/core/theme/app_theme.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/providers/staff_analytics_provider.dart';
import 'package:odtrack_academia/shared/widgets/loading_widget.dart';
import 'package:odtrack_academia/shared/widgets/empty_state_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/utils/analytics_theme_utils.dart';

/// Widget for displaying workload analytics with interactive charts
class WorkloadAnalyticsWidget extends ConsumerWidget {
  final String staffId;
  final DateRange dateRange;

  const WorkloadAnalyticsWidget({
    super.key,
    required this.staffId,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workloadAnalytics = ref.watch(workloadAnalyticsProvider);
    final isLoading = ref.watch(staffAnalyticsLoadingProvider);

    if (isLoading) {
      return const LoadingWidget(message: 'Loading workload analytics...');
    }

    if (workloadAnalytics == null) {
      return const EmptyStateWidget(
        icon: Icons.work_outline,
        title: 'No Workload Data',
        message: 'No workload analytics data available for the selected period.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workload Overview Cards
          _buildWorkloadOverview(context, workloadAnalytics),
          const SizedBox(height: 24),
          
          // Hours by Week Chart
          _buildHoursChart(context, workloadAnalytics),
          const SizedBox(height: 24),
          
          // Activity Breakdown Chart
          _buildActivityBreakdown(context, workloadAnalytics),
          const SizedBox(height: 24),
          
          // Weekly Trend Chart
          _buildWeeklyTrend(context, workloadAnalytics),
          const SizedBox(height: 24),
          
          // Workload Alerts
          _buildWorkloadAlerts(context, workloadAnalytics),
        ],
      ),
    );
  }

  Widget _buildWorkloadOverview(BuildContext context, WorkloadAnalytics analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workload Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            _buildOverviewCard(
              context,
              'Total Hours',
              '${analytics.totalWorkingHours.toStringAsFixed(1)}h',
              Icons.access_time,
              AppTheme.primaryColor,
            ),
            const SizedBox(height: 12),
            _buildOverviewCard(
              context,
              'Weekly Average',
              '${analytics.weeklyAverageHours.toStringAsFixed(1)}h',
              Icons.calendar_view_week,
              AppTheme.accentColor,
            ),
            const SizedBox(height: 12),
            _buildOverviewCard(
              context,
              'Department',
              analytics.department,
              Icons.business,
              Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnalyticsThemeUtils.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AnalyticsThemeUtils.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AnalyticsThemeUtils.getContainerBackgroundColor(context, color),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursChart(BuildContext context, WorkloadAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnalyticsThemeUtils.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AnalyticsThemeUtils.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hours by Week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return AnalyticsThemeUtils.getChartGridLine(context, value);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}h',
                          style: TextStyle(
                            fontSize: 12, 
                            color: AnalyticsThemeUtils.getAxisTextColor(context),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final weekIndex = value.toInt();
                        if (weekIndex >= 0 && weekIndex < analytics.hoursByWeek.length) {
                          return Text(
                            'W${weekIndex + 1}',
                            style: TextStyle(
                              fontSize: 12, 
                              color: AnalyticsThemeUtils.getAxisTextColor(context),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getWeeklyHoursSpots(analytics.hoursByWeek),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return AnalyticsThemeUtils.getChartDotPainter(context, AppTheme.primaryColor);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBreakdown(BuildContext context, WorkloadAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnalyticsThemeUtils.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AnalyticsThemeUtils.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _getActivitySections(analytics.hoursByActivity, context),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildActivityLegend(analytics.hoursByActivity, context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrend(BuildContext context, WorkloadAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnalyticsThemeUtils.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AnalyticsThemeUtils.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Workload Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AnalyticsThemeUtils.getContainerBackgroundColor(
                    context, 
                    AnalyticsThemeUtils.getTrendColor(context, analytics.trend),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTrendIcon(analytics.trend),
                      size: 16,
                      color: AnalyticsThemeUtils.getTrendColor(context, analytics.trend),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      analytics.trend.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AnalyticsThemeUtils.getTrendColor(context, analytics.trend),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: analytics.hoursByMonth.values.isNotEmpty 
                    ? analytics.hoursByMonth.values.reduce((a, b) => a > b ? a : b) * 1.2
                    : 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}h',
                          style: TextStyle(
                            fontSize: 10, 
                            color: AnalyticsThemeUtils.getAxisTextColor(context),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final monthIndex = value.toInt();
                        final months = analytics.hoursByMonth.keys.toList();
                        if (monthIndex >= 0 && monthIndex < months.length) {
                          return Text(
                            months[monthIndex].substring(0, 3),
                            style: TextStyle(
                              fontSize: 10, 
                              color: AnalyticsThemeUtils.getAxisTextColor(context),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getMonthlyHoursBars(analytics.hoursByMonth),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadAlerts(BuildContext context, WorkloadAnalytics analytics) {
    if (analytics.alerts.isEmpty) {
      final successColor = AnalyticsThemeUtils.getSuccessColor(context);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AnalyticsThemeUtils.getContainerBackgroundColor(context, successColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AnalyticsThemeUtils.getBorderColor(context, successColor),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: successColor),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No workload alerts. Everything looks good!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workload Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...analytics.alerts.map((alert) {
          final alertColor = AnalyticsThemeUtils.getAlertColor(alert.severity, context);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AnalyticsThemeUtils.getContainerBackgroundColor(context, alertColor),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AnalyticsThemeUtils.getBorderColor(context, alertColor),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getAlertIcon(alert.severity),
                  color: alertColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.message,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Severity: ${alert.severity.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: alertColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<FlSpot> _getWeeklyHoursSpots(Map<String, double> hoursByWeek) {
    final spots = <FlSpot>[];
    final weeks = hoursByWeek.keys.toList()..sort();
    
    for (int i = 0; i < weeks.length; i++) {
      final hours = hoursByWeek[weeks[i]] ?? 0;
      spots.add(FlSpot(i.toDouble(), hours));
    }
    
    return spots;
  }

  List<PieChartSectionData> _getActivitySections(Map<String, double> hoursByActivity, BuildContext context) {
    final colors = AnalyticsThemeUtils.getChartColors(context);
    
    final sections = <PieChartSectionData>[];
    final activities = hoursByActivity.keys.toList();
    
    for (int i = 0; i < activities.length; i++) {
      final activity = activities[i];
      final hours = hoursByActivity[activity] ?? 0;
      final color = colors[i % colors.length];
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: hours,
          title: '${hours.toStringAsFixed(0)}h',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return sections;
  }

  List<Widget> _buildActivityLegend(Map<String, double> hoursByActivity, BuildContext context) {
    final colors = AnalyticsThemeUtils.getChartColors(context);
    
    final activities = hoursByActivity.keys.toList();
    
    return activities.asMap().entries.map((entry) {
      final index = entry.key;
      final activity = entry.value;
      final hours = hoursByActivity[activity] ?? 0;
      final color = colors[index % colors.length];
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activity.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text(
              '${hours.toStringAsFixed(0)}h',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _getMonthlyHoursBars(Map<String, double> hoursByMonth) {
    final months = hoursByMonth.keys.toList();
    
    return months.asMap().entries.map((entry) {
      final index = entry.key;
      final month = entry.value;
      final hours = hoursByMonth[month] ?? 0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: hours,
            color: AppTheme.primaryColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
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

  IconData _getAlertIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Icons.error;
      case 'medium':
        return Icons.warning;
      case 'low':
        return Icons.info;
      default:
        return Icons.info;
    }
  }
}