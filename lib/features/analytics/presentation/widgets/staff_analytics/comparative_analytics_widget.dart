import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:odtrack_academia/core/theme/app_theme.dart';
import 'package:odtrack_academia/providers/staff_analytics_provider.dart';
import 'package:odtrack_academia/services/analytics/staff_analytics_service.dart';
import 'package:odtrack_academia/shared/widgets/loading_widget.dart';
import 'package:odtrack_academia/shared/widgets/empty_state_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/utils/analytics_theme_utils.dart';

/// Widget for displaying comparative analytics across semesters
class ComparativeAnalyticsWidget extends ConsumerWidget {
  final String staffId;
  final List<String> semesters;

  const ComparativeAnalyticsWidget({
    super.key,
    required this.staffId,
    required this.semesters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparativeAnalytics = ref.watch(comparativeAnalyticsProvider);
    final isLoading = ref.watch(staffAnalyticsLoadingProvider);

    if (isLoading) {
      return const LoadingWidget(message: 'Loading comparative analytics...');
    }

    if (comparativeAnalytics == null) {
      return const EmptyStateWidget(
        icon: Icons.compare_arrows_outlined,
        title: 'No Comparative Data',
        message: 'No comparative analytics data available for the selected semesters.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Semester Comparison Overview
          _buildSemesterComparisonOverview(comparativeAnalytics),
          const SizedBox(height: 24),
          
          // Trend Analysis Charts
          _buildTrendAnalysisCharts(comparativeAnalytics),
          const SizedBox(height: 24),
          
          // Performance Improvements
          _buildPerformanceImprovements(comparativeAnalytics),
          const SizedBox(height: 24),
          
          // Performance Declines
          _buildPerformanceDeclines(comparativeAnalytics),
          const SizedBox(height: 24),
          
          // Detailed Semester Comparison
          _buildDetailedSemesterComparison(comparativeAnalytics),
        ],
      ),
    );
  }

  Widget _buildSemesterComparisonOverview(ComparativeAnalytics analytics) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Semester Comparison Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AnalyticsThemeUtils.getGridLineColor(context),
                      strokeWidth: 1,
                    );
                  },
                ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: TextStyle(
                          fontSize: 12, 
                          color: AnalyticsThemeUtils.getSecondaryTextColor(context),
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
                      final index = value.toInt();
                      if (index >= 0 && index < analytics.semesterComparisons.length) {
                        return Text(
                          analytics.semesterComparisons[index].semester,
                          style: TextStyle(
                            fontSize: 10, 
                            color: AnalyticsThemeUtils.getSecondaryTextColor(context),
                          ),
                        );
                      }
                      return const Text(' ');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Working Hours Line
                LineChartBarData(
                  spots: _getWorkingHoursSpots(analytics.semesterComparisons),
                  isCurved: true,
                  color: AppTheme.primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                // Efficiency Score Line
                LineChartBarData(
                  spots: _getEfficiencySpots(analytics.semesterComparisons),
                  isCurved: true,
                  color: Colors.orange,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                ),
                // Satisfaction Score Line
                LineChartBarData(
                  spots: _getSatisfactionSpots(analytics.semesterComparisons),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Working Hours', AppTheme.primaryColor),
            _buildLegendItem('Efficiency Score', Colors.orange),
            _buildLegendItem('Satisfaction Score', Colors.green),
          ],
        ),
      ],
    ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTrendAnalysisCharts(ComparativeAnalytics analytics) {
    return Builder(
      builder: (context) => Container(
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
            'Trend Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTrendCard(
                  'Workload Trend',
                  analytics.workloadTrend,
                  Icons.work_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendCard(
                  'Efficiency Trend',
                  analytics.efficiencyTrend,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendCard(
                  'Satisfaction Trend',
                  analytics.studentSatisfactionTrend,
                  Icons.sentiment_satisfied,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTrendCard(String title, TrendAnalysis trend, IconData icon) {
    final color = _getTrendColor(trend.direction);
    final trendIcon = _getTrendIcon(trend.direction);
    
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AnalyticsThemeUtils.getContainerBackgroundColor(context, color),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AnalyticsThemeUtils.getBorderColor(context, color),
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Icon(trendIcon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            trend.direction.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Confidence: ${(trend.confidence * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10, 
              color: AnalyticsThemeUtils.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildPerformanceImprovements(ComparativeAnalytics analytics) {
    if (analytics.improvements.isEmpty) {
      return Builder(
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AnalyticsThemeUtils.getSecondaryBackgroundColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline, 
                color: AnalyticsThemeUtils.getSecondaryTextColor(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    'No significant improvements detected in the analyzed period.',
                    style: TextStyle(
                      color: AnalyticsThemeUtils.getSecondaryTextColor(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Builder(
      builder: (context) => Container(
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
                  'Performance Improvements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AnalyticsThemeUtils.getContainerBackgroundColor(context, Colors.green),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${analytics.improvements.length} improvements',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...analytics.improvements.map((improvement) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AnalyticsThemeUtils.getContainerBackgroundColor(context, Colors.green, opacity: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AnalyticsThemeUtils.getBorderColor(context, Colors.green, opacity: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        improvement.area,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        improvement.description,
                        style: TextStyle(
                          fontSize: 12, 
                          color: AnalyticsThemeUtils.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${improvement.improvementPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    ),
    );
  }

  Widget _buildPerformanceDeclines(ComparativeAnalytics analytics) {
    if (analytics.declines.isEmpty) {
      return Builder(
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AnalyticsThemeUtils.getContainerBackgroundColor(context, Colors.green, opacity: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AnalyticsThemeUtils.getBorderColor(context, Colors.green, opacity: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green.shade600),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No performance declines detected. Great job maintaining consistency!',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Builder(
      builder: (context) => Container(
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
                  'Areas for Improvement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AnalyticsThemeUtils.getContainerBackgroundColor(context, Colors.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${analytics.declines.length} areas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...analytics.declines.map((decline) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AnalyticsThemeUtils.getContainerBackgroundColor(context, Colors.orange, opacity: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AnalyticsThemeUtils.getBorderColor(context, Colors.orange, opacity: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_down, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        decline.area,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '-${decline.declinePercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  decline.description,
                  style: TextStyle(
                    fontSize: 12, 
                    color: AnalyticsThemeUtils.getSecondaryTextColor(context),
                  ),
                ),
                if (decline.suggestedActions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Suggested Actions:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  ...decline.suggestedActions.map((action) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      '• $action',
                      style: TextStyle(
                        fontSize: 11, 
                        color: AnalyticsThemeUtils.getSecondaryTextColor(context),
                      ),
                    ),
                  )),
                ],
              ],
            ),
          )),
        ],
      ),
    ),
    );
  }

  Widget _buildDetailedSemesterComparison(ComparativeAnalytics analytics) {
    return Builder(
      builder: (context) => Container(
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
            'Detailed Semester Comparison',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Semester')),
                DataColumn(label: Text('Working Hours')),
                DataColumn(label: Text('Periods Allocated')),
                DataColumn(label: Text('Efficiency Score')),
                DataColumn(label: Text('Satisfaction Score')),
              ],
              rows: analytics.semesterComparisons.map((comparison) {
                return DataRow(
                  cells: [
                    DataCell(Text(comparison.semester)),
                    DataCell(Text('${comparison.workingHours.toStringAsFixed(1)}h')),
                    DataCell(Text('${comparison.periodsAllocated}')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AnalyticsThemeUtils.getContainerBackgroundColor(
                            context, 
                            _getScoreColor(comparison.efficiencyScore),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          comparison.efficiencyScore.toStringAsFixed(1),
                          style: TextStyle(
                            color: _getScoreColor(comparison.efficiencyScore),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AnalyticsThemeUtils.getContainerBackgroundColor(
                            context, 
                            _getScoreColor(comparison.satisfactionScore),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          comparison.satisfactionScore.toStringAsFixed(1),
                          style: TextStyle(
                            color: _getScoreColor(comparison.satisfactionScore),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
    );
  }

  List<FlSpot> _getWorkingHoursSpots(List<SemesterComparison> comparisons) {
    return comparisons.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.workingHours);
    }).toList();
  }

  List<FlSpot> _getEfficiencySpots(List<SemesterComparison> comparisons) {
    return comparisons.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.efficiencyScore);
    }).toList();
  }

  List<FlSpot> _getSatisfactionSpots(List<SemesterComparison> comparisons) {
    return comparisons.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.satisfactionScore);
    }).toList();
  }

  Color _getTrendColor(String direction) {
    switch (direction.toLowerCase()) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      case 'stable':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(String direction) {
    switch (direction.toLowerCase()) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      case 'stable':
        return Icons.trending_flat;
      default:
        return Icons.help_outline;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}