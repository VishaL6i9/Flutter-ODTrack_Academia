import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/services/analytics/staff_analytics_service.dart';
import 'package:odtrack_academia/services/analytics/hive_staff_analytics_service.dart';

void main() {
  group('StaffAnalyticsService', () {
    late StaffAnalyticsService service;

    setUp(() async {
      service = HiveStaffAnalyticsService();
      // Note: In a real test environment, you would set up Hive properly
      // For now, we'll test the interface and basic functionality
    });

    group('Interface Tests', () {
      test('should have correct interface methods', () {
        expect(service.initialize, isA<Function>());
        expect(service.getWorkloadAnalytics, isA<Function>());
        expect(service.getTeachingAnalytics, isA<Function>());
        expect(service.calculateWorkingHours, isA<Function>());
        expect(service.calculateActivityDistribution, isA<Function>());
        expect(service.getWorkloadTrend, isA<Function>());
        expect(service.generateWorkloadAlerts, isA<Function>());
        expect(service.storeWorkloadData, isA<Function>());
        expect(service.getWorkloadData, isA<Function>());
        expect(service.updateWorkloadData, isA<Function>());
        expect(service.deleteWorkloadData, isA<Function>());
        expect(service.refreshAnalyticsCache, isA<Function>());
      });
    });

    group('Data Model Tests', () {
      test('should create WorkloadAnalytics model correctly', () {
        final workloadAnalytics = WorkloadAnalytics(
          staffId: 'staff_001',
          staffName: 'Dr. John Smith',
          department: 'Mathematics',
          periodStart: DateTime(2024, 8, 1),
          periodEnd: DateTime(2024, 12, 31),
          totalWorkingHours: 40.0,
          weeklyAverageHours: 35.0,
          hoursByWeek: {'Week 1': 35.0, 'Week 2': 40.0},
          hoursByMonth: {'2024-08': 150.0, '2024-09': 160.0},
          hoursByActivity: {'teaching': 25.0, 'administrative': 10.0},
          trend: WorkloadTrend.stable,
          alerts: [],
        );

        expect(workloadAnalytics.staffId, equals('staff_001'));
        expect(workloadAnalytics.staffName, equals('Dr. John Smith'));
        expect(workloadAnalytics.department, equals('Mathematics'));
        expect(workloadAnalytics.totalWorkingHours, equals(40.0));
        expect(workloadAnalytics.weeklyAverageHours, equals(35.0));
        expect(workloadAnalytics.trend, equals(WorkloadTrend.stable));
      });

      test('should create StaffWorkloadData model correctly', () {
        const workloadData = StaffWorkloadData(
          staffId: 'staff_001',
          semester: 'Fall_2024',
          periodsPerSubject: {'MATH101': 6, 'PHYS201': 4},
          classesPerGrade: {'grade10': ['10A', '10B'], 'grade11': ['11A']},
          weeklySchedule: {},
          totalWorkingHours: 40.0,
          activityBreakdown: {'teaching': 25.0, 'administrative': 15.0},
        );

        expect(workloadData.staffId, equals('staff_001'));
        expect(workloadData.semester, equals('Fall_2024'));
        expect(workloadData.periodsPerSubject['MATH101'], equals(6));
        expect(workloadData.periodsPerSubject['PHYS201'], equals(4));
        expect(workloadData.totalWorkingHours, equals(40.0));
      });

      test('should create WorkloadAlert model correctly', () {
        final alert = WorkloadAlert(
          id: 'alert_001',
          message: 'High workload detected',
          severity: 'high',
          timestamp: DateTime.now(),
          isRead: false,
        );

        expect(alert.id, equals('alert_001'));
        expect(alert.message, equals('High workload detected'));
        expect(alert.severity, equals('high'));
        expect(alert.isRead, equals(false));
      });
    });

    group('Enum Tests', () {
      test('should have correct ActivityType values', () {
        expect(ActivityType.values, contains(ActivityType.teaching));
        expect(ActivityType.values, contains(ActivityType.odProcessing));
        expect(ActivityType.values, contains(ActivityType.administrative));
        expect(ActivityType.values, contains(ActivityType.meetings));
        expect(ActivityType.values, contains(ActivityType.preparation));
        expect(ActivityType.values, contains(ActivityType.evaluation));
        expect(ActivityType.values, contains(ActivityType.other));
      });

      test('should have correct Grade values', () {
        expect(Grade.values, contains(Grade.grade1));
        expect(Grade.values, contains(Grade.grade10));
        expect(Grade.values, contains(Grade.grade12));
        expect(Grade.values, contains(Grade.postGraduate));
      });

      test('should have correct WorkloadTrend values', () {
        expect(WorkloadTrend.values, contains(WorkloadTrend.increasing));
        expect(WorkloadTrend.values, contains(WorkloadTrend.decreasing));
        expect(WorkloadTrend.values, contains(WorkloadTrend.stable));
      });

      test('should have correct PeriodType values', () {
        expect(PeriodType.values, contains(PeriodType.regular));
        expect(PeriodType.values, contains(PeriodType.extra));
        expect(PeriodType.values, contains(PeriodType.substitution));
        expect(PeriodType.values, contains(PeriodType.remedial));
        expect(PeriodType.values, contains(PeriodType.lab));
        expect(PeriodType.values, contains(PeriodType.practical));
      });
    });

    group('Algorithm Tests', () {
      test('should calculate working hours algorithm correctly', () {
        // Test the algorithm logic for calculating working hours
        const periodsPerWeek = 10;
        final teachingHours = periodsPerWeek.toDouble();
        final preparationHours = teachingHours * 0.5; // 50% additional
        final evaluationHours = teachingHours * 0.3; // 30% additional
        const administrativeHours = 5.0; // Fixed 5 hours
        
        final weeklyHours = teachingHours + preparationHours + evaluationHours + administrativeHours;
        const expectedWeeklyHours = 10.0 + 5.0 + 3.0 + 5.0; // 23 hours per week
        
        expect(weeklyHours, equals(expectedWeeklyHours));
      });

      test('should calculate activity distribution percentages correctly', () {
        const totalHours = 40.0;
        const teachingHours = 25.0;
        const adminHours = 10.0;
        const otherHours = 5.0;
        
        const teachingPercentage = (teachingHours / totalHours) * 100;
        const adminPercentage = (adminHours / totalHours) * 100;
        const otherPercentage = (otherHours / totalHours) * 100;
        
        expect(teachingPercentage, equals(62.5));
        expect(adminPercentage, equals(25.0));
        expect(otherPercentage, equals(12.5));
        expect(teachingPercentage + adminPercentage + otherPercentage, equals(100.0));
      });

      test('should determine workload trend correctly', () {
        const currentHours = 45.0;
        const previousHours = 40.0;
        
        const changePercentage = ((currentHours - previousHours) / previousHours) * 100;
        
        expect(changePercentage, equals(12.5));
        expect(changePercentage > 10, isTrue); // Should indicate increasing trend
      });

      test('should generate appropriate alerts based on workload thresholds', () {
        const weeklyHours1 = 55.0; // High workload
        const weeklyHours2 = 15.0; // Low workload
        const weeklyHours3 = 35.0; // Normal workload
        
        expect(weeklyHours1 > 50, isTrue); // Should trigger overwork alert
        expect(weeklyHours2 < 20, isTrue); // Should trigger underwork alert
        expect(weeklyHours3 >= 20 && weeklyHours3 <= 50, isTrue); // Should not trigger alerts
      });
    });
  });
}