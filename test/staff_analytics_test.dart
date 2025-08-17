import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/providers/staff_analytics_provider.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';

void main() {
  group('Staff Analytics Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with correct default state', () {
      final state = container.read(staffAnalyticsProvider);
      
      expect(state.workloadAnalytics, isNull);
      expect(state.teachingAnalytics, isNull);
      expect(state.timeAllocationAnalytics, isNull);
      expect(state.efficiencyMetrics, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('should update loading state correctly', () {
      final notifier = container.read(staffAnalyticsProvider.notifier);
      
      // Initial state should not be loading
      expect(container.read(staffAnalyticsProvider).isLoading, isFalse);
      
      // Test state management
      expect(notifier.needsRefresh, isTrue); // No last updated time
    });

    test('should handle error state correctly', () {
      const initialState = StaffAnalyticsState();
      final errorState = initialState.copyWith(
        error: 'Test error message',
        isLoading: false,
      );
      
      expect(errorState.error, equals('Test error message'));
      expect(errorState.isLoading, isFalse);
    });

    test('should create date range correctly', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 12, 31);
      final dateRange = DateRange(startDate: startDate, endDate: endDate);
      
      expect(dateRange.startDate, equals(startDate));
      expect(dateRange.endDate, equals(endDate));
    });

    test('should handle workload trend enum correctly', () {
      expect(WorkloadTrend.values.length, equals(3));
      expect(WorkloadTrend.values.contains(WorkloadTrend.increasing), isTrue);
      expect(WorkloadTrend.values.contains(WorkloadTrend.decreasing), isTrue);
      expect(WorkloadTrend.values.contains(WorkloadTrend.stable), isTrue);
    });

    test('should handle activity type enum correctly', () {
      expect(ActivityType.values.length, equals(7));
      expect(ActivityType.values.contains(ActivityType.teaching), isTrue);
      expect(ActivityType.values.contains(ActivityType.odProcessing), isTrue);
      expect(ActivityType.values.contains(ActivityType.administrative), isTrue);
    });

    test('should handle grade enum correctly', () {
      expect(Grade.values.length, equals(13));
      expect(Grade.values.contains(Grade.grade1), isTrue);
      expect(Grade.values.contains(Grade.grade12), isTrue);
      expect(Grade.values.contains(Grade.postGraduate), isTrue);
    });
  });

  group('Staff Analytics Models Tests', () {
    test('should create TimeSlot correctly', () {
      final startTime = DateTime(2024, 1, 1, 9, 0);
      final endTime = DateTime(2024, 1, 1, 10, 0);
      
      final timeSlot = TimeSlot(
        periodNumber: 1,
        startTime: startTime,
        endTime: endTime,
        durationMinutes: 60,
      );
      
      expect(timeSlot.periodNumber, equals(1));
      expect(timeSlot.startTime, equals(startTime));
      expect(timeSlot.endTime, equals(endTime));
      expect(timeSlot.duration, equals(const Duration(minutes: 60)));
    });

    test('should create WorkloadAlert correctly', () {
      final alert = WorkloadAlert(
        id: 'test-alert-1',
        message: 'High workload detected',
        severity: 'high',
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      expect(alert.id, equals('test-alert-1'));
      expect(alert.message, equals('High workload detected'));
      expect(alert.severity, equals('high'));
      expect(alert.isRead, isFalse);
    });

    test('should create SubjectAllocation correctly', () {
      final classAssignments = [
        const ClassAssignment(
          className: 'Class 10A',
          grade: Grade.grade10,
          section: 'A',
          studentCount: 30,
          periodsAssigned: 5,
        ),
      ];
      
      final subjectAllocation = SubjectAllocation(
        subjectCode: 'MATH101',
        subjectName: 'Mathematics',
        periodsPerWeek: 5,
        totalPeriods: 80,
        classAssignments: classAssignments,
        studentCount: 30,
        type: SubjectType.theory,
      );
      
      expect(subjectAllocation.subjectCode, equals('MATH101'));
      expect(subjectAllocation.subjectName, equals('Mathematics'));
      expect(subjectAllocation.periodsPerWeek, equals(5));
      expect(subjectAllocation.classAssignments.length, equals(1));
      expect(subjectAllocation.type, equals(SubjectType.theory));
    });
  });

  group('Staff Analytics State Management Tests', () {
    test('should copy state correctly', () {
      const originalState = StaffAnalyticsState(
        isLoading: false,
        error: null,
        currentStaffId: 'staff-1',
      );
      
      final newState = originalState.copyWith(
        isLoading: true,
        error: 'New error',
      );
      
      expect(newState.isLoading, isTrue);
      expect(newState.error, equals('New error'));
      expect(newState.currentStaffId, equals('staff-1')); // Should remain unchanged
    });

    test('should handle null values in copyWith correctly', () {
      const originalState = StaffAnalyticsState(
        isLoading: true,
        error: 'Original error',
      );
      
      final newState = originalState.copyWith(
        error: null, // Explicitly setting to null
      );
      
      expect(newState.isLoading, isTrue); // Should remain unchanged
      expect(newState.error, isNull); // Should be null
    });
  });
}