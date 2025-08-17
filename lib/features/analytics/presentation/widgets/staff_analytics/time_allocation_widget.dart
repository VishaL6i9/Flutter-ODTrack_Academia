import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:odtrack_academia/core/theme/app_theme.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/providers/staff_analytics_provider.dart';
import 'package:odtrack_academia/services/analytics/staff_analytics_service.dart';
import 'package:odtrack_academia/shared/widgets/loading_widget.dart';
import 'package:odtrack_academia/shared/widgets/empty_state_widget.dart';

/// Widget for displaying time allocation analytics
class TimeAllocationWidget extends ConsumerWidget {
  final String staffId;
  final DateRange dateRange;

  const TimeAllocationWidget({
    super.key,
    required this.staffId,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeAllocationAnalytics = ref.watch(timeAllocationAnalyticsProvider);
    final isLoading = ref.watch(staffAnalyticsLoadingProvider);

    if (isLoading) {
      return const LoadingWidget(message: 'Loading time allocation analytics...');
    }

    if (timeAllocationAnalytics == null) {
      return const EmptyStateWidget(
        icon: Icons.schedule_outlined,
        title: 'No Time Allocation Data',
        message: 'No time allocation analytics data available for the selected period.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Allocation Overview
          _buildTimeAllocationOverview(timeAllocationAnalytics),
          const SizedBox(height: 24),
          
          // Activity Time Distribution Chart
          _buildActivityTimeChart(timeAllocationAnalytics),
          const SizedBox(height: 24),
          
          // Daily Time Distribution
          _buildDailyTimeChart(timeAllocationAnalytics),
          const SizedBox(height: 24),
          
          // Activity Percentages
          _buildActivityPercentages(timeAllocationAnalytics),
          const SizedBox(height: 24),
          
          // Time Conflicts
          _buildTimeConflicts(timeAllocationAnalytics),
        ],
      ),
    );
  }

  Widget _buildTimeAllocationOverview(TimeAllocationAnalytics analytics) {
    final totalMinutes = analytics.timeByActivity.values
        .fold<int>(0, (sum, duration) => sum + duration.inMinutes);
    final totalHours = totalMinutes / 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Allocation Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Total Time',
                '${totalHours.toStringAsFixed(1)}h',
                Icons.access_time,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Teaching',
                '${analytics.teachingPercentage.toStringAsFixed(1)}%',
                Icons.school,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Administrative',
                '${analytics.administrativePercentage.toStringAsFixed(1)}%',
                Icons.business,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'OD Processing',
                '${analytics.odProcessingPercentage.toStringAsFixed(1)}%',
                Icons.assignment,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeChart(TimeAllocationAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Distribution by Activity',
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
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: _getActivityTimeSections(analytics.timeByActivity),
                      centerSpaceRadius: 50,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildActivityTimeLegend(analytics.timeByActivity),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTimeChart(TimeAllocationAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Time Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxDailyHours(analytics.timeByDay) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayName = _getDayName(groupIndex + 1);
                      final hours = rod.toY;
                      return BarTooltipItem(
                        '$dayName\n${hours.toStringAsFixed(1)} hours',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}h',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final dayIndex = value.toInt() + 1;
                        return Text(
                          _getDayName(dayIndex).substring(0, 3),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getDailyTimeBars(analytics.timeByDay),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPercentages(TimeAllocationAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Breakdown Percentages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPercentageBar('Teaching', analytics.teachingPercentage, Colors.green),
          const SizedBox(height: 12),
          _buildPercentageBar('Administrative', analytics.administrativePercentage, Colors.orange),
          const SizedBox(height: 12),
          _buildPercentageBar('OD Processing', analytics.odProcessingPercentage, Colors.blue),
          const SizedBox(height: 12),
          _buildPercentageBar('Other Activities', analytics.otherActivitiesPercentage, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildPercentageBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeConflicts(TimeAllocationAnalytics analytics) {
    if (analytics.conflicts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade600),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No time conflicts detected. Schedule looks well organized!',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Time Conflicts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${analytics.conflicts.length} conflicts',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...analytics.conflicts.map((conflict) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getConflictColor(conflict.severity).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getConflictColor(conflict.severity).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getConflictIcon(conflict.severity),
                      color: _getConflictColor(conflict.severity),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        conflict.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getConflictColor(conflict.severity),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        conflict.severity.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Conflicting activities: ${conflict.conflictingActivities.join(', ')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getActivityTimeSections(Map<ActivityType, Duration> timeByActivity) {
    final colors = [
      Colors.green,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
    ];
    
    final sections = <PieChartSectionData>[];
    final activities = timeByActivity.keys.toList();
    
    for (int i = 0; i < activities.length; i++) {
      final activity = activities[i];
      final duration = timeByActivity[activity]!;
      final hours = duration.inMinutes / 60;
      final color = colors[i % colors.length];
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: hours,
          title: '${hours.toStringAsFixed(1)}h',
          radius: 70,
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

  List<Widget> _buildActivityTimeLegend(Map<ActivityType, Duration> timeByActivity) {
    final colors = [
      Colors.green,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
    ];
    
    final activities = timeByActivity.keys.toList();
    
    return activities.asMap().entries.map((entry) {
      final index = entry.key;
      final activity = entry.value;
      final duration = timeByActivity[activity]!;
      final hours = duration.inMinutes / 60;
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
                _getActivityDisplayName(activity),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text(
              '${hours.toStringAsFixed(1)}h',
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

  double _getMaxDailyHours(Map<int, Duration> timeByDay) {
    if (timeByDay.isEmpty) return 8;
    return timeByDay.values
        .map((d) => d.inMinutes / 60)
        .reduce((a, b) => a > b ? a : b);
  }

  List<BarChartGroupData> _getDailyTimeBars(Map<int, Duration> timeByDay) {
    final days = [1, 2, 3, 4, 5, 6, 7]; // Monday to Sunday
    
    return days.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;
      final duration = timeByDay[day] ?? Duration.zero;
      final hours = duration.inMinutes / 60;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: hours,
            color: AppTheme.primaryColor,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  String _getDayName(int dayIndex) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[(dayIndex - 1) % 7];
  }

  String _getActivityDisplayName(ActivityType activity) {
    switch (activity) {
      case ActivityType.teaching:
        return 'Teaching';
      case ActivityType.odProcessing:
        return 'OD Processing';
      case ActivityType.administrative:
        return 'Administrative';
      case ActivityType.meetings:
        return 'Meetings';
      case ActivityType.preparation:
        return 'Preparation';
      case ActivityType.evaluation:
        return 'Evaluation';
      case ActivityType.other:
        return 'Other';
    }
  }

  IconData _getConflictIcon(String severity) {
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

  Color _getConflictColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
