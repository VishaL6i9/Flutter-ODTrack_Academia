import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/charts/base_chart_widget.dart';

/// Line chart widget for displaying trend analytics data
class AnalyticsLineChart extends BaseChartWidget {
  final bool showDots;
  final bool showArea;
  final bool showGrid;
  final double? minY;
  final double? maxY;

  const AnalyticsLineChart({
    super.key,
    required super.data,
    required super.title,
    super.showLegend = true,
    super.isLoading = false,
    super.error,
    super.onRefresh,
    this.showDots = true,
    this.showArea = false,
    this.showGrid = true,
    this.minY,
    this.maxY,
  });

  @override
  Widget buildChart(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: _buildGridData(context),
        titlesData: _buildTitlesData(context),
        borderData: _buildBorderData(context),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY ?? _getMinValue() * 0.9,
        maxY: maxY ?? _getMaxValue() * 1.1,
        lineBarsData: _buildLineBarsData(context),
        lineTouchData: _buildLineTouchData(context),
      ),
    );
  }

  double _getMinValue() {
    if (data.isEmpty) return 0;
    return data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxValue() {
    if (data.isEmpty) return 100;
    return data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
  }

  FlGridData _buildGridData(BuildContext context) {
    if (!showGrid) {
      return const FlGridData(show: false);
    }

    return FlGridData(
      show: true,
      drawVerticalLine: true,
      horizontalInterval: _getGridInterval(),
      verticalInterval: 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          strokeWidth: 1,
        );
      },
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
          reservedSize: 42,
          interval: _getBottomTitleInterval(),
          getTitlesWidget: (value, meta) => _buildBottomTitle(context, value),
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          interval: _getGridInterval(),
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
        label.length > 6 ? '${label.substring(0, 6)}...' : label,
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
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData(BuildContext context) {
    final colors = getChartColors(context);
    final primaryColor = colors.first;

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: primaryColor,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: showDots,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: primaryColor,
              strokeWidth: 2,
              strokeColor: Theme.of(context).colorScheme.surface,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: showArea,
          color: primaryColor.withValues(alpha: 0.2),
        ),
      ),
    ];
  }

  LineTouchData _buildLineTouchData(BuildContext context) {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.inverseSurface,
        tooltipRoundedRadius: 8,
        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          return touchedBarSpots.map((barSpot) {
            final index = barSpot.x.toInt();
            if (index < 0 || index >= data.length) {
              return null;
            }

            final chartData = data[index];
            return LineTooltipItem(
              '${chartData.label}\n${formatValue(chartData.value)}',
              TextStyle(
                color: Theme.of(context).colorScheme.onInverseSurface,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList();
        },
      ),
      handleBuiltInTouches: true,
      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
        return spotIndexes.map((spotIndex) {
          return TouchedSpotIndicatorData(
            FlLine(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              strokeWidth: 2,
            ),
            FlDotData(
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
          );
        }).toList();
      },
    );
  }

  double _getGridInterval() {
    final range = (_getMaxValue() - _getMinValue());
    if (range <= 10) return 2;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    if (range <= 500) return 100;
    return (range / 5).roundToDouble();
  }

  double _getBottomTitleInterval() {
    if (data.length <= 5) return 1;
    if (data.length <= 10) return 2;
    if (data.length <= 20) return 4;
    return (data.length / 5).roundToDouble();
  }
}