import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:odtrack_academia/core/theme/app_theme.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/providers/staff_analytics_provider.dart';
import 'package:odtrack_academia/services/analytics/staff_analytics_service.dart';
import 'package:odtrack_academia/shared/widgets/loading_widget.dart';
import 'package:odtrack_academia/shared/widgets/empty_state_widget.dart';

/// Widget for displaying teaching analytics with interactive charts
class TeachingAnalyticsWidget extends ConsumerWidget {
  final String staffId;
  final String semester;

  const TeachingAnalyticsWidget({
    super.key,
    required this.staffId,
    required this.semester,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachingAnalytics = ref.watch(teachingAnalyticsProvider);
    final isLoading = ref.watch(staffAnalyticsLoadingProvider);

    if (isLoading) {
      return const LoadingWidget(message: 'Loading teaching analytics...');
    }

    if (teachingAnalytics == null) {
      return const EmptyStateWidget(
        icon: Icons.school_outlined,
        title: 'No Teaching Data',
        message: 'No teaching analytics data available for the selected semester.',
      );
    }

    return Theme(
      data: ThemeData.light(),
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teaching Overview Cards
          _buildTeachingOverview(teachingAnalytics),
          const SizedBox(height: 24),
          
          // Subject Allocation Chart
          _buildSubjectAllocationChart(teachingAnalytics),
          const SizedBox(height: 24),
          
          // Class Distribution Chart
          _buildClassDistributionChart(teachingAnalytics),
          const SizedBox(height: 24),
          
          // Grade-wise Analytics
          _buildGradeWiseAnalytics(teachingAnalytics),
          const SizedBox(height: 24),
          
          // Teaching Efficiency Metrics
          _buildTeachingEfficiencyMetrics(teachingAnalytics),
          const SizedBox(height: 24),
          
          // Detailed Subject Breakdown
          _buildSubjectBreakdown(teachingAnalytics),
        ],
      ),
      ),
    );
  }

  Widget _buildTeachingOverview(TeachingAnalytics analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teaching Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    'Total Periods',
                    '${analytics.totalPeriodsAllocated}',
                    Icons.schedule,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Classes Assigned',
                    '${analytics.totalClassesAssigned}',
                    Icons.class_,
                    AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    'Avg Class Size',
                    analytics.averageClassSize.toStringAsFixed(0),
                    Icons.people,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOverviewCard(
                    'Subjects',
                    '${analytics.subjectAllocations.length}',
                    Icons.book,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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

  Widget _buildSubjectAllocationChart(TeachingAnalytics analytics) {
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
            'Subject Allocation (Periods per Week)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxPeriodsPerWeek(analytics.subjectAllocations) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final subjects = analytics.subjectAllocations.keys.toList();
                      if (groupIndex < subjects.length) {
                        final subject = subjects[groupIndex];
                        final allocation = analytics.subjectAllocations[subject]!;
                        return BarTooltipItem(
                          '${allocation.subjectName}\n${rod.toY.toInt()} periods/week\n${allocation.studentCount.toInt()} students',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }
                      return null;
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
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        final subjects = analytics.subjectAllocations.keys.toList();
                        final index = value.toInt();
                        if (index >= 0 && index < subjects.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              subjects[index],
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                              textAlign: TextAlign.center,
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
                barGroups: _getSubjectAllocationBars(analytics.subjectAllocations),
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

  Widget _buildClassDistributionChart(TeachingAnalytics analytics) {
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
            'Class Distribution by Grade',
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
                      sections: _getGradeDistributionSections(analytics.gradeDistribution),
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
                  children: _buildGradeDistributionLegend(analytics.gradeDistribution),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeWiseAnalytics(TeachingAnalytics analytics) {
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
            'Grade-wise Class Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...analytics.gradeDistribution.entries.map((entry) {
            final grade = entry.key;
            final classCount = entry.value;
            final gradeClasses = analytics.classAllocations.values
                .where((c) => c.grade == grade)
                .toList();
            final totalStudents = gradeClasses.fold<int>(
              0, (sum, c) => sum + c.studentCount
            );
            final avgClassSize = gradeClasses.isNotEmpty 
                ? totalStudents / gradeClasses.length 
                : 0.0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getGradeColor(grade),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _getGradeDisplayName(grade),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grade ${_getGradeDisplayName(grade)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$classCount classes • $totalStudents students • Avg: ${avgClassSize.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${((classCount / analytics.totalClassesAssigned) * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getGradeColor(grade),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeachingEfficiencyMetrics(TeachingAnalytics analytics) {
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
            'Teaching Efficiency Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEfficiencyCard(
                  'Period Utilization',
                  '${(analytics.efficiency.periodsUtilizationRate * 100).toStringAsFixed(1)}%',
                  Icons.schedule,
                  _getEfficiencyColor(analytics.efficiency.periodsUtilizationRate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEfficiencyCard(
                  'Students/Period',
                  analytics.efficiency.averageStudentsPerPeriod.toStringAsFixed(1),
                  Icons.people,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEfficiencyCard(
                  'Subject Diversity',
                  '${(analytics.efficiency.subjectDiversityIndex * 100).toStringAsFixed(0)}%',
                  Icons.book,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEfficiencyCard(
                  'Grade Spread',
                  '${(analytics.efficiency.gradeLevelSpread * 100).toStringAsFixed(0)}%',
                  Icons.trending_up,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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

  Widget _buildSubjectBreakdown(TeachingAnalytics analytics) {
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
            'Detailed Subject Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...analytics.subjectAllocations.entries.map((entry) {
            final allocation = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSubjectTypeColor(allocation.type),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          allocation.type.toString().split('.').last.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          allocation.subjectName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${allocation.periodsPerWeek} periods/week',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSubjectStat('Total Periods', '${allocation.totalPeriods}'),
                      const SizedBox(width: 16),
                      _buildSubjectStat('Students', '${allocation.studentCount.toInt()}'),
                      const SizedBox(width: 16),
                      _buildSubjectStat('Classes', '${allocation.classAssignments.length}'),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubjectStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  double _getMaxPeriodsPerWeek(Map<String, SubjectAllocation> allocations) {
    if (allocations.isEmpty) return 10;
    return allocations.values
        .map((a) => a.periodsPerWeek.toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  List<BarChartGroupData> _getSubjectAllocationBars(Map<String, SubjectAllocation> allocations) {
    final subjects = allocations.keys.toList();
    
    return subjects.asMap().entries.map((entry) {
      final index = entry.key;
      final subject = entry.value;
      final allocation = allocations[subject]!;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: allocation.periodsPerWeek.toDouble(),
            color: _getSubjectTypeColor(allocation.type),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  List<PieChartSectionData> _getGradeDistributionSections(Map<Grade, int> gradeDistribution) {
    final sections = <PieChartSectionData>[];
    final grades = gradeDistribution.keys.toList();
    
    for (int i = 0; i < grades.length; i++) {
      final grade = grades[i];
      final classCount = gradeDistribution[grade] ?? 0;
      final color = _getGradeColor(grade);
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: classCount.toDouble(),
          title: '$classCount',
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

  List<Widget> _buildGradeDistributionLegend(Map<Grade, int> gradeDistribution) {
    final grades = gradeDistribution.keys.toList();
    
    return grades.map((grade) {
      final classCount = gradeDistribution[grade] ?? 0;
      final color = _getGradeColor(grade);
      
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
                'Grade ${_getGradeDisplayName(grade)}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text(
              '$classCount',
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

  Color _getGradeColor(Grade grade) {
    final colors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.orange,
    ];
    
    final index = Grade.values.indexOf(grade);
    return colors[index % colors.length];
  }

  String _getGradeDisplayName(Grade grade) {
    switch (grade) {
      case Grade.grade1: return '1';
      case Grade.grade2: return '2';
      case Grade.grade3: return '3';
      case Grade.grade4: return '4';
      case Grade.grade5: return '5';
      case Grade.grade6: return '6';
      case Grade.grade7: return '7';
      case Grade.grade8: return '8';
      case Grade.grade9: return '9';
      case Grade.grade10: return '10';
      case Grade.grade11: return '11';
      case Grade.grade12: return '12';
      case Grade.postGraduate: return 'PG';
    }
  }

  Color _getSubjectTypeColor(SubjectType type) {
    switch (type) {
      case SubjectType.theory:
        return AppTheme.primaryColor;
      case SubjectType.practical:
        return Colors.orange;
      case SubjectType.lab:
        return Colors.red;
      case SubjectType.project:
        return Colors.purple;
      case SubjectType.seminar:
        return Colors.teal;
    }
  }

  Color _getEfficiencyColor(double value) {
    if (value >= 0.8) return Colors.green;
    if (value >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
