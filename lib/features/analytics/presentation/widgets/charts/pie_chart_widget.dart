import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/charts/base_chart_widget.dart';

/// Pie chart widget for displaying analytics data distribution
class AnalyticsPieChart extends BaseChartWidget {
  final bool showPercentages;
  final bool showValues;
  final double centerSpaceRadius;
  final bool showLegendBelowChart;

  const AnalyticsPieChart({
    super.key,
    required super.data,
    required super.title,
    super.showLegend = true,
    super.isLoading = false,
    super.error,
    super.onRefresh,
    this.showPercentages = true,
    this.showValues = false,
    this.centerSpaceRadius = 40,
    this.showLegendBelowChart = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildContent(context),
            if (showLegend && showLegendBelowChart && data.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLegend(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : onRefresh,
            tooltip: 'Refresh Chart',
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRefresh != null) ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onRefresh,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No data available',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 250,
            child: buildChart(context),
          ),
        ),
        if (showLegend && !showLegendBelowChart) ...[
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: _buildLegend(context),
          ),
        ],
      ],
    );
  }

  @override
  Widget buildChart(BuildContext context) {
    return PieChart(
      PieChartData(
        pieTouchData: _buildPieTouchData(context),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: centerSpaceRadius,
        sections: _buildPieSections(context),
      ),
    );
  }

  PieTouchData _buildPieTouchData(BuildContext context) {
    return PieTouchData(
      enabled: true,
      touchCallback: (FlTouchEvent event, pieTouchResponse) {
        // Handle touch events if needed
      },
    );
  }

  List<PieChartSectionData> _buildPieSections(BuildContext context) {
    final colors = getChartColors(context);
    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final chartData = entry.value;
      final color = chartData.color ?? colors[index % colors.length];
      final percentage = (chartData.value / total) * 100;

      return PieChartSectionData(
        color: color,
        value: chartData.value,
        title: _getSectionTitle(chartData, percentage),
        radius: 80,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _getContrastColor(color),
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  String _getSectionTitle(ChartData chartData, double percentage) {
    if (showPercentages && showValues) {
      return '${percentage.toStringAsFixed(1)}%\n${formatValue(chartData.value)}';
    } else if (showPercentages) {
      return '${percentage.toStringAsFixed(1)}%';
    } else if (showValues) {
      return formatValue(chartData.value);
    } else {
      return '';
    }
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we should use light or dark text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildLegend(BuildContext context) {
    final colors = getChartColors(context);
    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLegendBelowChart)
          Text(
            'Legend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 8),
        ...data.asMap().entries.map((entry) {
          final index = entry.key;
          final chartData = entry.value;
          final color = chartData.color ?? colors[index % colors.length];
          final percentage = (chartData.value / total) * 100;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chartData.label,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${formatValue(chartData.value)} (${percentage.toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}