import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/services/analytics/staff_analytics_service.dart';

void main() {
  group('Staff Analytics Integration Tests', () {
    test('should create and process workload data models correctly', () {
      // Test TimeSlot model
      final timeSlot = TimeSlot(
        periodNumber: 1,
        startTime: DateTime(2024, 1, 1, 9, 0),
        endTime: DateTime(2024, 1, 1, 10, 0),
        durationMinutes: 60,
      );
      
      expect(timeSlot.periodNumber, equals(1));
      expect(timeSlot.duration.inMinutes, equals(60));
      
      // Test Period model
      final period = Period(
        id: 'period_001',
        subjectCode: 'MATH101',
        className: '10A',
        grade: Grade.grade10,
        timeSlot: timeSlot,
        type: PeriodType.regular,
        studentCount: 35,
        date: DateTime(2024, 1, 1),
      );
      
      expect(period.id, equals('period_001'));
      expect(period.subjectCode, equals('MATH101'));
      expect(period.grade, equals(Grade.grade10));
      expect(period.type, equals(PeriodType.regular));
      expect(period.studentCount, equals(35));
      
      // Test ClassAssignment model
      const classAssignment = ClassAssignment(
        className: '10A',
        grade: Grade.grade10,
        section: 'A',
        studentCount: 35,
        periodsAssigned: 6,
      );
      
      expect(classAssignment.className, equals('10A'));
      expect(classAssignment.grade, equals(Grade.grade10));
      expect(classAssignment.periodsAssigned, equals(6));
      
      // Test SubjectAllocation model
      const subjectAllocation = SubjectAllocation(
        subjectCode: 'MATH101',
        subjectName: 'Mathematics',
        periodsPerWeek: 6,
        totalPeriods: 96, // 6 periods * 16 weeks
        classAssignments: [classAssignment],
        studentCount: 35,
        type: SubjectType.theory,
      );
      
      expect(subjectAllocation.subjectCode, equals('MATH101'));
      expect(subjectAllocation.periodsPerWeek, equals(6));
      expect(subjectAllocation.totalPeriods, equals(96));
      expect(subjectAllocation.classAssignments, hasLength(1));
      expect(subjectAllocation.type, equals(SubjectType.theory));
      
      // Test WorkloadAlert model
      final alert = WorkloadAlert(
        id: 'alert_001',
        message: 'High workload detected: 55.0 hours per week',
        severity: 'high',
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      expect(alert.id, equals('alert_001'));
      expect(alert.severity, equals('high'));
      expect(alert.isRead, equals(false));
      expect(alert.message.contains('High workload'), isTrue);
      
      // Test WorkloadAnalytics model
      final workloadAnalytics = WorkloadAnalytics(
        staffId: 'staff_001',
        staffName: 'Dr. John Smith',
        department: 'Mathematics',
        periodStart: DateTime(2024, 8, 1),
        periodEnd: DateTime(2024, 12, 31),
        totalWorkingHours: 180.0,
        weeklyAverageHours: 40.0,
        hoursByWeek: {
          'Week 1': 38.0,
          'Week 2': 42.0,
          'Week 3': 40.0,
        },
        hoursByMonth: {
          '2024-08': 160.0,
          '2024-09': 170.0,
        },
        hoursByActivity: {
          'teaching': 120.0,
          'administrative': 40.0,
          'preparation': 20.0,
        },
        trend: WorkloadTrend.stable,
        alerts: [alert],
      );
      
      expect(workloadAnalytics.staffId, equals('staff_001'));
      expect(workloadAnalytics.totalWorkingHours, equals(180.0));
      expect(workloadAnalytics.weeklyAverageHours, equals(40.0));
      expect(workloadAnalytics.hoursByWeek, hasLength(3));
      expect(workloadAnalytics.hoursByMonth, hasLength(2));
      expect(workloadAnalytics.hoursByActivity, hasLength(3));
      expect(workloadAnalytics.trend, equals(WorkloadTrend.stable));
      expect(workloadAnalytics.alerts, hasLength(1));
    });

    test('should validate enum values correctly', () {
      // Test ActivityType enum
      expect(ActivityType.values, hasLength(7));
      expect(ActivityType.values, contains(ActivityType.teaching));
      expect(ActivityType.values, contains(ActivityType.odProcessing));
      expect(ActivityType.values, contains(ActivityType.administrative));
      
      // Test Grade enum
      expect(Grade.values, hasLength(13));
      expect(Grade.values, contains(Grade.grade1));
      expect(Grade.values, contains(Grade.grade12));
      expect(Grade.values, contains(Grade.postGraduate));
      
      // Test PeriodType enum
      expect(PeriodType.values, hasLength(6));
      expect(PeriodType.values, contains(PeriodType.regular));
      expect(PeriodType.values, contains(PeriodType.lab));
      expect(PeriodType.values, contains(PeriodType.practical));
      
      // Test SubjectType enum
      expect(SubjectType.values, hasLength(5));
      expect(SubjectType.values, contains(SubjectType.theory));
      expect(SubjectType.values, contains(SubjectType.practical));
      expect(SubjectType.values, contains(SubjectType.project));
      
      // Test WorkloadTrend enum
      expect(WorkloadTrend.values, hasLength(3));
      expect(WorkloadTrend.values, contains(WorkloadTrend.increasing));
      expect(WorkloadTrend.values, contains(WorkloadTrend.decreasing));
      expect(WorkloadTrend.values, contains(WorkloadTrend.stable));
    });

    test('should handle complex workload calculations', () {
      // Test complex workload scenario
      const workloadData = StaffWorkloadData(
        staffId: 'staff_complex',
        semester: 'Fall_2024',
        periodsPerSubject: {
          'MATH101': 8,
          'MATH201': 6,
          'STAT301': 4,
        },
        classesPerGrade: {
          'grade10': ['10A', '10B', '10C'],
          'grade11': ['11A', '11B'],
          'grade12': ['12A'],
        },
        weeklySchedule: {
          'monday': [],
          'tuesday': [],
          'wednesday': [],
          'thursday': [],
          'friday': [],
        },
        totalWorkingHours: 45.0,
        activityBreakdown: {
          'teaching': 28.0,
          'administrative': 12.0,
          'preparation': 3.0,
          'evaluation': 2.0,
        },
      );
      
      // Verify total periods calculation
      final totalPeriods = workloadData.periodsPerSubject.values
          .fold<int>(0, (sum, periods) => sum + periods);
      expect(totalPeriods, equals(18)); // 8 + 6 + 4
      
      // Verify total classes calculation
      final totalClasses = workloadData.classesPerGrade.values
          .fold<int>(0, (sum, classes) => sum + classes.length);
      expect(totalClasses, equals(6)); // 3 + 2 + 1
      
      // Verify activity breakdown totals
      final totalActivityHours = workloadData.activityBreakdown.values
          .fold<double>(0, (sum, hours) => sum + hours);
      expect(totalActivityHours, equals(45.0)); // 28 + 12 + 3 + 2
      
      // Verify teaching percentage
      final teachingPercentage = (workloadData.activityBreakdown['teaching']! / 
          workloadData.totalWorkingHours) * 100;
      expect(teachingPercentage, closeTo(62.22, 0.01)); // 28/45 * 100
    });

    test('should create service interface models correctly', () {
      // Test TeachingAnalytics model creation
      const teachingEfficiency = TeachingEfficiency(
        periodsUtilizationRate: 0.75,
        averageStudentsPerPeriod: 32.5,
        subjectDiversityIndex: 0.6,
        gradeLevelSpread: 0.5,
      );
      
      expect(teachingEfficiency.periodsUtilizationRate, equals(0.75));
      expect(teachingEfficiency.averageStudentsPerPeriod, equals(32.5));
      
      // Test TimeConflict model
      final timeConflict = TimeConflict(
        id: 'conflict_001',
        description: 'Overlapping periods detected',
        conflictTime: DateTime(2024, 1, 1, 10, 0),
        conflictingActivities: ['MATH101', 'PHYS201'],
        severity: 'medium',
      );
      
      expect(timeConflict.id, equals('conflict_001'));
      expect(timeConflict.conflictingActivities, hasLength(2));
      expect(timeConflict.severity, equals('medium'));
      
      // Test ComparisonMetrics model
      const comparisonMetrics = ComparisonMetrics(
        averageProcessingTime: 24.5,
        averageApprovalRate: 78.3,
        averageResponseTime: 18.2,
        percentileRank: 85.7,
      );
      
      expect(comparisonMetrics.averageProcessingTime, equals(24.5));
      expect(comparisonMetrics.percentileRank, equals(85.7));
      
      // Test ReportOptions model
      const reportOptions = ReportOptions(
        includeWorkloadAnalysis: true,
        includeTeachingAnalysis: true,
        includeEfficiencyMetrics: false,
        includeComparativeAnalysis: true,
        includeBenchmarks: false,
        includeRecommendations: true,
        format: 'detailed',
      );
      
      expect(reportOptions.includeWorkloadAnalysis, isTrue);
      expect(reportOptions.includeEfficiencyMetrics, isFalse);
      expect(reportOptions.format, equals('detailed'));
    });

    test('should validate date range calculations', () {
      final dateRange = DateRange(
        startDate: DateTime(2024, 8, 1),
        endDate: DateTime(2024, 12, 31),
      );
      
      expect(dateRange.startDate.month, equals(8));
      expect(dateRange.endDate.month, equals(12));
      
      // Calculate weeks in range
      final days = dateRange.endDate.difference(dateRange.startDate).inDays;
      final weeks = days / 7.0;
      
      expect(days, greaterThan(120)); // More than 4 months
      expect(weeks, greaterThan(17)); // More than 17 weeks
      
      // Calculate months in range
      final months = (dateRange.endDate.year - dateRange.startDate.year) * 12 + 
                     dateRange.endDate.month - dateRange.startDate.month + 1;
      
      expect(months, equals(5)); // August to December = 5 months
    });
  });
}