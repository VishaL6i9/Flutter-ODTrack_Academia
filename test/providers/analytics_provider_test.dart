import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/providers/analytics_provider.dart';
import 'package:odtrack_academia/services/analytics/analytics_service.dart';

import 'analytics_provider_test.mocks.dart';

@GenerateMocks([AnalyticsService])
void main() {
  group('AnalyticsProvider', () {
    late MockAnalyticsService mockAnalyticsService;
    late ProviderContainer container;
    
    setUp(() {
      mockAnalyticsService = MockAnalyticsService();
      
      container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
        ],
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    group('AnalyticsNotifier', () {
      test('should initialize with empty state', () {
        final state = container.read(analyticsProvider);
        
        expect(state.analyticsData, isNull);
        expect(state.departmentAnalytics, isEmpty);
        expect(state.studentAnalytics, isEmpty);
        expect(state.staffAnalytics, isEmpty);
        expect(state.trendData, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
        expect(state.lastUpdated, isNull);
      });
      
      test('should initialize analytics service successfully', () async {
        when(mockAnalyticsService.initialize()).thenAnswer((_) async {});
        
        final notifier = container.read(analyticsProvider.notifier);
        await notifier.initialize();
        
        verify(mockAnalyticsService.initialize()).called(1);
        
        final state = container.read(analyticsProvider);
        expect(state.error, isNull);
      });
      
      test('should handle initialization error', () async {
        when(mockAnalyticsService.initialize()).thenThrow(Exception('Init failed'));
        
        final notifier = container.read(analyticsProvider.notifier);
        await notifier.initialize();
        
        final state = container.read(analyticsProvider);
        expect(state.error, contains('Failed to initialize analytics'));
      });
      
      test('should load OD request analytics successfully', () async {
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        
        const mockAnalyticsData = AnalyticsData(
          totalRequests: 10,
          approvedRequests: 7,
          rejectedRequests: 2,
          pendingRequests: 1,
          approvalRate: 70.0,
          requestsByMonth: {'2024-01': 10},
          requestsByDepartment: {'CS': 6, 'EC': 4},
          topRejectionReasons: [],
          patterns: [],
        );
        
        when(mockAnalyticsService.getODRequestAnalytics(dateRange))
            .thenAnswer((_) async => mockAnalyticsData);
        
        final notifier = container.read(analyticsProvider.notifier);
        await notifier.loadODRequestAnalytics(dateRange);
        
        verify(mockAnalyticsService.getODRequestAnalytics(dateRange)).called(1);
        
        final state = container.read(analyticsProvider);
        expect(state.analyticsData, equals(mockAnalyticsData));
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
        expect(state.lastUpdated, isNotNull);
      });
      
      test('should handle OD request analytics loading error', () async {
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        
        when(mockAnalyticsService.getODRequestAnalytics(dateRange))
            .thenThrow(Exception('Loading failed'));
        
        final notifier = container.read(analyticsProvider.notifier);
        await notifier.loadODRequestAnalytics(dateRange);
        
        final state = container.read(analyticsProvider);
        expect(state.analyticsData, isNull);
        expect(state.isLoading, isFalse);
        expect(state.error, contains('Failed to load analytics'));
      });
      
      test('should load department analytics successfully', () async {
        const department = 'Computer Science';
        const mockDepartmentAnalytics = DepartmentAnalytics(
          departmentName: department,
          totalRequests: 5,
          approvalRate: 80.0,
          requestsByStatus: {'approved': 4, 'rejected': 1},
          topStudents: ['student1', 'student2'],
        );
        
        when(mockAnalyticsService.getDepartmentAnalytics(department))
            .thenAnswer((_) async => mockDepartmentAnalytics);
        
        final notifier = container.read(analyticsProvider.notifier);
        await notifier.loadDepartmentAnalytics(department);
        
        verify(mockAnalyticsService.getDepartmentAnalytics(department)).called(1);
        
        final state = container.read(analyticsProvider);
        expect(state.departmentAnalytics[department], equals(mockDepartmentAnalytics));
        expect(state.error, isNull);
        expect(state.lastUpdated, isNotNull);
      });
      
      test('should load student analytics successfully', () async {
        const studentId = 'student1';
        const mockStudentAnalytics = StudentAnalytics(
          studentId: studentId,
          studentName: 'John Doe',
          totalRequests: 3,
          approvedRequests: 2,
          rejectedRequests: 1,
          approvalRate: 66.67,
          frequentReasons: ['Medical', 'Personal'],
        );
        
        when(mockAnalyticsService.getStudentAnalytics(studentId))
            .thenAnswer((_) async => mockStudentAnalytics);
        
        final notifier = container.read(analyticsProvider.notifier);
        await notifier.loadStudentAnalytics(studentId);
        
        verify(mockAnalyticsService.getStudentAnalytics(studentId)).called(1);
        
        final state = container.read(analyticsProvider);
        expect(state.studentAnalytics[studentId], equals(mockStudentAnalytics));
        expect(state.error, isNull);
      });
      
      test('should load staff analytics successfully', () async {
        const staffId = 'staff1';
        const mockStaffAnalytics = StaffAnalytics(
          staffId: staffId,
          staffName: 'Dr. Wilson',
          requestsProcessed: 10,
          requestsApproved: 8,
          requestsRejected: 2,
          averageProcessingTime: 24.5,
          commonRejectionReasons: ['Insufficient notice'],
        );
        
        when(mockAnalyticsService.getStaffAnalytics(staffId))
            .thenAnswer((_) async => mockStaffAnalytics);
        
        final notifier = container.read(analyticsProvider.notifier);
        await notifier.loadStaffAnalytics(staffId);
        
        verify(mockAnalyticsService.getStaffAnalytics(staffId)).called(1);
        
        final state = container.read(analyticsProvider);
        expect(state.staffAnalytics[staffId], equals(mockStaffAnalytics));
        expect(state.error, isNull);
      });
      
      test('should load trend analysis successfully', () async {
        const analyticsType = AnalyticsType.requests;
        final mockTrendData = [
          TrendData(
            label: 'Weekly Requests',
            dataPoints: [
              DataPoint(timestamp: DateTime(2024, 1, 1), value: 5.0),
              DataPoint(timestamp: DateTime(2024, 1, 8), value: 7.0),
            ],
            direction: TrendDirection.up,
            changePercentage: 40.0,
          ),
        ];
        
        when(mockAnalyticsService.getTrendAnalysis(analyticsType))
            .thenAnswer((_) async => mockTrendData);
        
        final notifier = container.read(analyticsProvider.notifier);
        await notifier.loadTrendAnalysis(analyticsType);
        
        verify(mockAnalyticsService.getTrendAnalysis(analyticsType)).called(1);
        
        final state = container.read(analyticsProvider);
        expect(state.trendData[analyticsType], equals(mockTrendData));
        expect(state.error, isNull);
      });
      
      test('should get chart data successfully', () async {
        const chartType = ChartType.bar;
        const filter = AnalyticsFilter();
        const mockChartData = [
          ChartData(label: 'Approved', value: 5.0),
          ChartData(label: 'Rejected', value: 2.0),
        ];
        
        when(mockAnalyticsService.getChartData(chartType, filter))
            .thenAnswer((_) async => mockChartData);
        
        final notifier = container.read(analyticsProvider.notifier);
        final result = await notifier.getChartData(chartType, filter);
        
        verify(mockAnalyticsService.getChartData(chartType, filter)).called(1);
        expect(result, equals(mockChartData));
      });
      
      test('should get approval rate successfully', () async {
        const filter = AnalyticsFilter();
        const mockApprovalRate = 75.5;
        
        when(mockAnalyticsService.getApprovalRate(filter))
            .thenAnswer((_) async => mockApprovalRate);
        
        final notifier = container.read(analyticsProvider.notifier);
        final result = await notifier.getApprovalRate(filter);
        
        verify(mockAnalyticsService.getApprovalRate(filter)).called(1);
        expect(result, equals(mockApprovalRate));
      });
      
      test('should refresh analytics cache successfully', () async {
        when(mockAnalyticsService.refreshAnalyticsCache()).thenAnswer((_) async {});
        
        final notifier = container.read(analyticsProvider.notifier);
        await notifier.refreshAnalyticsCache();
        
        verify(mockAnalyticsService.refreshAnalyticsCache()).called(1);
        
        final state = container.read(analyticsProvider);
        expect(state.analyticsData, isNull);
        expect(state.departmentAnalytics, isEmpty);
        expect(state.studentAnalytics, isEmpty);
        expect(state.staffAnalytics, isEmpty);
        expect(state.trendData, isEmpty);
        expect(state.lastUpdated, isNotNull);
      });
      
      test('should clear error state', () async {
        // First set an error
        when(mockAnalyticsService.initialize()).thenThrow(Exception('Test error'));
        
        final notifier = container.read(analyticsProvider.notifier);
        await notifier.initialize();
        
        var state = container.read(analyticsProvider);
        expect(state.error, isNotNull);
        
        // Clear the error
        notifier.clearError();
        
        state = container.read(analyticsProvider);
        expect(state.error, isNull);
      });
      
      test('should check if data needs refresh correctly', () {
        final notifier = container.read(analyticsProvider.notifier);
        
        // Initially should need refresh (no last updated time)
        expect(notifier.needsRefresh, isTrue);
        
        // After loading data, should not need refresh immediately
        // This would be tested in integration tests with actual time manipulation
      });
    });
    
    group('Convenience Providers', () {
      test('should provide current analytics data', () {
        final analyticsData = container.read(currentAnalyticsDataProvider);
        expect(analyticsData, isNull); // Initially null
      });
      
      test('should provide loading state', () {
        final isLoading = container.read(analyticsLoadingProvider);
        expect(isLoading, isFalse); // Initially false
      });
      
      test('should provide error state', () {
        final error = container.read(analyticsErrorProvider);
        expect(error, isNull); // Initially null
      });
      
      test('should provide last updated time', () {
        final lastUpdated = container.read(analyticsLastUpdatedProvider);
        expect(lastUpdated, isNull); // Initially null
      });
      
      test('should provide needs refresh state', () {
        final needsRefresh = container.read(analyticsNeedsRefreshProvider);
        expect(needsRefresh, isTrue); // Initially true
      });
    });
  });
}