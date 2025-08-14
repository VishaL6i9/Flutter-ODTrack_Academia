import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/features/analytics/presentation/services/chart_data_service.dart';

void main() {
  group('ChartDataService', () {
    late AnalyticsData mockAnalyticsData;
    late Map<String, DepartmentAnalytics> mockDepartmentAnalytics;
    late List<TrendData> mockTrendData;

    setUp(() {
      mockAnalyticsData = const AnalyticsData(
        totalRequests: 100,
        approvedRequests: 70,
        rejectedRequests: 20,
        pendingRequests: 10,
        approvalRate: 70.0,
        requestsByMonth: {
          'Jan': 15,
          'Feb': 20,
          'Mar': 25,
          'Apr': 18,
          'May': 22,
        },
        requestsByDepartment: {
          'CS': 40,
          'ECE': 30,
          'ME': 20,
          'CE': 10,
        },
        topRejectionReasons: [
          RejectionReason(reason: 'Insufficient documentation', count: 8, percentage: 40.0),
          RejectionReason(reason: 'Invalid dates', count: 6, percentage: 30.0),
          RejectionReason(reason: 'Duplicate request', count: 4, percentage: 20.0),
          RejectionReason(reason: 'Other', count: 2, percentage: 10.0),
        ],
        patterns: [],
      );

      mockDepartmentAnalytics = {
        'CS': const DepartmentAnalytics(
          departmentName: 'Computer Science',
          totalRequests: 40,
          approvalRate: 75.0,
          requestsByStatus: {'Approved': 30, 'Rejected': 8, 'Pending': 2},
          topStudents: ['student1', 'student2'],
        ),
        'ECE': const DepartmentAnalytics(
          departmentName: 'Electronics',
          totalRequests: 30,
          approvalRate: 80.0,
          requestsByStatus: {'Approved': 24, 'Rejected': 4, 'Pending': 2},
          topStudents: ['student3', 'student4'],
        ),
      };

      mockTrendData = [
        TrendData(
          label: 'Weekly Requests',
          dataPoints: [
            DataPoint(timestamp: DateTime(2024, 1, 1), value: 10),
            DataPoint(timestamp: DateTime(2024, 1, 8), value: 15),
            DataPoint(timestamp: DateTime(2024, 1, 15), value: 12),
            DataPoint(timestamp: DateTime(2024, 1, 22), value: 18),
          ],
          direction: TrendDirection.up,
          changePercentage: 25.5,
        ),
      ];
    });

    group('prepareBarChartData', () {
      test('should prepare status bar chart data correctly', () {
        final result = ChartDataService.prepareBarChartData(
          mockAnalyticsData,
          ChartType.bar,
        );

        expect(result, hasLength(3));
        expect(result[0].label, equals('Pending'));
        expect(result[0].value, equals(10.0));
        expect(result[0].color, equals(Colors.orange));
        
        expect(result[1].label, equals('Approved'));
        expect(result[1].value, equals(70.0));
        expect(result[1].color, equals(Colors.green));
        
        expect(result[2].label, equals('Rejected'));
        expect(result[2].value, equals(20.0));
        expect(result[2].color, equals(Colors.red));
      });

      test('should return empty list for unsupported chart type', () {
        final result = ChartDataService.prepareBarChartData(
          mockAnalyticsData,
          ChartType.pie,
        );

        expect(result, isEmpty);
      });
    });

    group('prepareDepartmentChartData', () {
      test('should prepare department bar chart data correctly', () {
        final result = ChartDataService.prepareDepartmentChartData(
          mockDepartmentAnalytics,
          ChartType.bar,
        );

        expect(result, hasLength(2));
        expect(result.any((item) => item.label == 'CS' && item.value == 40.0), isTrue);
        expect(result.any((item) => item.label == 'ECE' && item.value == 30.0), isTrue);
      });

      test('should prepare department pie chart data correctly', () {
        final result = ChartDataService.prepareDepartmentChartData(
          mockDepartmentAnalytics,
          ChartType.pie,
        );

        expect(result, hasLength(2));
        expect(result.any((item) => item.label == 'CS' && item.value == 40.0), isTrue);
        expect(result.any((item) => item.label == 'ECE' && item.value == 30.0), isTrue);
      });
    });

    group('prepareTrendChartData', () {
      test('should prepare trend line chart data correctly', () {
        final result = ChartDataService.prepareTrendChartData(
          mockTrendData,
          ChartType.line,
        );

        expect(result, hasLength(4));
        expect(result[0].value, equals(10.0));
        expect(result[1].value, equals(15.0));
        expect(result[2].value, equals(12.0));
        expect(result[3].value, equals(18.0));
        
        // Check that timestamps are preserved
        expect(result[0].timestamp, equals(DateTime(2024, 1, 1)));
        expect(result[3].timestamp, equals(DateTime(2024, 1, 22)));
      });

      test('should return empty list for empty trend data', () {
        final result = ChartDataService.prepareTrendChartData(
          [],
          ChartType.line,
        );

        expect(result, isEmpty);
      });
    });

    group('prepareMonthlyChartData', () {
      test('should prepare monthly chart data in correct order', () {
        final result = ChartDataService.prepareMonthlyChartData(
          mockAnalyticsData.requestsByMonth,
          ChartType.bar,
        );

        expect(result, hasLength(5));
        expect(result[0].label, equals('Jan'));
        expect(result[0].value, equals(15.0));
        expect(result[1].label, equals('Feb'));
        expect(result[1].value, equals(20.0));
        expect(result[4].label, equals('May'));
        expect(result[4].value, equals(22.0));
      });
    });

    group('prepareRejectionReasonsChartData', () {
      test('should prepare rejection reasons chart data correctly', () {
        final result = ChartDataService.prepareRejectionReasonsChartData(
          mockAnalyticsData.topRejectionReasons,
          ChartType.pie,
        );

        expect(result, hasLength(4));
        expect(result[0].label, equals('Insufficient documentation'));
        expect(result[0].value, equals(8.0));
        expect(result[1].label, equals('Invalid dates'));
        expect(result[1].value, equals(6.0));
      });
    });

    group('prepareChartDataWithColors', () {
      test('should assign colors to chart data correctly', () {
        final data = [
          const ChartData(label: 'A', value: 10),
          const ChartData(label: 'B', value: 20),
          const ChartData(label: 'C', value: 30),
        ];
        final colors = [Colors.red, Colors.green, Colors.blue];

        final result = ChartDataService.prepareChartDataWithColors(data, colors);

        expect(result, hasLength(3));
        expect(result[0].color, equals(Colors.red));
        expect(result[1].color, equals(Colors.green));
        expect(result[2].color, equals(Colors.blue));
      });

      test('should cycle colors when data length exceeds colors length', () {
        final data = [
          const ChartData(label: 'A', value: 10),
          const ChartData(label: 'B', value: 20),
          const ChartData(label: 'C', value: 30),
          const ChartData(label: 'D', value: 40),
        ];
        final colors = [Colors.red, Colors.green];

        final result = ChartDataService.prepareChartDataWithColors(data, colors);

        expect(result, hasLength(4));
        expect(result[0].color, equals(Colors.red));
        expect(result[1].color, equals(Colors.green));
        expect(result[2].color, equals(Colors.red)); // Cycles back
        expect(result[3].color, equals(Colors.green)); // Cycles back
      });
    });

    group('filterChartData', () {
      test('should filter chart data by date range', () {
        final data = [
          ChartData(
            label: 'A',
            value: 10,
            timestamp: DateTime(2024, 1, 5),
          ),
          ChartData(
            label: 'B',
            value: 20,
            timestamp: DateTime(2024, 1, 15),
          ),
          ChartData(
            label: 'C',
            value: 30,
            timestamp: DateTime(2024, 1, 25),
          ),
        ];

        final filter = AnalyticsFilter(
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 10),
            endDate: DateTime(2024, 1, 20),
          ),
        );

        final result = ChartDataService.filterChartData(data, filter);

        expect(result, hasLength(1));
        expect(result[0].label, equals('B'));
      });

      test('should return all data when no date filter is applied', () {
        final data = [
          const ChartData(label: 'A', value: 10),
          const ChartData(label: 'B', value: 20),
          const ChartData(label: 'C', value: 30),
        ];

        const filter = AnalyticsFilter();

        final result = ChartDataService.filterChartData(data, filter);

        expect(result, hasLength(3));
      });
    });

    group('sortChartData', () {
      test('should sort chart data in descending order by default', () {
        final data = [
          const ChartData(label: 'A', value: 10),
          const ChartData(label: 'B', value: 30),
          const ChartData(label: 'C', value: 20),
        ];

        final result = ChartDataService.sortChartData(data);

        expect(result, hasLength(3));
        expect(result[0].value, equals(30.0));
        expect(result[1].value, equals(20.0));
        expect(result[2].value, equals(10.0));
      });

      test('should sort chart data in ascending order when specified', () {
        final data = [
          const ChartData(label: 'A', value: 10),
          const ChartData(label: 'B', value: 30),
          const ChartData(label: 'C', value: 20),
        ];

        final result = ChartDataService.sortChartData(data, ascending: true);

        expect(result, hasLength(3));
        expect(result[0].value, equals(10.0));
        expect(result[1].value, equals(20.0));
        expect(result[2].value, equals(30.0));
      });
    });

    group('limitChartData', () {
      test('should limit chart data and create "Others" category', () {
        final data = [
          const ChartData(label: 'A', value: 30),
          const ChartData(label: 'B', value: 20),
          const ChartData(label: 'C', value: 15),
          const ChartData(label: 'D', value: 10),
          const ChartData(label: 'E', value: 5),
        ];

        final result = ChartDataService.limitChartData(data, 3);

        expect(result, hasLength(3));
        expect(result[0].label, equals('A'));
        expect(result[0].value, equals(30.0));
        expect(result[1].label, equals('B'));
        expect(result[1].value, equals(20.0));
        expect(result[2].label, equals('Others'));
        expect(result[2].value, equals(30.0)); // 15 + 10 + 5
      });

      test('should return original data when limit is greater than data length', () {
        final data = [
          const ChartData(label: 'A', value: 30),
          const ChartData(label: 'B', value: 20),
        ];

        final result = ChartDataService.limitChartData(data, 5);

        expect(result, hasLength(2));
        expect(result[0].label, equals('A'));
        expect(result[1].label, equals('B'));
      });
    });

    group('calculatePercentages', () {
      test('should calculate percentages correctly', () {
        final data = [
          const ChartData(label: 'A', value: 30),
          const ChartData(label: 'B', value: 20),
          const ChartData(label: 'C', value: 50),
        ];

        final result = ChartDataService.calculatePercentages(data);

        expect(result, hasLength(3));
        expect(result[0].value, equals(30.0)); // 30/100 * 100
        expect(result[1].value, equals(20.0)); // 20/100 * 100
        expect(result[2].value, equals(50.0)); // 50/100 * 100
      });

      test('should return original data when total is zero', () {
        final data = [
          const ChartData(label: 'A', value: 0),
          const ChartData(label: 'B', value: 0),
        ];

        final result = ChartDataService.calculatePercentages(data);

        expect(result, hasLength(2));
        expect(result[0].value, equals(0.0));
        expect(result[1].value, equals(0.0));
      });
    });
  });
}