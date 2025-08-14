import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/charts/base_chart_widget.dart';

/// Bar chart widget for displaying analytics data
class AnalyticsBarChart extends BaseChartWidget {
  final bool isHorizontal;
  final bool showValues;
  final double? maxY;

  const AnalyticsBarChart({
    super.key,
    required super.data,
    required super.title,
    super.showLegend = true,
    super.isLoading = false,
    super.error,
    super.onRefresh,
    this.isHorizontal = false,
    this.showValues = true,
    this.maxY,
  });

  @override
  Widget buildChart(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY ?? _getMaxValue() * 1.2,
        barTouchData: _buildBarTouchData(context),
        titlesData: _buildTitlesData(context),
        borderData: _buildBorderData(context),
        barGroups: _buildBarGroups(context),
        gridData: _buildGridData(context),
      ),
    );
  }

  double _getMaxValue() {
    if (data.isEmpty) return 100;
    return data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
  }

  BarTouchData _buildBarTouchData(BuildContext context) {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (group) => Theme.of(context).colorScheme.inverseSurface,
        tooltipRoundedRadius: 8,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final chartData = data[groupIndex];
          return BarTooltipItem(
            '${chartData.label}\n${formatValue(chartData.value)}',
            TextStyle(
              color: Theme.of(context).colorScheme.onInverseSurface,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  FlTitlesData _buildTitlesData(BuildContext context) {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => _buildBottomTitle(context, value),
          reservedSize: 42,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          getTitlesWidget: (value, meta) => _buildLeftTitle(context, value),
        ),
      ),
    );
  }

  Widget _buildBottomTitle(BuildContext context, double value) {
    final index = value.toInt();
    if (index < 0 || index >= data.length) {
      return const SizedBox.shrink();
    }

    final label = data[index].label;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        label.length > 8 ? '${label.substring(0, 8)}...' : label,
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLeftTitle(BuildContext context, double value) {
    return Text(
      formatValue(value),
      style: Theme.of(context).textTheme.bodySmall,
      textAlign: TextAlign.right,
    );
  }

  FlBorderData _buildBorderData(BuildContext context) {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        left: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(BuildContext context) {
    final colors = getChartColors(context);
    
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final chartData = entry.value;
      final color = chartData.color ?? colors[index % colors.length];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: chartData.value,
            color: color,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY ?? _getMaxValue() * 1.2,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
        showingTooltipIndicators: showValues ? [0] : [],
      );
    }).toList();
  }

  FlGridData _buildGridData(BuildContext context) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: _getGridInterval(),
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          strokeWidth: 1,
        );
      },
    );
  }

  double _getGridInterval() {
    final maxValue = maxY ?? _getMaxValue() * 1.2;
    if (maxValue <= 10) return 2;
    if (maxValue <= 50) return 10;
    if (maxValue <= 100) return 20;
    if (maxValue <= 500) return 100;
    return (maxValue / 5).roundToDouble();
  }
}