import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/user.dart';
import 'package:odtrack_academia/services/analytics/hive_analytics_service.dart';
import 'package:odtrack_academia/core/storage/enhanced_storage_manager.dart';

import 'hive_analytics_service_test.mocks.dart';

@GenerateMocks([EnhancedStorageManager, Box])
void main() {
  group('HiveAnalyticsService', () {
    late HiveAnalyticsService analyticsService;
    late MockEnhancedStorageManager mockStorageManager;
    late MockBox<ODRequest> mockODRequestsBox;
    late MockBox<User> mockUsersBox;
    
    // Test data
    final testUsers = [
      const User(
        id: 'student1',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'student',
        department: 'Computer Science',
        year: '2024',
        registerNumber: 'CS001',
      ),
      const User(
        id: 'student2',
        name: 'Jane Smith',
        email: 'jane@example.com',
        role: 'student',
        department: 'Electronics',
        year: '2024',
        registerNumber: 'EC001',
      ),
      const User(
        id: 'staff1',
        name: 'Dr. Wilson',
        email: 'wilson@example.com',
        role: 'staff',
        department: 'Computer Science',
      ),
    ];
    
    final testRequests = [
      ODRequest(
        id: 'req1',
        studentId: 'student1',
        studentName: 'John Doe',
        registerNumber: 'CS001',
        date: DateTime(2024, 1, 15),
        periods: [1, 2],
        reason: 'Medical appointment',
        status: 'approved',
        createdAt: DateTime(2024, 1, 10),
        approvedAt: DateTime(2024, 1, 11),
        approvedBy: 'staff1',
      ),
      ODRequest(
        id: 'req2',
        studentId: 'student1',
        studentName: 'John Doe',
        registerNumber: 'CS001',
        date: DateTime(2024, 1, 20),
        periods: [3, 4],
        reason: 'Family function',
        status: 'rejected',
        createdAt: DateTime(2024, 1, 15),
        rejectionReason: 'Insufficient notice',
        staffId: 'staff1',
      ),
      ODRequest(
        id: 'req3',
        studentId: 'student2',
        studentName: 'Jane Smith',
        registerNumber: 'EC001',
        date: DateTime(2024, 1, 25),
        periods: [1, 2, 3],
        reason: 'Medical appointment',
        status: 'pending',
        createdAt: DateTime(2024, 1, 20),
      ),
      ODRequest(
        id: 'req4',
        studentId: 'student2',
        studentName: 'Jane Smith',
        registerNumber: 'EC001',
        date: DateTime(2024, 2, 5),
        periods: [2, 3],
        reason: 'Personal work',
        status: 'approved',
        createdAt: DateTime(2024, 2, 1),
        approvedAt: DateTime(2024, 2, 2),
        approvedBy: 'staff1',
      ),
    ];
    
    setUp(() {
      mockStorageManager = MockEnhancedStorageManager();
      mockODRequestsBox = MockBox<ODRequest>();
      mockUsersBox = MockBox<User>();
      
      analyticsService = HiveAnalyticsService(mockStorageManager);
      
      // Setup Hive mocks
      when(mockODRequestsBox.values).thenReturn(testRequests);
      when(mockUsersBox.values).thenReturn(testUsers);
      
      // Mock user lookups
      for (final user in testUsers) {
        when(mockUsersBox.get(user.id)).thenReturn(user);
      }
      
      // Mock storage manager
      when(mockStorageManager.initialize()).thenAnswer((_) async {});
      when(mockStorageManager.getCachedData(any)).thenAnswer((_) async => null);
      when(mockStorageManager.cacheData(any, any, ttl: anyNamed('ttl')))
          .thenAnswer((_) async {});
    });
    
    group('initialization', () {
      test('should initialize successfully', () async {
        await analyticsService.initialize();
        verify(mockStorageManager.initialize()).called(1);
      });
    });
    
    group('getODRequestAnalytics', () {
      test('should return correct analytics data for date range', () async {
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        
        // Mock Hive box operations
        when(mockStorageManager.getCachedData(any)).thenAnswer((_) async => null);
        
        final result = await analyticsService.getODRequestAnalytics(dateRange);
        
        expect(result.totalRequests, equals(3)); // req1, req2, req3 in January
        expect(result.approvedRequests, equals(1)); // req1
        expect(result.rejectedRequests, equals(1)); // req2
        expect(result.pendingRequests, equals(1)); // req3
        expect(result.approvalRate, closeTo(33.33, 0.1)); // 1/3 * 100
        
        // Verify caching was called
        verify(mockStorageManager.cacheData(any, any, ttl: anyNamed('ttl')))
            .called(1);
      });
      
      test('should return cached data when available', () async {
        final cachedData = {
          'totalRequests': 5,
          'approvedRequests': 3,
          'rejectedRequests': 1,
          'pendingRequests': 1,
          'approvalRate': 60.0,
          'requestsByMonth': {'2024-01': 5},
          'requestsByDepartment': {'Computer Science': 3, 'Electronics': 2},
          'topRejectionReasons': <Map<String, dynamic>>[],
          'patterns': <Map<String, dynamic>>[],
        };
        
        when(mockStorageManager.getCachedData(any))
            .thenAnswer((_) async => cachedData);
        
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        
        final result = await analyticsService.getODRequestAnalytics(dateRange);
        
        expect(result.totalRequests, equals(5));
        expect(result.approvalRate, equals(60.0));
        
        // Verify cache was checked but not written to
        verify(mockStorageManager.getCachedData(any)).called(1);
        verifyNever(mockStorageManager.cacheData(any, any, ttl: anyNamed('ttl')));
      });
    });
    
    group('getDepartmentAnalytics', () {
      test('should return correct department analytics', () async {
        when(mockStorageManager.getCachedData(any)).thenAnswer((_) async => null);
        
        final result = await analyticsService.getDepartmentAnalytics('Computer Science');
        
        expect(result.departmentName, equals('Computer Science'));
        expect(result.totalRequests, equals(2)); // req1, req2 from student1
        expect(result.approvalRate, closeTo(50.0, 0.1)); // 1 approved out of 2
        expect(result.requestsByStatus['approved'], equals(1));
        expect(result.requestsByStatus['rejected'], equals(1));
        expect(result.requestsByStatus['pending'], equals(0));
        expect(result.topStudents, contains('student1'));
      });
      
      test('should handle empty department', () async {
        when(mockStorageManager.getCachedData(any)).thenAnswer((_) async => null);
        
        final result = await analyticsService.getDepartmentAnalytics('Non-existent Department');
        
        expect(result.departmentName, equals('Non-existent Department'));
        expect(result.totalRequests, equals(0));
        expect(result.approvalRate, equals(0.0));
        expect(result.topStudents, isEmpty);
      });
    });
    
    group('getStudentAnalytics', () {
      test('should return correct student analytics', () async {
        when(mockStorageManager.getCachedData(any)).thenAnswer((_) async => null);
        
        final result = await analyticsService.getStudentAnalytics('student1');
        
        expect(result.studentId, equals('student1'));
        expect(result.studentName, equals('John Doe'));
        expect(result.totalRequests, equals(2)); // req1, req2
        expect(result.approvedRequests, equals(1)); // req1
        expect(result.rejectedRequests, equals(1)); // req2
        expect(result.approvalRate, closeTo(50.0, 0.1));
        expect(result.frequentReasons, contains('Medical appointment'));
        expect(result.frequentReasons, contains('Family function'));
      });
      
      test('should handle non-existent student', () async {
        when(mockStorageManager.getCachedData(any)).thenAnswer((_) async => null);
        when(mockUsersBox.get('non-existent')).thenReturn(null);
        
        final result = await analyticsService.getStudentAnalytics('non-existent');
        
        expect(result.studentId, equals('non-existent'));
        expect(result.studentName, equals('Unknown Student'));
        expect(result.totalRequests, equals(0));
        expect(result.approvalRate, equals(0.0));
      });
    });
    
    group('getStaffAnalytics', () {
      test('should return correct staff analytics', () async {
        when(mockStorageManager.getCachedData(any)).thenAnswer((_) async => null);
        
        final result = await analyticsService.getStaffAnalytics('staff1');
        
        expect(result.staffId, equals('staff1'));
        expect(result.staffName, equals('Dr. Wilson'));
        expect(result.requestsProcessed, equals(3)); // req1, req2, req4
        expect(result.requestsApproved, equals(2)); // req1, req4
        expect(result.requestsRejected, equals(1)); // req2
        expect(result.averageProcessingTime, greaterThan(0));
        expect(result.commonRejectionReasons, contains('Insufficient notice'));
      });
    });
    
    group('getTrendAnalysis', () {
      test('should return request trends', () async {
        when(mockStorageManager.getCachedData(any)).thenAnswer((_) async => null);
        
        final result = await analyticsService.getTrendAnalysis(AnalyticsType.requests);
        
        expect(result, isNotEmpty);
        expect(result.first.label, equals('Weekly Request Volume'));
        expect(result.first.dataPoints, isNotEmpty);
        expect(result.first.direction, isA<TrendDirection>());
      });
      
      test('should return approval trends', () async {
        when(mockStorageManager.getCachedData(any)).thenAnswer((_) async => null);
        
        final result = await analyticsService.getTrendAnalysis(AnalyticsType.approvals);
        
        expect(result, isNotEmpty);
        expect(result.first.label, equals('Monthly Approval Rate'));
        expect(result.first.dataPoints, isNotEmpty);
      });
      
      test('should return cached trend data when available', () async {
        final cachedTrends = <String, dynamic>{
          'trends': <Map<String, dynamic>>[
            <String, dynamic>{
              'label': 'Test Trend',
              'dataPoints': <Map<String, dynamic>>[
                <String, dynamic>{'timestamp': DateTime.now().toIso8601String(), 'value': 10.0}
              ],
              'direction': 'up',
              'changePercentage': 5.0,
            }
          ]
        };
        
        when(mockStorageManager.getCachedData(any))
            .thenAnswer((_) async => cachedTrends);
        
        final result = await analyticsService.getTrendAnalysis(AnalyticsType.requests);
        
        expect(result, hasLength(1));
        expect(result.first.label, equals('Test Trend'));
        expect(result.first.direction, equals(TrendDirection.up));
      });
    });
    
    group('getChartData', () {
      test('should return bar chart data', () async {
        const filter = AnalyticsFilter();
        
        final result = await analyticsService.getChartData(ChartType.bar, filter);
        
        expect(result, hasLength(3)); // Approved, Rejected, Pending
        expect(result.map((d) => d.label), containsAll(['Approved', 'Rejected', 'Pending']));
        
        final approvedData = result.firstWhere((d) => d.label == 'Approved');
        expect(approvedData.value, equals(2.0)); // req1, req4
        
        final rejectedData = result.firstWhere((d) => d.label == 'Rejected');
        expect(rejectedData.value, equals(1.0)); // req2
        
        final pendingData = result.firstWhere((d) => d.label == 'Pending');
        expect(pendingData.value, equals(1.0)); // req3
      });
      
      test('should return pie chart data', () async {
        const filter = AnalyticsFilter();
        
        final result = await analyticsService.getChartData(ChartType.pie, filter);
        
        expect(result, isNotEmpty);
        expect(result.map((d) => d.label), contains('Medical appointment'));
        
        final medicalData = result.firstWhere((d) => d.label == 'Medical appointment');
        expect(medicalData.value, equals(2.0)); // req1, req3
      });
      
      test('should apply date range filter', () async {
        final filter = AnalyticsFilter(
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
        );
        
        final result = await analyticsService.getChartData(ChartType.bar, filter);
        
        final approvedData = result.firstWhere((d) => d.label == 'Approved');
        expect(approvedData.value, equals(1.0)); // Only req1 in January
      });
      
      test('should apply department filter', () async {
        const filter = AnalyticsFilter(department: 'Computer Science');
        
        final result = await analyticsService.getChartData(ChartType.bar, filter);
        
        final approvedData = result.firstWhere((d) => d.label == 'Approved');
        expect(approvedData.value, equals(1.0)); // Only req1 from CS student
      });
    });
    
    group('getApprovalRate', () {
      test('should calculate correct approval rate', () async {
        const filter = AnalyticsFilter();
        
        final result = await analyticsService.getApprovalRate(filter);
        
        expect(result, closeTo(50.0, 0.1)); // 2 approved out of 4 total
      });
      
      test('should return 0 for empty dataset', () async {
        when(mockODRequestsBox.values).thenReturn([]);
        
        const filter = AnalyticsFilter();
        final result = await analyticsService.getApprovalRate(filter);
        
        expect(result, equals(0.0));
      });
    });
    
    group('getRejectionReasonsStats', () {
      test('should return rejection reason statistics', () async {
        const filter = AnalyticsFilter();
        
        final result = await analyticsService.getRejectionReasonsStats(filter);
        
        expect(result, containsPair('Insufficient notice', 1));
      });
      
      test('should handle no rejections', () async {
        final approvedOnlyRequests = testRequests
            .where((r) => r.status == 'approved')
            .toList();
        when(mockODRequestsBox.values).thenReturn(approvedOnlyRequests);
        
        const filter = AnalyticsFilter();
        final result = await analyticsService.getRejectionReasonsStats(filter);
        
        expect(result, isEmpty);
      });
    });
    
    group('prepareAnalyticsForExport', () {
      test('should prepare export data correctly', () async {
        when(mockStorageManager.getCachedData(any)).thenAnswer((_) async => null);
        
        final filter = AnalyticsFilter(
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
        );
        
        final result = await analyticsService.prepareAnalyticsForExport(filter);
        
        expect(result.title, equals('OD Request Analytics Report'));
        expect(result.data, isNotEmpty);
        expect(result.chartData, isNotEmpty);
        expect(result.generatedAt, isA<DateTime>());
      });
    });
  });
}