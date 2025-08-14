import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/charts/bar_chart_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/charts/line_chart_widget.dart';
import 'package:odtrack_academia/features/analytics/presentation/widgets/charts/pie_chart_widget.dart';

void main() {
  group('Chart Widgets', () {
    late List<ChartData> mockChartData;

    setUp(() {
      mockChartData = [
        const ChartData(label: 'Approved', value: 70, color: Colors.green),
        const ChartData(label: 'Pending', value: 20, color: Colors.orange),
        const ChartData(label: 'Rejected', value: 10, color: Colors.red),
      ];
    });

    group('AnalyticsBarChart', () {
      testWidgets('should display bar chart with data', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalyticsBarChart(
                data: mockChartData,
                title: 'Test Bar Chart',
              ),
            ),
          ),
        );

        expect(find.text('Test Bar Chart'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should display loading state', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AnalyticsBarChart(
                data: [],
                title: 'Loading Chart',
                isLoading: true,
              ),
            ),
          ),
        );

        expect(find.text('Loading Chart'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display error state', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AnalyticsBarChart(
                data: [],
                title: 'Error Chart',
                error: 'Failed to load data',
              ),
            ),
          ),
        );

        expect(find.text('Error Chart'), findsOneWidget);
        expect(find.text('Failed to load data'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should display empty state when no data', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AnalyticsBarChart(
                data: [],
                title: 'Empty Chart',
              ),
            ),
          ),
        );

        expect(find.text('Empty Chart'), findsOneWidget);
        expect(find.text('No data available'), findsOneWidget);
        expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);
      });

      testWidgets('should show refresh button when onRefresh is provided', (WidgetTester tester) async {
        bool refreshCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalyticsBarChart(
                data: mockChartData,
                title: 'Refreshable Chart',
                onRefresh: () => refreshCalled = true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.refresh), findsOneWidget);

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        expect(refreshCalled, isTrue);
      });
    });

    group('AnalyticsLineChart', () {
      testWidgets('should display line chart with data', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalyticsLineChart(
                data: mockChartData,
                title: 'Test Line Chart',
              ),
            ),
          ),
        );

        expect(find.text('Test Line Chart'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should display loading state', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AnalyticsLineChart(
                data: [],
                title: 'Loading Line Chart',
                isLoading: true,
              ),
            ),
          ),
        );

        expect(find.text('Loading Line Chart'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display error state with retry button', (WidgetTester tester) async {
        bool retryCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalyticsLineChart(
                data: const [],
                title: 'Error Line Chart',
                error: 'Network error',
                onRefresh: () => retryCalled = true,
              ),
            ),
          ),
        );

        expect(find.text('Error Line Chart'), findsOneWidget);
        expect(find.text('Network error'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        await tester.pump();

        expect(retryCalled, isTrue);
      });

      testWidgets('should handle different configuration options', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalyticsLineChart(
                data: mockChartData,
                title: 'Configured Line Chart',
                showDots: false,
                showArea: true,
                showGrid: false,
              ),
            ),
          ),
        );

        expect(find.text('Configured Line Chart'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('AnalyticsPieChart', () {
      testWidgets('should display pie chart with data', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalyticsPieChart(
                data: mockChartData,
                title: 'Test Pie Chart',
              ),
            ),
          ),
        );

        expect(find.text('Test Pie Chart'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should display legend when enabled', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalyticsPieChart(
                data: mockChartData,
                title: 'Pie Chart with Legend',
                showLegend: true,
                showLegendBelowChart: true,
              ),
            ),
          ),
        );

        expect(find.text('Pie Chart with Legend'), findsOneWidget);
        expect(find.text('Legend'), findsOneWidget);
        expect(find.text('Approved'), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('Rejected'), findsOneWidget);
      });

      testWidgets('should display empty state for pie chart', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AnalyticsPieChart(
                data: [],
                title: 'Empty Pie Chart',
              ),
            ),
          ),
        );

        expect(find.text('Empty Pie Chart'), findsOneWidget);
        expect(find.text('No data available'), findsOneWidget);
        expect(find.byIcon(Icons.pie_chart_outline), findsOneWidget);
      });

      testWidgets('should handle different configuration options', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalyticsPieChart(
                data: mockChartData,
                title: 'Configured Pie Chart',
                showPercentages: false,
                showValues: true,
                centerSpaceRadius: 60,
                showLegendBelowChart: false,
              ),
            ),
          ),
        );

        expect(find.text('Configured Pie Chart'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Chart Data Formatting', () {
      testWidgets('should format large values correctly in bar chart', (WidgetTester tester) async {
        final largeValueData = [
          const ChartData(label: 'Large', value: 1500000),
          const ChartData(label: 'Medium', value: 2500),
          const ChartData(label: 'Small', value: 15),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalyticsBarChart(
                data: largeValueData,
                title: 'Large Values Chart',
              ),
            ),
          ),
        );

        expect(find.text('Large Values Chart'), findsOneWidget);
        // The chart should handle large values without overflow
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should handle decimal values correctly', (WidgetTester tester) async {
        final decimalData = [
          const ChartData(label: 'A', value: 10.5),
          const ChartData(label: 'B', value: 20.75),
          const ChartData(label: 'C', value: 5.25),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalyticsLineChart(
                data: decimalData,
                title: 'Decimal Values Chart',
              ),
            ),
          ),
        );

        expect(find.text('Decimal Values Chart'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Chart Interactions', () {
      testWidgets('should handle refresh action correctly', (WidgetTester tester) async {
        int refreshCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalyticsBarChart(
                data: mockChartData,
                title: 'Interactive Chart',
                onRefresh: () => refreshCount++,
              ),
            ),
          ),
        );

        // Tap refresh button multiple times
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        expect(refreshCount, equals(2));
      });

      testWidgets('should disable refresh button when loading', (WidgetTester tester) async {
        bool refreshCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnalyticsBarChart(
                data: const [],
                title: 'Loading Chart',
                isLoading: true,
                onRefresh: () => refreshCalled = true,
              ),
            ),
          ),
        );

        // Try to tap refresh button while loading
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        // Refresh should not be called when loading
        expect(refreshCalled, isFalse);
      });
    });
  });
}