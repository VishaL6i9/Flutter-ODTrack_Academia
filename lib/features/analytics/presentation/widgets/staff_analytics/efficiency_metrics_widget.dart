import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:odtrack_academia/core/theme/app_theme.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/providers/staff_analytics_provider.dart';
import 'package:odtrack_academia/services/analytics/staff_analytics_service.dart';
import 'package:odtrack_academia/shared/widgets/loading_widget.dart';
import 'package:odtrack_academia/shared/widgets/empty_state_widget.dart';

/// Widget for displaying efficiency metrics with interactive charts
class EfficiencyMetricsWidget extends ConsumerWidget {
  final String staffId;
  final DateRange dateRange;

  const EfficiencyMetricsWidget({
    super.key,
    required this.staffId,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final efficiencyMetrics = ref.watch(efficiencyMetricsProvider);
    final isLoading = ref.watch(staffAnalyticsLoadingProvider);

    if (isLoading) {
      return const LoadingWidget(message: 'Loading efficiency metrics...');
    }

    if (efficiencyMetrics == null) {
      return const EmptyStateWidget(
        icon: Icons.trending_up_outlined,
        title: 'No Efficiency Data',
        message: 'No efficiency metrics data available for the selected period.',
      );
    }

    return Theme(
      data: ThemeData.light(),
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Efficiency Overview Cards
          _buildEfficiencyOverview(efficiencyMetrics),
          const SizedBox(height: 24),
          
          // OD Processing Metrics
          _buildODProcessingMetrics(efficiencyMetrics),
          const SizedBox(height: 24),
          
          // Performance Comparison Charts
          _buildPerformanceComparison(efficiencyMetrics),
          const SizedBox(height: 24),
          
          // OD Status Distribution
          _buildODStatusDistribution(efficiencyMetrics),
          const SizedBox(height: 24),
          
          // Student Satisfaction Score
          _buildStudentSatisfactionScore(efficiencyMetrics),
        ],
      ),
      ),
    );
  }

  Widget _buildEfficiencyOverview(EfficiencyMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Efficiency Overview',
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
                'Approval Rate',
                '${metrics.odApprovalRate.toStringAsFixed(1)}%',
                Icons.check_circle_outline,
                _getApprovalRateColor(metrics.odApprovalRate),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Avg Processing Time',
                '${metrics.averageODProcessingTime.toStringAsFixed(1)}h',
                Icons.schedule,
                _getProcessingTimeColor(metrics.averageODProcessingTime),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Response Time',
                '${metrics.odResponseTime.toStringAsFixed(1)}h',
                Icons.reply,
                _getResponseTimeColor(metrics.odResponseTime),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Total Processed',
                '${metrics.totalODsProcessed}',
                Icons.assignment_turned_in,
                AppTheme.primaryColor,
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

  Widget _buildODProcessingMetrics(EfficiencyMetrics metrics) {
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
            'OD Processing Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Processing Speed',
                  '${metrics.averageODProcessingTime.toStringAsFixed(1)} hours',
                  _getProcessingSpeedRating(metrics.averageODProcessingTime),
                  _getProcessingTimeColor(metrics.averageODProcessingTime),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Response Speed',
                  '${metrics.odResponseTime.toStringAsFixed(1)} hours',
                  _getResponseSpeedRating(metrics.odResponseTime),
                  _getResponseTimeColor(metrics.odResponseTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Approval Efficiency',
                  '${metrics.odApprovalRate.toStringAsFixed(1)}%',
                  _getApprovalRating(metrics.odApprovalRate),
                  _getApprovalRateColor(metrics.odApprovalRate),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Volume Handled',
                  '${metrics.totalODsProcessed} requests',
                  _getVolumeRating(metrics.totalODsProcessed),
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String rating, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rating,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceComparison(EfficiencyMetrics metrics) {
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
            'Performance Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildComparisonCard(
                  'Department Comparison',
                  metrics.departmentComparison,
                  Icons.business,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildComparisonCard(
                  'Institution Comparison',
                  metrics.institutionComparison,
                  Icons.school,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(String title, ComparisonMetrics comparison, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildComparisonMetric(
            'Processing Time',
            '${comparison.averageProcessingTime.toStringAsFixed(1)}h avg',
            color,
          ),
          const SizedBox(height: 8),
          _buildComparisonMetric(
            'Approval Rate',
            '${comparison.averageApprovalRate.toStringAsFixed(1)}% avg',
            color,
          ),
          const SizedBox(height: 8),
          _buildComparisonMetric(
            'Response Time',
            '${comparison.averageResponseTime.toStringAsFixed(1)}h avg',
            color,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Percentile: ${comparison.percentileRank.toStringAsFixed(0)}th',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonMetric(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildODStatusDistribution(EfficiencyMetrics metrics) {
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
            'OD Request Status Distribution',
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
                      sections: _getODStatusSections(metrics.odsByStatus),
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
                  children: _buildODStatusLegend(metrics.odsByStatus),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSatisfactionScore(EfficiencyMetrics metrics) {
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
            'Student Satisfaction Score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${metrics.studentSatisfactionScore.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getSatisfactionColor(metrics.studentSatisfactionScore),
                      ),
                    ),
                    Text(
                      _getSatisfactionRating(metrics.studentSatisfactionScore),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _getSatisfactionColor(metrics.studentSatisfactionScore),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on student feedback and response quality',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: metrics.studentSatisfactionScore / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getSatisfactionColor(metrics.studentSatisfactionScore),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getODStatusSections(Map<String, int> odsByStatus) {
    final statusColors = {
      'approved': Colors.green,
      'rejected': Colors.red,
      'pending': Colors.orange,
      'cancelled': Colors.grey,
    };
    
    final sections = <PieChartSectionData>[];
    
    odsByStatus.forEach((status, count) {
      final color = statusColors[status.toLowerCase()] ?? Colors.blue;
      sections.add(
        PieChartSectionData(
          color: color,
          value: count.toDouble(),
          title: '$count',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });
    
    return sections;
  }

  List<Widget> _buildODStatusLegend(Map<String, int> odsByStatus) {
    final statusColors = {
      'approved': Colors.green,
      'rejected': Colors.red,
      'pending': Colors.orange,
      'cancelled': Colors.grey,
    };
    
    return odsByStatus.entries.map((entry) {
      final status = entry.key;
      final count = entry.value;
      final color = statusColors[status.toLowerCase()] ?? Colors.blue;
      
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
                status.toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text(
              '$count',
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

  Color _getApprovalRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getProcessingTimeColor(double hours) {
    if (hours <= 24) return Colors.green;
    if (hours <= 48) return Colors.orange;
    return Colors.red;
  }

  Color _getResponseTimeColor(double hours) {
    if (hours <= 12) return Colors.green;
    if (hours <= 24) return Colors.orange;
    return Colors.red;
  }

  Color _getSatisfactionColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  String _getProcessingSpeedRating(double hours) {
    if (hours <= 24) return 'EXCELLENT';
    if (hours <= 48) return 'GOOD';
    if (hours <= 72) return 'AVERAGE';
    return 'NEEDS IMPROVEMENT';
  }

  String _getResponseSpeedRating(double hours) {
    if (hours <= 12) return 'EXCELLENT';
    if (hours <= 24) return 'GOOD';
    if (hours <= 48) return 'AVERAGE';
    return 'NEEDS IMPROVEMENT';
  }

  String _getApprovalRating(double rate) {
    if (rate >= 80) return 'EXCELLENT';
    if (rate >= 60) return 'GOOD';
    if (rate >= 40) return 'AVERAGE';
    return 'NEEDS IMPROVEMENT';
  }

  String _getVolumeRating(int count) {
    if (count >= 100) return 'HIGH VOLUME';
    if (count >= 50) return 'MODERATE';
    if (count >= 20) return 'LOW VOLUME';
    return 'MINIMAL';
  }

  String _getSatisfactionRating(double score) {
    if (score >= 90) return 'Outstanding';
    if (score >= 80) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Satisfactory';
    return 'Needs Improvement';
  }
}
