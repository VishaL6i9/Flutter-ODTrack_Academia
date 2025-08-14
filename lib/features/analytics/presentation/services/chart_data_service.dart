import 'package:flutter/material.dart';
import 'package:odtrack_academia/models/analytics_models.dart';

/// Service for preparing chart data from analytics data
class ChartDataService {
  /// Convert analytics data to chart data for bar charts
  static List<ChartData> prepareBarChartData(
    AnalyticsData analyticsData,
    ChartType chartType,
  ) {
    switch (chartType) {
      case ChartType.bar:
        return _prepareStatusBarData(analyticsData);
      default:
        return [];
    }
  }

  /// Convert department analytics to chart data
  static List<ChartData> prepareDepartmentChartData(
    Map<String, DepartmentAnalytics> departmentAnalytics,
    ChartType chartType,
  ) {
    switch (chartType) {
      case ChartType.bar:
        return _prepareDepartmentBarData(departmentAnalytics);
      case ChartType.pie:
        return _prepareDepartmentPieData(departmentAnalytics);
      default:
        return [];
    }
  }

  /// Convert trend data to chart data for line charts
  static List<ChartData> prepareTrendChartData(
    List<TrendData> trendData,
    ChartType chartType,
  ) {
    if (trendData.isEmpty) return [];
    
    switch (chartType) {
      case ChartType.line:
        return _prepareTrendLineData(trendData.first);
      default:
        return [];
    }
  }

  /// Convert requests by month data to chart data
  static List<ChartData> prepareMonthlyChartData(
    Map<String, int> requestsByMonth,
    ChartType chartType,
  ) {
    final sortedEntries = requestsByMonth.entries.toList()
      ..sort((a, b) => _getMonthOrder(a.key).compareTo(_getMonthOrder(b.key)));

    return sortedEntries.map((entry) {
      return ChartData(
        label: entry.key,
        value: entry.value.toDouble(),
      );
    }).toList();
  }

  /// Convert rejection reasons to chart data
  static List<ChartData> prepareRejectionReasonsChartData(
    List<RejectionReason> rejectionReasons,
    ChartType chartType,
  ) {
    return rejectionReasons.map((reason) {
      return ChartData(
        label: reason.reason,
        value: reason.count.toDouble(),
      );
    }).toList();
  }

  /// Prepare chart data with custom colors
  static List<ChartData> prepareChartDataWithColors(
    List<ChartData> data,
    List<Color> colors,
  ) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final chartData = entry.value;
      final color = colors[index % colors.length];

      return ChartData(
        label: chartData.label,
        value: chartData.value,
        color: color,
        timestamp: chartData.timestamp,
      );
    }).toList();
  }

  /// Filter chart data based on criteria
  static List<ChartData> filterChartData(
    List<ChartData> data,
    AnalyticsFilter filter,
  ) {
    List<ChartData> filteredData = List.from(data);

    // Filter by date range if timestamp is available
    if (filter.dateRange != null) {
      filteredData = filteredData.where((item) {
        if (item.timestamp == null) return true;
        return item.timestamp!.isAfter(filter.dateRange!.startDate) &&
               item.timestamp!.isBefore(filter.dateRange!.endDate);
      }).toList();
    }

    return filteredData;
  }

  /// Sort chart data by value
  static List<ChartData> sortChartData(
    List<ChartData> data,
    {bool ascending = false}
  ) {
    final sortedData = List<ChartData>.from(data);
    sortedData.sort((a, b) {
      return ascending 
          ? a.value.compareTo(b.value)
          : b.value.compareTo(a.value);
    });
    return sortedData;
  }

  /// Limit chart data to top N items
  static List<ChartData> limitChartData(
    List<ChartData> data,
    int limit,
  ) {
    if (data.length <= limit) return data;
    
    final sortedData = sortChartData(data, ascending: false);
    final topItems = sortedData.take(limit - 1).toList();
    
    // Combine remaining items into "Others"
    final remainingSum = sortedData
        .skip(limit - 1)
        .fold<double>(0, (sum, item) => sum + item.value);
    
    if (remainingSum > 0) {
      topItems.add(ChartData(
        label: 'Others',
        value: remainingSum,
      ));
    }
    
    return topItems;
  }

  /// Calculate percentages for chart data
  static List<ChartData> calculatePercentages(List<ChartData> data) {
    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    if (total == 0) return data;

    return data.map((item) {
      final percentage = (item.value / total) * 100;
      return ChartData(
        label: item.label,
        value: percentage,
        color: item.color,
        timestamp: item.timestamp,
      );
    }).toList();
  }

  // Private helper methods

  static List<ChartData> _prepareStatusBarData(AnalyticsData analyticsData) {
    return [
      ChartData(
        label: 'Pending',
        value: analyticsData.pendingRequests.toDouble(),
        color: Colors.orange,
      ),
      ChartData(
        label: 'Approved',
        value: analyticsData.approvedRequests.toDouble(),
        color: Colors.green,
      ),
      ChartData(
        label: 'Rejected',
        value: analyticsData.rejectedRequests.toDouble(),
        color: Colors.red,
      ),
    ];
  }

  static List<ChartData> _prepareDepartmentBarData(
    Map<String, DepartmentAnalytics> departmentAnalytics,
  ) {
    return departmentAnalytics.entries.map((entry) {
      return ChartData(
        label: entry.key,
        value: entry.value.totalRequests.toDouble(),
      );
    }).toList();
  }

  static List<ChartData> _prepareDepartmentPieData(
    Map<String, DepartmentAnalytics> departmentAnalytics,
  ) {
    return departmentAnalytics.entries.map((entry) {
      return ChartData(
        label: entry.key,
        value: entry.value.totalRequests.toDouble(),
      );
    }).toList();
  }

  static List<ChartData> _prepareTrendLineData(TrendData trendData) {
    return trendData.dataPoints.map((point) {
      return ChartData(
        label: _formatTimestamp(point.timestamp),
        value: point.value,
        timestamp: point.timestamp,
      );
    }).toList();
  }

  static String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.month}/${timestamp.day}';
  }

  static int _getMonthOrder(String monthName) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months.indexOf(monthName);
  }
}