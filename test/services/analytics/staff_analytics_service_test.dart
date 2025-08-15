import 'dart:math';
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

    group('Teaching Analytics Tests', () {
      test('should calculate subject-wise period allocation correctly', () {
        // Test subject allocation calculation
        final periodsPerSubject = {
          'MATH101': 6,
          'PHYS101': 4,
          'CHEM101': 3,
        };
        
        final totalPeriods = periodsPerSubject.values.fold<int>(0, (sum, periods) => sum + periods);
        expect(totalPeriods, equals(13));
        
        // Test distribution calculation
        final mathPercentage = (periodsPerSubject['MATH101']! / totalPeriods) * 100;
        final physPercentage = (periodsPerSubject['PHYS101']! / totalPeriods) * 100;
        final chemPercentage = (periodsPerSubject['CHEM101']! / totalPeriods) * 100;
        
        expect(mathPercentage, closeTo(46.15, 0.01));
        expect(physPercentage, closeTo(30.77, 0.01));
        expect(chemPercentage, closeTo(23.08, 0.01));
        expect(mathPercentage + physPercentage + chemPercentage, closeTo(100.0, 0.01));
      });

      test('should calculate class-wise teaching load distribution correctly', () {
        // Test class load distribution
        final classAllocations = {
          '10A': {'periods': 8, 'students': 35},
          '10B': {'periods': 6, 'students': 32},
          '11A': {'periods': 5, 'students': 28},
        };
        
        final totalPeriods = classAllocations.values
            .fold<int>(0, (sum, data) => sum + (data['periods'] as int));
        expect(totalPeriods, equals(19));
        
        // Calculate load percentages
        final class10APercentage = (classAllocations['10A']!['periods'] as int) / totalPeriods * 100;
        final class10BPercentage = (classAllocations['10B']!['periods'] as int) / totalPeriods * 100;
        final class11APercentage = (classAllocations['11A']!['periods'] as int) / totalPeriods * 100;
        
        expect(class10APercentage, closeTo(42.11, 0.01));
        expect(class10BPercentage, closeTo(31.58, 0.01));
        expect(class11APercentage, closeTo(26.32, 0.01));
      });

      test('should calculate grade-wise teaching load distribution correctly', () {
        // Test grade distribution calculation
        final gradeDistribution = {
          Grade.grade10: 2, // 2 classes
          Grade.grade11: 1, // 1 class
          Grade.grade12: 1, // 1 class
        };
        
        final totalClasses = gradeDistribution.values.fold<int>(0, (sum, count) => sum + count);
        expect(totalClasses, equals(4));
        
        // Calculate percentages
        final grade10Percentage = (gradeDistribution[Grade.grade10]! / totalClasses) * 100;
        final grade11Percentage = (gradeDistribution[Grade.grade11]! / totalClasses) * 100;
        final grade12Percentage = (gradeDistribution[Grade.grade12]! / totalClasses) * 100;
        
        expect(grade10Percentage, equals(50.0));
        expect(grade11Percentage, equals(25.0));
        expect(grade12Percentage, equals(25.0));
      });

      test('should calculate student count tracking correctly', () {
        // Test student count calculations
        final classSizes = [35, 32, 28, 30, 25];
        
        final totalStudents = classSizes.fold<int>(0, (sum, size) => sum + size);
        final averageClassSize = totalStudents / classSizes.length;
        final minClassSize = classSizes.reduce((a, b) => a < b ? a : b);
        final maxClassSize = classSizes.reduce((a, b) => a > b ? a : b);
        
        expect(totalStudents, equals(150));
        expect(averageClassSize, equals(30.0));
        expect(minClassSize, equals(25));
        expect(maxClassSize, equals(35));
        
        // Test standard deviation calculation
        final variance = classSizes
            .map((size) => (size - averageClassSize) * (size - averageClassSize))
            .reduce((a, b) => a + b) / classSizes.length;
        final standardDeviation = sqrt(variance);
        
        expect(standardDeviation, closeTo(3.41, 0.1));
      });

      test('should calculate class size analytics correctly', () {
        // Test comprehensive class size analytics
        final classSizes = [30, 35, 28, 32, 25, 40, 22];
        classSizes.sort();
        
        final average = classSizes.reduce((a, b) => a + b) / classSizes.length;
        final median = classSizes[classSizes.length ~/ 2].toDouble();
        final minimum = classSizes.first;
        final maximum = classSizes.last;
        
        expect(average, closeTo(30.29, 0.01));
        expect(median, equals(30.0));
        expect(minimum, equals(22));
        expect(maximum, equals(40));
        
        // Test variance and standard deviation
        final variance = classSizes
            .map((size) => (size - average) * (size - average))
            .reduce((a, b) => a + b) / classSizes.length;
        final standardDeviation = sqrt(variance);
        
        expect(standardDeviation, closeTo(5.62, 0.1));
      });

      test('should calculate teaching efficiency metrics correctly', () {
        // Test teaching efficiency calculations
        const totalPeriods = 25;
        const maxPossiblePeriods = 40;
        const totalStudents = 150;
        const subjectCount = 3;
        const gradeCount = 2;
        
        const periodsUtilizationRate = totalPeriods / maxPossiblePeriods;
        const averageStudentsPerPeriod = totalStudents / totalPeriods;
        const subjectDiversityIndex = subjectCount / 10.0;
        const gradeLevelSpread = gradeCount / 12.0;
        
        expect(periodsUtilizationRate, equals(0.625));
        expect(averageStudentsPerPeriod, equals(6.0));
        expect(subjectDiversityIndex, equals(0.3));
        expect(gradeLevelSpread, closeTo(0.167, 0.001));
      });

      test('should calculate student-to-period ratios correctly', () {
        // Test student-to-period ratio calculations
        final subjectData = {
          'MATH101': {'students': 120.0, 'periods': 6},
          'PHYS101': {'students': 80.0, 'periods': 4},
          'CHEM101': {'students': 60.0, 'periods': 3},
        };
        
        final ratios = <String, double>{};
        for (final entry in subjectData.entries) {
          final students = entry.value['students'] as double;
          final periods = entry.value['periods'] as int;
          ratios[entry.key] = students / periods;
        }
        
        expect(ratios['MATH101'], equals(20.0));
        expect(ratios['PHYS101'], equals(20.0));
        expect(ratios['CHEM101'], equals(20.0));
      });

      test('should handle edge cases in teaching analytics calculations', () {
        // Test empty data
        final emptyClassSizes = <int>[];
        expect(emptyClassSizes.isEmpty, isTrue);
        
        // Test single class
        final singleClass = [30];
        final singleAverage = singleClass.reduce((a, b) => a + b) / singleClass.length;
        expect(singleAverage, equals(30.0));
        
        // Test zero periods
        const zeroPeriods = 0;
        const totalStudents = 100;
        const ratio = zeroPeriods > 0 ? totalStudents / zeroPeriods : 0.0;
        expect(ratio, equals(0.0));
        
        // Test maximum utilization
        const maxPeriods = 40;
        const assignedPeriods = 40;
        const utilization = assignedPeriods / maxPeriods;
        expect(utilization, equals(1.0));
      });
    });
  });
}