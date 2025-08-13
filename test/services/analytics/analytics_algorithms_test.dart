import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/user.dart';
import 'package:odtrack_academia/services/analytics/hive_analytics_service.dart';

import 'hive_analytics_service_test.mocks.dart';

void main() {
  group('Analytics Algorithms', () {
    late HiveAnalyticsService analyticsService;
    late MockEnhancedStorageManager mockStorageManager;
    late MockBox<ODRequest> mockODRequestsBox;
    late MockBox<User> mockUsersBox;
    
    setUp(() {
      mockStorageManager = MockEnhancedStorageManager();
      mockODRequestsBox = MockBox<ODRequest>();
      mockUsersBox = MockBox<User>();
      
      analyticsService = HiveAnalyticsService(mockStorageManager);
      
      when(mockStorageManager.initialize()).thenAnswer((_) async {});
      when(mockStorageManager.getCachedData(any)).thenAnswer((_) async => null);
      when(mockStorageManager.cacheData(any, any, ttl: anyNamed('ttl')))
          .thenAnswer((_) async {});
    });
    
    group('Pattern Recognition', () {
      test('should identify peak request days', () async {
        // Create requests with Monday being the peak day
        final requests = [
          // Monday requests (weekday = 1)
          ODRequest(
            id: 'req1',
            studentId: 'student1',
            studentName: 'John Doe',
            registerNumber: 'CS001',
            date: DateTime(2024, 1, 15), // Monday
            periods: [1, 2],
            reason: 'Medical',
            status: 'approved',
            createdAt: DateTime(2024, 1, 15), // Monday
          ),
          ODRequest(
            id: 'req2',
            studentId: 'student2',
            studentName: 'Jane Smith',
            registerNumber: 'CS002',
            date: DateTime(2024, 1, 22), // Monday
            periods: [1, 2],
            reason: 'Personal',
            status: 'approved',
            createdAt: DateTime(2024, 1, 22), // Monday
          ),
          ODRequest(
            id: 'req3',
            studentId: 'student3',
            studentName: 'Bob Wilson',
            registerNumber: 'CS003',
            date: DateTime(2024, 1, 29), // Monday
            periods: [1, 2],
            reason: 'Family',
            status: 'approved',
            createdAt: DateTime(2024, 1, 29), // Monday
          ),
          // Tuesday request (weekday = 2)
          ODRequest(
            id: 'req4',
            studentId: 'student4',
            studentName: 'Alice Brown',
            registerNumber: 'CS004',
            date: DateTime(2024, 1, 16), // Tuesday
            periods: [1, 2],
            reason: 'Medical',
            status: 'approved',
            createdAt: DateTime(2024, 1, 16), // Tuesday
          ),
        ];
        
        when(mockODRequestsBox.values).thenReturn(requests);
        when(mockUsersBox.values).thenReturn([]);
        
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        
        final result = await analyticsService.getODRequestAnalytics(dateRange);
        
        expect(result.patterns, isNotEmpty);
        final peakDayPattern = result.patterns
            .firstWhere((p) => p.pattern == 'peak_day', orElse: () => 
                const RequestPattern(pattern: '', description: '', confidence: 0));
        
        expect(peakDayPattern.pattern, equals('peak_day'));
        expect(peakDayPattern.description, contains('Monday'));
        expect(peakDayPattern.confidence, equals(75.0)); // 3 out of 4 requests on Monday
      });
      
      test('should identify seasonal trends', () async {
        final requests = [
          // January requests (peak month)
          ODRequest(
            id: 'req1',
            studentId: 'student1',
            studentName: 'John Doe',
            registerNumber: 'CS001',
            date: DateTime(2024, 1, 15),
            periods: [1, 2],
            reason: 'Medical',
            status: 'approved',
            createdAt: DateTime(2024, 1, 15),
          ),
          ODRequest(
            id: 'req2',
            studentId: 'student2',
            studentName: 'Jane Smith',
            registerNumber: 'CS002',
            date: DateTime(2024, 1, 20),
            periods: [1, 2],
            reason: 'Personal',
            status: 'approved',
            createdAt: DateTime(2024, 1, 20),
          ),
          ODRequest(
            id: 'req3',
            studentId: 'student3',
            studentName: 'Bob Wilson',
            registerNumber: 'CS003',
            date: DateTime(2024, 1, 25),
            periods: [1, 2],
            reason: 'Family',
            status: 'approved',
            createdAt: DateTime(2024, 1, 25),
          ),
          // February request
          ODRequest(
            id: 'req4',
            studentId: 'student4',
            studentName: 'Alice Brown',
            registerNumber: 'CS004',
            date: DateTime(2024, 2, 5),
            periods: [1, 2],
            reason: 'Medical',
            status: 'approved',
            createdAt: DateTime(2024, 2, 5),
          ),
        ];
        
        when(mockODRequestsBox.values).thenReturn(requests);
        when(mockUsersBox.values).thenReturn([]);
        
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 2, 29),
        );
        
        final result = await analyticsService.getODRequestAnalytics(dateRange);
        
        expect(result.patterns, isNotEmpty);
        final seasonalPattern = result.patterns
            .firstWhere((p) => p.pattern == 'seasonal_trend', orElse: () => 
                const RequestPattern(pattern: '', description: '', confidence: 0));
        
        expect(seasonalPattern.pattern, equals('seasonal_trend'));
        expect(seasonalPattern.description, contains('Jan'));
        expect(seasonalPattern.confidence, equals(75.0)); // 3 out of 4 requests in January
      });
      
      test('should identify best approval reasons', () async {
        final requests = [
          // Medical reasons (100% approval rate)
          ODRequest(
            id: 'req1',
            studentId: 'student1',
            studentName: 'John Doe',
            registerNumber: 'CS001',
            date: DateTime(2024, 1, 15),
            periods: [1, 2],
            reason: 'Medical appointment',
            status: 'approved',
            createdAt: DateTime(2024, 1, 15),
          ),
          ODRequest(
            id: 'req2',
            studentId: 'student2',
            studentName: 'Jane Smith',
            registerNumber: 'CS002',
            date: DateTime(2024, 1, 20),
            periods: [1, 2],
            reason: 'Medical appointment',
            status: 'approved',
            createdAt: DateTime(2024, 1, 20),
          ),
          // Personal reasons (50% approval rate)
          ODRequest(
            id: 'req3',
            studentId: 'student3',
            studentName: 'Bob Wilson',
            registerNumber: 'CS003',
            date: DateTime(2024, 1, 25),
            periods: [1, 2],
            reason: 'Personal work',
            status: 'approved',
            createdAt: DateTime(2024, 1, 25),
          ),
          ODRequest(
            id: 'req4',
            studentId: 'student4',
            studentName: 'Alice Brown',
            registerNumber: 'CS004',
            date: DateTime(2024, 2, 5),
            periods: [1, 2],
            reason: 'Personal work',
            status: 'rejected',
            createdAt: DateTime(2024, 2, 5),
            rejectionReason: 'Insufficient notice',
          ),
        ];
        
        when(mockODRequestsBox.values).thenReturn(requests);
        when(mockUsersBox.values).thenReturn([]);
        
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 2, 29),
        );
        
        final result = await analyticsService.getODRequestAnalytics(dateRange);
        
        expect(result.patterns, isNotEmpty);
        final bestReasonPattern = result.patterns
            .firstWhere((p) => p.pattern == 'best_reason', orElse: () => 
                const RequestPattern(pattern: '', description: '', confidence: 0));
        
        expect(bestReasonPattern.pattern, equals('best_reason'));
        expect(bestReasonPattern.description, contains('Medical appointment'));
        expect(bestReasonPattern.confidence, equals(100.0)); // 100% approval rate
      });
    });
    
    group('Trend Analysis Algorithms', () {
      test('should calculate upward trend correctly', () async {
        // Create requests with increasing trend over weeks
        final now = DateTime.now();
        final requests = <ODRequest>[];
        
        // Week 1: 1 request
        requests.add(ODRequest(
          id: 'req1',
          studentId: 'student1',
          studentName: 'John Doe',
          registerNumber: 'CS001',
          date: now.subtract(const Duration(days: 21)),
          periods: [1, 2],
          reason: 'Medical',
          status: 'approved',
          createdAt: now.subtract(const Duration(days: 21)),
        ));
        
        // Week 2: 2 requests
        for (int i = 0; i < 2; i++) {
          requests.add(ODRequest(
            id: 'req${2 + i}',
            studentId: 'student${2 + i}',
            studentName: 'Student ${2 + i}',
            registerNumber: 'CS00${2 + i}',
            date: now.subtract(const Duration(days: 14)),
            periods: [1, 2],
            reason: 'Medical',
            status: 'approved',
            createdAt: now.subtract(const Duration(days: 14)),
          ));
        }
        
        // Week 3: 3 requests
        for (int i = 0; i < 3; i++) {
          requests.add(ODRequest(
            id: 'req${4 + i}',
            studentId: 'student${4 + i}',
            studentName: 'Student ${4 + i}',
            registerNumber: 'CS00${4 + i}',
            date: now.subtract(const Duration(days: 7)),
            periods: [1, 2],
            reason: 'Medical',
            status: 'approved',
            createdAt: now.subtract(const Duration(days: 7)),
          ));
        }
        
        when(mockODRequestsBox.values).thenReturn(requests);
        when(mockUsersBox.values).thenReturn([]);
        
        final result = await analyticsService.getTrendAnalysis(AnalyticsType.requests);
        
        expect(result, isNotEmpty);
        final weeklyTrend = result.firstWhere((t) => t.label == 'Weekly Request Volume');
        
        expect(weeklyTrend.direction, equals(TrendDirection.up));
        expect(weeklyTrend.changePercentage, greaterThan(0));
        expect(weeklyTrend.dataPoints, isNotEmpty);
      });
      
      test('should calculate downward trend correctly', () async {
        // Create requests with decreasing trend over months
        final now = DateTime.now();
        final requests = <ODRequest>[];
        
        // Month 1: 6 requests (3 approved)
        for (int i = 0; i < 6; i++) {
          requests.add(ODRequest(
            id: 'req${i + 1}',
            studentId: 'student${i + 1}',
            studentName: 'Student ${i + 1}',
            registerNumber: 'CS00${i + 1}',
            date: DateTime(now.year, now.month - 2, 15),
            periods: [1, 2],
            reason: 'Medical',
            status: i < 3 ? 'approved' : 'rejected',
            createdAt: DateTime(now.year, now.month - 2, 15),
          ));
        }
        
        // Month 2: 4 requests (1 approved)
        for (int i = 0; i < 4; i++) {
          requests.add(ODRequest(
            id: 'req${i + 7}',
            studentId: 'student${i + 7}',
            studentName: 'Student ${i + 7}',
            registerNumber: 'CS00${i + 7}',
            date: DateTime(now.year, now.month - 1, 15),
            periods: [1, 2],
            reason: 'Medical',
            status: i < 1 ? 'approved' : 'rejected',
            createdAt: DateTime(now.year, now.month - 1, 15),
          ));
        }
        
        when(mockODRequestsBox.values).thenReturn(requests);
        when(mockUsersBox.values).thenReturn([]);
        
        final result = await analyticsService.getTrendAnalysis(AnalyticsType.approvals);
        
        expect(result, isNotEmpty);
        final approvalTrend = result.firstWhere((t) => t.label == 'Monthly Approval Rate');
        
        expect(approvalTrend.direction, equals(TrendDirection.down));
        expect(approvalTrend.changePercentage, lessThan(0));
      });
      
      test('should calculate stable trend correctly', () async {
        // Create requests with stable trend
        final now = DateTime.now();
        final requests = <ODRequest>[];
        
        // Create consistent approval rates across months
        for (int month = 0; month < 3; month++) {
          for (int i = 0; i < 4; i++) {
            requests.add(ODRequest(
              id: 'req${month * 4 + i + 1}',
              studentId: 'student${month * 4 + i + 1}',
              studentName: 'Student ${month * 4 + i + 1}',
              registerNumber: 'CS00${month * 4 + i + 1}',
              date: DateTime(now.year, now.month - month, 15),
              periods: [1, 2],
              reason: 'Medical',
              status: i < 2 ? 'approved' : 'rejected', // 50% approval rate
              createdAt: DateTime(now.year, now.month - month, 15),
            ));
          }
        }
        
        when(mockODRequestsBox.values).thenReturn(requests);
        when(mockUsersBox.values).thenReturn([]);
        
        final result = await analyticsService.getTrendAnalysis(AnalyticsType.approvals);
        
        expect(result, isNotEmpty);
        final approvalTrend = result.firstWhere((t) => t.label == 'Monthly Approval Rate');
        
        expect(approvalTrend.direction, equals(TrendDirection.stable));
        expect(approvalTrend.changePercentage.abs(), lessThan(5.0)); // Within 5% threshold
      });
    });
    
    group('Data Aggregation Algorithms', () {
      test('should correctly aggregate requests by month', () async {
        final requests = [
          ODRequest(
            id: 'req1',
            studentId: 'student1',
            studentName: 'John Doe',
            registerNumber: 'CS001',
            date: DateTime(2024, 1, 15),
            periods: [1, 2],
            reason: 'Medical',
            status: 'approved',
            createdAt: DateTime(2024, 1, 15),
          ),
          ODRequest(
            id: 'req2',
            studentId: 'student2',
            studentName: 'Jane Smith',
            registerNumber: 'CS002',
            date: DateTime(2024, 1, 20),
            periods: [1, 2],
            reason: 'Personal',
            status: 'approved',
            createdAt: DateTime(2024, 1, 20),
          ),
          ODRequest(
            id: 'req3',
            studentId: 'student3',
            studentName: 'Bob Wilson',
            registerNumber: 'CS003',
            date: DateTime(2024, 2, 5),
            periods: [1, 2],
            reason: 'Family',
            status: 'approved',
            createdAt: DateTime(2024, 2, 5),
          ),
        ];
        
        when(mockODRequestsBox.values).thenReturn(requests);
        when(mockUsersBox.values).thenReturn([]);
        
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 2, 29),
        );
        
        final result = await analyticsService.getODRequestAnalytics(dateRange);
        
        expect(result.requestsByMonth['2024-01'], equals(2));
        expect(result.requestsByMonth['2024-02'], equals(1));
      });
      
      test('should correctly calculate rejection reason statistics', () async {
        final requests = [
          ODRequest(
            id: 'req1',
            studentId: 'student1',
            studentName: 'John Doe',
            registerNumber: 'CS001',
            date: DateTime(2024, 1, 15),
            periods: [1, 2],
            reason: 'Medical',
            status: 'rejected',
            createdAt: DateTime(2024, 1, 15),
            rejectionReason: 'Insufficient notice',
          ),
          ODRequest(
            id: 'req2',
            studentId: 'student2',
            studentName: 'Jane Smith',
            registerNumber: 'CS002',
            date: DateTime(2024, 1, 20),
            periods: [1, 2],
            reason: 'Personal',
            status: 'rejected',
            createdAt: DateTime(2024, 1, 20),
            rejectionReason: 'Insufficient notice',
          ),
          ODRequest(
            id: 'req3',
            studentId: 'student3',
            studentName: 'Bob Wilson',
            registerNumber: 'CS003',
            date: DateTime(2024, 2, 5),
            periods: [1, 2],
            reason: 'Family',
            status: 'rejected',
            createdAt: DateTime(2024, 2, 5),
            rejectionReason: 'Invalid reason',
          ),
        ];
        
        when(mockODRequestsBox.values).thenReturn(requests);
        when(mockUsersBox.values).thenReturn([]);
        
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 2, 29),
        );
        
        final result = await analyticsService.getODRequestAnalytics(dateRange);
        
        expect(result.topRejectionReasons, hasLength(2));
        
        final topReason = result.topRejectionReasons.first;
        expect(topReason.reason, equals('Insufficient notice'));
        expect(topReason.count, equals(2));
        expect(topReason.percentage, closeTo(66.67, 0.1));
        
        final secondReason = result.topRejectionReasons[1];
        expect(secondReason.reason, equals('Invalid reason'));
        expect(secondReason.count, equals(1));
        expect(secondReason.percentage, closeTo(33.33, 0.1));
      });
    });
  });
}