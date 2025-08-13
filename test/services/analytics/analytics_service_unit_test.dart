import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/user.dart';

void main() {
  group('Analytics Calculations', () {
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
    
    group('Basic Analytics Calculations', () {
      test('should calculate correct approval rate', () {
        final approvedCount = testRequests.where((r) => r.isApproved).length;
        final totalCount = testRequests.length;
        final approvalRate = (approvedCount / totalCount) * 100;
        
        expect(approvalRate, equals(50.0)); // 2 approved out of 4 total
      });
      
      test('should aggregate requests by month correctly', () {
        final requestsByMonth = <String, int>{};
        
        for (final request in testRequests) {
          final monthKey = '${request.createdAt.year}-${request.createdAt.month.toString().padLeft(2, '0')}';
          requestsByMonth[monthKey] = (requestsByMonth[monthKey] ?? 0) + 1;
        }
        
        expect(requestsByMonth['2024-01'], equals(3)); // req1, req2, req3
        expect(requestsByMonth['2024-02'], equals(1)); // req4
      });
      
      test('should aggregate requests by department correctly', () {
        final departmentCounts = <String, int>{};
        
        for (final request in testRequests) {
          final user = testUsers.firstWhere((u) => u.id == request.studentId);
          final department = user.department ?? 'Unknown';
          departmentCounts[department] = (departmentCounts[department] ?? 0) + 1;
        }
        
        expect(departmentCounts['Computer Science'], equals(2)); // req1, req2
        expect(departmentCounts['Electronics'], equals(2)); // req3, req4
      });
      
      test('should calculate rejection reasons correctly', () {
        final rejectedRequests = testRequests.where((r) => r.isRejected && r.rejectionReason != null).toList();
        final totalRejected = rejectedRequests.length;
        
        expect(totalRejected, equals(1)); // Only req2
        
        final reasonCounts = <String, int>{};
        for (final request in rejectedRequests) {
          final reason = request.rejectionReason!;
          reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
        }
        
        final rejectionReasons = reasonCounts.entries
            .map((entry) => RejectionReason(
                  reason: entry.key,
                  count: entry.value,
                  percentage: (entry.value / totalRejected) * 100,
                ))
            .toList();
        
        expect(rejectionReasons.length, equals(1));
        expect(rejectionReasons.first.reason, equals('Insufficient notice'));
        expect(rejectionReasons.first.count, equals(1));
        expect(rejectionReasons.first.percentage, equals(100.0));
      });
    });
    
    group('Pattern Recognition Algorithms', () {
      test('should identify peak request days', () {
        final dayOfWeekCounts = <int, int>{};
        
        for (final request in testRequests) {
          final dayOfWeek = request.createdAt.weekday;
          dayOfWeekCounts[dayOfWeek] = (dayOfWeekCounts[dayOfWeek] ?? 0) + 1;
        }
        
        expect(dayOfWeekCounts.isNotEmpty, isTrue);
        
        final maxDay = dayOfWeekCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
        final confidence = (maxDay.value / testRequests.length) * 100;
        
        expect(confidence, greaterThan(0));
        expect(maxDay.value, greaterThan(0));
      });
      
      test('should identify seasonal trends', () {
        final monthCounts = <int, int>{};
        
        for (final request in testRequests) {
          final month = request.createdAt.month;
          monthCounts[month] = (monthCounts[month] ?? 0) + 1;
        }
        
        expect(monthCounts[1], equals(3)); // January: req1, req2, req3
        expect(monthCounts[2], equals(1)); // February: req4
        
        final maxMonth = monthCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
        expect(maxMonth.key, equals(1)); // January is peak month
        expect(maxMonth.value, equals(3));
      });
      
      test('should calculate approval rates by reason', () {
        final reasonApprovalRates = <String, double>{};
        final reasonCounts = <String, int>{};
        final reasonApprovals = <String, int>{};
        
        for (final request in testRequests) {
          reasonCounts[request.reason] = (reasonCounts[request.reason] ?? 0) + 1;
          if (request.isApproved) {
            reasonApprovals[request.reason] = (reasonApprovals[request.reason] ?? 0) + 1;
          }
        }
        
        for (final reason in reasonCounts.keys) {
          final approvals = reasonApprovals[reason] ?? 0;
          final total = reasonCounts[reason]!;
          reasonApprovalRates[reason] = (approvals / total) * 100;
        }
        
        expect(reasonApprovalRates['Medical appointment'], equals(50.0)); // 1 out of 2
        expect(reasonApprovalRates['Family function'], equals(0.0)); // 0 out of 1
        expect(reasonApprovalRates['Personal work'], equals(100.0)); // 1 out of 1
        
        final bestReason = reasonApprovalRates.entries.reduce((a, b) => a.value > b.value ? a : b);
        expect(bestReason.key, equals('Personal work'));
        expect(bestReason.value, equals(100.0));
      });
    });
    
    group('Trend Analysis Algorithms', () {
      test('should calculate trend direction correctly', () {
        // Test upward trend
        final upwardDataPoints = [
          DataPoint(timestamp: DateTime(2024, 1, 1), value: 1.0),
          DataPoint(timestamp: DateTime(2024, 1, 8), value: 2.0),
          DataPoint(timestamp: DateTime(2024, 1, 15), value: 3.0),
          DataPoint(timestamp: DateTime(2024, 1, 22), value: 4.0),
        ];
        
        final upwardDirection = _calculateTrendDirection(upwardDataPoints);
        expect(upwardDirection, equals(TrendDirection.up));
        
        // Test downward trend
        final downwardDataPoints = [
          DataPoint(timestamp: DateTime(2024, 1, 1), value: 4.0),
          DataPoint(timestamp: DateTime(2024, 1, 8), value: 3.0),
          DataPoint(timestamp: DateTime(2024, 1, 15), value: 2.0),
          DataPoint(timestamp: DateTime(2024, 1, 22), value: 1.0),
        ];
        
        final downwardDirection = _calculateTrendDirection(downwardDataPoints);
        expect(downwardDirection, equals(TrendDirection.down));
        
        // Test stable trend
        final stableDataPoints = [
          DataPoint(timestamp: DateTime(2024, 1, 1), value: 2.0),
          DataPoint(timestamp: DateTime(2024, 1, 8), value: 2.1),
          DataPoint(timestamp: DateTime(2024, 1, 15), value: 1.9),
          DataPoint(timestamp: DateTime(2024, 1, 22), value: 2.0),
        ];
        
        final stableDirection = _calculateTrendDirection(stableDataPoints);
        expect(stableDirection, equals(TrendDirection.stable));
      });
      
      test('should calculate percentage change correctly', () {
        final dataPoints = [
          DataPoint(timestamp: DateTime(2024, 1, 1), value: 10.0),
          DataPoint(timestamp: DateTime(2024, 1, 8), value: 15.0),
          DataPoint(timestamp: DateTime(2024, 1, 15), value: 20.0),
          DataPoint(timestamp: DateTime(2024, 1, 22), value: 12.0),
        ];
        
        final changePercentage = _calculateChangePercentage(dataPoints);
        expect(changePercentage, equals(20.0)); // (12 - 10) / 10 * 100 = 20%
      });
      
      test('should handle edge cases in trend calculation', () {
        // Empty data points
        final emptyDirection = _calculateTrendDirection([]);
        expect(emptyDirection, equals(TrendDirection.stable));
        
        // Single data point
        final singleDataPoint = [DataPoint(timestamp: DateTime.now(), value: 5.0)];
        final singleDirection = _calculateTrendDirection(singleDataPoint);
        expect(singleDirection, equals(TrendDirection.stable));
        
        // Zero starting value
        final zeroStartDataPoints = [
          DataPoint(timestamp: DateTime(2024, 1, 1), value: 0.0),
          DataPoint(timestamp: DateTime(2024, 1, 8), value: 5.0),
        ];
        
        final zeroStartChange = _calculateChangePercentage(zeroStartDataPoints);
        expect(zeroStartChange, equals(100.0)); // Special case for zero start
      });
    });
    
    group('Chart Data Generation', () {
      test('should generate bar chart data correctly', () {
        final statusCounts = <String, int>{
          'Approved': testRequests.where((r) => r.isApproved).length,
          'Rejected': testRequests.where((r) => r.isRejected).length,
          'Pending': testRequests.where((r) => r.isPending).length,
        };
        
        final chartData = statusCounts.entries
            .map((entry) => ChartData(
                  label: entry.key,
                  value: entry.value.toDouble(),
                ))
            .toList();
        
        expect(chartData.length, equals(3));
        
        final approvedData = chartData.firstWhere((d) => d.label == 'Approved');
        expect(approvedData.value, equals(2.0)); // req1, req4
        
        final rejectedData = chartData.firstWhere((d) => d.label == 'Rejected');
        expect(rejectedData.value, equals(1.0)); // req2
        
        final pendingData = chartData.firstWhere((d) => d.label == 'Pending');
        expect(pendingData.value, equals(1.0)); // req3
      });
      
      test('should generate pie chart data correctly', () {
        final reasonCounts = <String, int>{};
        
        for (final request in testRequests) {
          reasonCounts[request.reason] = (reasonCounts[request.reason] ?? 0) + 1;
        }
        
        final chartData = reasonCounts.entries
            .map((entry) => ChartData(
                  label: entry.key,
                  value: entry.value.toDouble(),
                ))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        expect(chartData.isNotEmpty, isTrue);
        
        final medicalData = chartData.firstWhere((d) => d.label == 'Medical appointment');
        expect(medicalData.value, equals(2.0)); // req1, req3
        
        final familyData = chartData.firstWhere((d) => d.label == 'Family function');
        expect(familyData.value, equals(1.0)); // req2
        
        final personalData = chartData.firstWhere((d) => d.label == 'Personal work');
        expect(personalData.value, equals(1.0)); // req4
      });
    });
    
    group('Data Filtering', () {
      test('should filter requests by date range correctly', () {
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        
        final filteredRequests = testRequests.where((r) => 
            r.createdAt.isAfter(dateRange.startDate) &&
            r.createdAt.isBefore(dateRange.endDate.add(const Duration(days: 1)))).toList();
        
        expect(filteredRequests.length, equals(3)); // req1, req2, req3 in January
        expect(filteredRequests.map((r) => r.id), containsAll(['req1', 'req2', 'req3']));
      });
      
      test('should filter requests by department correctly', () {
        final departmentStudents = testUsers
            .where((user) => user.department == 'Computer Science' && user.role == 'student')
            .map((user) => user.id)
            .toSet();
        
        final filteredRequests = testRequests
            .where((r) => departmentStudents.contains(r.studentId))
            .toList();
        
        expect(filteredRequests.length, equals(2)); // req1, req2 from student1
        expect(filteredRequests.map((r) => r.id), containsAll(['req1', 'req2']));
      });
      
      test('should filter requests by status correctly', () {
        final approvedRequests = testRequests.where((r) => r.status == 'approved').toList();
        expect(approvedRequests.length, equals(2)); // req1, req4
        
        final rejectedRequests = testRequests.where((r) => r.status == 'rejected').toList();
        expect(rejectedRequests.length, equals(1)); // req2
        
        final pendingRequests = testRequests.where((r) => r.status == 'pending').toList();
        expect(pendingRequests.length, equals(1)); // req3
      });
    });
  });
}

// Helper functions for testing trend calculations
TrendDirection _calculateTrendDirection(List<DataPoint> dataPoints) {
  if (dataPoints.length < 2) return TrendDirection.stable;
  
  final firstHalf = dataPoints.take(dataPoints.length ~/ 2).toList();
  final secondHalf = dataPoints.skip(dataPoints.length ~/ 2).toList();
  
  final firstAvg = firstHalf.isEmpty ? 0.0 : 
      firstHalf.map((p) => p.value).reduce((a, b) => a + b) / firstHalf.length;
  final secondAvg = secondHalf.isEmpty ? 0.0 : 
      secondHalf.map((p) => p.value).reduce((a, b) => a + b) / secondHalf.length;
  
  const threshold = 0.05; // 5% threshold for stability
  final changeRatio = firstAvg == 0 ? 0 : (secondAvg - firstAvg) / firstAvg;
  
  if (changeRatio > threshold) return TrendDirection.up;
  if (changeRatio < -threshold) return TrendDirection.down;
  return TrendDirection.stable;
}

double _calculateChangePercentage(List<DataPoint> dataPoints) {
  if (dataPoints.length < 2) return 0.0;
  
  final first = dataPoints.first.value;
  final last = dataPoints.last.value;
  
  if (first == 0) return last > 0 ? 100.0 : 0.0;
  
  return ((last - first) / first) * 100;
}