import 'dart:async';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/staff_member.dart';
import 'package:odtrack_academia/services/analytics/staff_analytics_service.dart';

/// Hive-based implementation of StaffAnalyticsService
class HiveStaffAnalyticsService implements StaffAnalyticsService {
  static const String _workloadDataBoxName = 'staff_workload_data';
  static const String _analyticsCacheBoxName = 'staff_analytics_cache';
  static const String _odRequestsBoxName = 'od_requests';
  static const String _staffMembersBoxName = 'staff_members';
  
  Box<StaffWorkloadData>? _workloadBox;
  Box<Map<String, dynamic>>? _analyticsBox;
  Box<ODRequest>? _odRequestsBox;
  Box<StaffMember>? _staffMembersBox;
  
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _workloadBox = await Hive.openBox<StaffWorkloadData>(_workloadDataBoxName);
      _analyticsBox = await Hive.openBox<Map<String, dynamic>>(_analyticsCacheBoxName);
      _odRequestsBox = await Hive.openBox<ODRequest>(_odRequestsBoxName);
      _staffMembersBox = await Hive.openBox<StaffMember>(_staffMembersBoxName);
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize HiveStaffAnalyticsService: $e');
    }
  }

  @override
  Future<WorkloadAnalytics> getWorkloadAnalytics(
    String staffId, 
    DateRange dateRange
  ) async {
    _ensureInitialized();
    
    final staffMember = _staffMembersBox!.get(staffId);
    if (staffMember == null) {
      throw Exception('Staff member not found: $staffId');
    }
    
    // Validate workload data exists for the period
    await _getWorkloadDataForPeriod(staffId, dateRange);
    
    // Calculate working hours
    final totalHours = await calculateWorkingHours(staffId, dateRange);
    final weeklyAverage = totalHours / _getWeeksInRange(dateRange);
    
    // Calculate hours by week and month
    final hoursByWeek = await _calculateHoursByWeek(staffId, dateRange);
    final hoursByMonth = await _calculateHoursByMonth(staffId, dateRange);
    
    // Calculate activity distribution
    final activityDistribution = await calculateActivityDistribution(staffId, dateRange);
    final hoursByActivity = activityDistribution.map(
      (key, value) => MapEntry(key.toString().split('.').last, value)
    );
    
    // Determine trend
    final trend = await getWorkloadTrend(staffId, dateRange);
    
    // Generate alerts
    final alerts = await generateWorkloadAlerts(staffId, dateRange);
    
    return WorkloadAnalytics(
      staffId: staffId,
      staffName: staffMember.name,
      department: staffMember.department,
      periodStart: dateRange.startDate,
      periodEnd: dateRange.endDate,
      totalWorkingHours: totalHours,
      weeklyAverageHours: weeklyAverage,
      hoursByWeek: hoursByWeek,
      hoursByMonth: hoursByMonth,
      hoursByActivity: hoursByActivity,
      trend: trend,
      alerts: alerts,
    );
  }

  @override
  Future<TeachingAnalytics> getTeachingAnalytics(
    String staffId, 
    String semester
  ) async {
    _ensureInitialized();
    
    final workloadData = _workloadBox!.get('${staffId}_$semester');
    if (workloadData == null) {
      throw Exception('No workload data found for staff $staffId in semester $semester');
    }
    
    // Calculate total periods allocated
    final totalPeriods = workloadData.periodsPerSubject.values
        .fold<int>(0, (sum, periods) => sum + periods);
    
    // Calculate total classes assigned
    final totalClasses = workloadData.classesPerGrade.values
        .fold<int>(0, (sum, classes) => sum + classes.length);
    
    // Build subject allocations
    final subjectAllocations = <String, SubjectAllocation>{};
    for (final entry in workloadData.periodsPerSubject.entries) {
      final subjectCode = entry.key;
      final periods = entry.value;
      
      // Find classes for this subject
      final classAssignments = <ClassAssignment>[];
      double totalStudents = 0;
      
      for (final gradeEntry in workloadData.classesPerGrade.entries) {
        final grade = _parseGrade(gradeEntry.key);
        for (final className in gradeEntry.value) {
          // Simulate class assignment data
          final studentCount = 30 + Random().nextInt(20); // 30-50 students
          classAssignments.add(ClassAssignment(
            className: className,
            grade: grade,
            section: 'A', // Default section
            studentCount: studentCount,
            periodsAssigned: periods ~/ gradeEntry.value.length,
          ));
          totalStudents += studentCount;
        }
      }
      
      subjectAllocations[subjectCode] = SubjectAllocation(
        subjectCode: subjectCode,
        subjectName: subjectCode, // Use code as name for now
        periodsPerWeek: periods,
        totalPeriods: periods * 16, // Assuming 16 weeks per semester
        classAssignments: classAssignments,
        studentCount: totalStudents,
        type: SubjectType.theory, // Default type
      );
    }
    
    // Build class allocations
    final classAllocations = <String, ClassAllocation>{};
    for (final gradeEntry in workloadData.classesPerGrade.entries) {
      final grade = _parseGrade(gradeEntry.key);
      for (final className in gradeEntry.value) {
        final studentCount = 30 + Random().nextInt(20);
        final periodsAssigned = workloadData.periodsPerSubject.values
            .fold<int>(0, (sum, periods) => sum + periods) ~/ gradeEntry.value.length;
        
        classAllocations[className] = ClassAllocation(
          className: className,
          grade: grade,
          section: 'A',
          studentCount: studentCount,
          periodsAssigned: periodsAssigned,
          subjects: workloadData.periodsPerSubject.keys.toList(),
          type: ClassType.regular,
        );
      }
    }
    
    // Calculate grade distribution
    final gradeDistribution = <Grade, int>{};
    for (final gradeEntry in workloadData.classesPerGrade.entries) {
      final grade = _parseGrade(gradeEntry.key);
      gradeDistribution[grade] = gradeEntry.value.length;
    }
    
    // Calculate average class size
    final averageClassSize = classAllocations.values.isEmpty 
        ? 0.0 
        : classAllocations.values
            .map((c) => c.studentCount)
            .reduce((a, b) => a + b) / classAllocations.length;
    
    // Calculate teaching efficiency
    final efficiency = TeachingEfficiency(
      periodsUtilizationRate: totalPeriods / 40.0, // Assuming 40 periods max
      averageStudentsPerPeriod: averageClassSize,
      subjectDiversityIndex: subjectAllocations.length / 10.0, // Normalized
      gradeLevelSpread: gradeDistribution.length / 12.0, // 12 grades max
    );
    
    return TeachingAnalytics(
      staffId: staffId,
      semester: semester,
      totalPeriodsAllocated: totalPeriods,
      totalClassesAssigned: totalClasses,
      subjectAllocations: subjectAllocations,
      classAllocations: classAllocations,
      gradeDistribution: gradeDistribution,
      averageClassSize: averageClassSize,
      efficiency: efficiency,
    );
  }

  @override
  Future<TimeAllocationAnalytics> getTimeAllocationAnalytics(
    String staffId, 
    DateRange dateRange
  ) async {
    _ensureInitialized();
    
    // Calculate time by activity
    final activityDistribution = await calculateActivityDistribution(staffId, dateRange);
    final timeByActivity = <ActivityType, Duration>{};
    final totalHours = await calculateWorkingHours(staffId, dateRange);
    
    for (final entry in activityDistribution.entries) {
      final hours = entry.value;
      timeByActivity[entry.key] = Duration(minutes: (hours * 60).round());
    }
    
    // Calculate time by day (simplified)
    final timeByDay = <int, Duration>{};
    final dailyHours = totalHours / 7; // Distribute evenly across week
    for (int i = 1; i <= 7; i++) {
      timeByDay[i] = Duration(minutes: (dailyHours * 60).round());
    }
    
    // Calculate percentages
    final teachingHours = activityDistribution[ActivityType.teaching] ?? 0;
    final adminHours = activityDistribution[ActivityType.administrative] ?? 0;
    final odHours = activityDistribution[ActivityType.odProcessing] ?? 0;
    final otherHours = totalHours - teachingHours - adminHours - odHours;
    
    return TimeAllocationAnalytics(
      timeByActivity: timeByActivity,
      timeByDay: timeByDay,
      scheduleBreakdown: {}, // Simplified for now
      teachingPercentage: (teachingHours / totalHours) * 100,
      administrativePercentage: (adminHours / totalHours) * 100,
      odProcessingPercentage: (odHours / totalHours) * 100,
      otherActivitiesPercentage: (otherHours / totalHours) * 100,
      conflicts: [], // No conflicts detected for now
    );
  }

  @override
  Future<EfficiencyMetrics> getEfficiencyMetrics(
    String staffId, 
    DateRange dateRange
  ) async {
    _ensureInitialized();
    
    // Get OD requests processed by this staff member
    final odRequests = _odRequestsBox!.values
        .where((od) => od.staffId == staffId)
        .where((od) => od.createdAt.isAfter(dateRange.startDate) && 
                      od.createdAt.isBefore(dateRange.endDate))
        .toList();
    
    if (odRequests.isEmpty) {
      return const EfficiencyMetrics(
        averageODProcessingTime: 0,
        odApprovalRate: 0,
        odResponseTime: 0,
        totalODsProcessed: 0,
        odsByStatus: {},
        studentSatisfactionScore: 0,
        departmentComparison: ComparisonMetrics(
          averageProcessingTime: 0,
          averageApprovalRate: 0,
          averageResponseTime: 0,
          percentileRank: 0,
        ),
        institutionComparison: ComparisonMetrics(
          averageProcessingTime: 0,
          averageApprovalRate: 0,
          averageResponseTime: 0,
          percentileRank: 0,
        ),
      );
    }
    
    // Calculate processing times
    final processingTimes = <double>[];
    final responseTimes = <double>[];
    final odsByStatus = <String, int>{};
    
    for (final od in odRequests) {
      // Count by status
      odsByStatus[od.status] = (odsByStatus[od.status] ?? 0) + 1;
      
      // Calculate processing time (creation to decision)
      if (od.approvedAt != null) {
        final processingHours = od.approvedAt!.difference(od.createdAt).inHours.toDouble();
        processingTimes.add(processingHours);
      }
      
      // Calculate response time (creation to first response)
      if (od.approvedAt != null) {
        final responseHours = od.approvedAt!.difference(od.createdAt).inHours.toDouble();
        responseTimes.add(responseHours);
      }
    }
    
    final averageProcessingTime = processingTimes.isEmpty 
        ? 0.0 
        : processingTimes.reduce((a, b) => a + b) / processingTimes.length;
    
    final averageResponseTime = responseTimes.isEmpty 
        ? 0.0 
        : responseTimes.reduce((a, b) => a + b) / responseTimes.length;
    
    final approvedCount = odsByStatus['approved'] ?? 0;
    final approvalRate = odRequests.isEmpty 
        ? 0.0 
        : (approvedCount / odRequests.length) * 100;
    
    // Simulate satisfaction score (would come from surveys in real implementation)
    final satisfactionScore = 75.0 + Random().nextDouble() * 20; // 75-95%
    
    // Get department and institution comparisons (simplified)
    final departmentComparison = await _getDepartmentComparison(staffId);
    final institutionComparison = await _getInstitutionComparison(staffId);
    
    return EfficiencyMetrics(
      averageODProcessingTime: averageProcessingTime,
      odApprovalRate: approvalRate,
      odResponseTime: averageResponseTime,
      totalODsProcessed: odRequests.length,
      odsByStatus: odsByStatus,
      studentSatisfactionScore: satisfactionScore,
      departmentComparison: departmentComparison,
      institutionComparison: institutionComparison,
    );
  }

  @override
  Future<ComparativeAnalytics> getComparativeAnalytics(
    String staffId, 
    List<String> semesters
  ) async {
    _ensureInitialized();
    
    final semesterComparisons = <SemesterComparison>[];
    
    for (final semester in semesters) {
      final workloadData = _workloadBox!.get('${staffId}_$semester');
      if (workloadData != null) {
        final periodsAllocated = workloadData.periodsPerSubject.values
            .fold<int>(0, (sum, periods) => sum + periods);
        
        semesterComparisons.add(SemesterComparison(
          semester: semester,
          workingHours: workloadData.totalWorkingHours,
          periodsAllocated: periodsAllocated,
          efficiencyScore: 75.0 + Random().nextDouble() * 20, // Simulated
          satisfactionScore: 80.0 + Random().nextDouble() * 15, // Simulated
        ));
      }
    }
    
    // Generate trend analyses (simplified)
    final workloadTrend = TrendAnalysis(
      metric: 'Working Hours',
      points: semesterComparisons.map((s) => TrendPoint(
        period: s.semester,
        value: s.workingHours,
        timestamp: DateTime.now(), // Simplified
      )).toList(),
      slope: 0.5, // Simulated positive trend
      direction: 'improving',
      confidence: 0.85,
    );
    
    final efficiencyTrend = TrendAnalysis(
      metric: 'Efficiency Score',
      points: semesterComparisons.map((s) => TrendPoint(
        period: s.semester,
        value: s.efficiencyScore,
        timestamp: DateTime.now(),
      )).toList(),
      slope: 0.3,
      direction: 'stable',
      confidence: 0.75,
    );
    
    final satisfactionTrend = TrendAnalysis(
      metric: 'Student Satisfaction',
      points: semesterComparisons.map((s) => TrendPoint(
        period: s.semester,
        value: s.satisfactionScore,
        timestamp: DateTime.now(),
      )).toList(),
      slope: 0.8,
      direction: 'improving',
      confidence: 0.90,
    );
    
    return ComparativeAnalytics(
      staffId: staffId,
      semesterComparisons: semesterComparisons,
      workloadTrend: workloadTrend,
      efficiencyTrend: efficiencyTrend,
      studentSatisfactionTrend: satisfactionTrend,
      improvements: [], // Would be calculated based on trends
      declines: [], // Would be calculated based on trends
    );
  }

  @override
  Future<DepartmentBenchmarks> getDepartmentBenchmarks(
    String department, 
    String semester
  ) async {
    _ensureInitialized();
    
    // Get all staff members in the department
    final departmentStaff = _staffMembersBox!.values
        .where((staff) => staff.department == department)
        .toList();
    
    if (departmentStaff.isEmpty) {
      throw Exception('No staff found in department: $department');
    }
    
    // Calculate averages across department
    double totalWorkingHours = 0;
    double totalPeriodsAllocated = 0;
    int staffCount = 0;
    
    final subjectDistribution = <String, double>{};
    final gradeDistribution = <Grade, double>{};
    
    for (final staff in departmentStaff) {
      final workloadData = _workloadBox!.get('${staff.id}_$semester');
      if (workloadData != null) {
        totalWorkingHours += workloadData.totalWorkingHours;
        
        final periods = workloadData.periodsPerSubject.values
            .fold<int>(0, (sum, p) => sum + p);
        totalPeriodsAllocated += periods;
        
        // Count subjects
        for (final subject in workloadData.periodsPerSubject.keys) {
          subjectDistribution[subject] = (subjectDistribution[subject] ?? 0) + 1;
        }
        
        // Count grades
        for (final gradeKey in workloadData.classesPerGrade.keys) {
          final grade = _parseGrade(gradeKey);
          gradeDistribution[grade] = (gradeDistribution[grade] ?? 0) + 1;
        }
        
        staffCount++;
      }
    }
    
    return DepartmentBenchmarks(
      department: department,
      semester: semester,
      averageWorkingHours: staffCount > 0 ? totalWorkingHours / staffCount : 0,
      averagePeriodsAllocated: staffCount > 0 ? totalPeriodsAllocated / staffCount : 0,
      averageEfficiencyScore: 78.5, // Simulated
      averageSatisfactionScore: 82.3, // Simulated
      subjectDistribution: subjectDistribution.map((k, v) => MapEntry(k, v / staffCount)),
      gradeDistribution: gradeDistribution.map((k, v) => MapEntry(k, v / staffCount)),
    );
  }

  @override
  Future<StaffPerformanceReport> generatePerformanceReport(
    String staffId, 
    ReportOptions options
  ) async {
    _ensureInitialized();
    
    final staffMember = _staffMembersBox!.get(staffId);
    if (staffMember == null) {
      throw Exception('Staff member not found: $staffId');
    }
    
    final dateRange = DateRange(
      startDate: DateTime.now().subtract(const Duration(days: 180)), // Last 6 months
      endDate: DateTime.now(),
    );
    
    final workloadSummary = await getWorkloadAnalytics(staffId, dateRange);
    final teachingSummary = await getTeachingAnalytics(staffId, 'current');
    final efficiencyMetrics = await getEfficiencyMetrics(staffId, dateRange);
    
    // Generate insights based on data
    final strengths = <String>[];
    final improvementAreas = <String>[];
    final recommendations = <String>[];
    
    // Analyze workload
    if (workloadSummary.weeklyAverageHours > 35) {
      strengths.add('High commitment with ${workloadSummary.weeklyAverageHours.toStringAsFixed(1)} hours per week');
    } else if (workloadSummary.weeklyAverageHours < 25) {
      improvementAreas.add('Low weekly hours (${workloadSummary.weeklyAverageHours.toStringAsFixed(1)})');
      recommendations.add('Consider taking on additional responsibilities');
    }
    
    // Analyze efficiency
    if (efficiencyMetrics.odApprovalRate > 80) {
      strengths.add('High OD approval rate (${efficiencyMetrics.odApprovalRate.toStringAsFixed(1)}%)');
    } else if (efficiencyMetrics.odApprovalRate < 60) {
      improvementAreas.add('Low OD approval rate (${efficiencyMetrics.odApprovalRate.toStringAsFixed(1)}%)');
      recommendations.add('Review OD approval criteria and provide feedback to students');
    }
    
    // Analyze response time
    if (efficiencyMetrics.odResponseTime < 24) {
      strengths.add('Quick response time (${efficiencyMetrics.odResponseTime.toStringAsFixed(1)} hours)');
    } else if (efficiencyMetrics.odResponseTime > 72) {
      improvementAreas.add('Slow response time (${efficiencyMetrics.odResponseTime.toStringAsFixed(1)} hours)');
      recommendations.add('Aim to respond to OD requests within 48 hours');
    }
    
    return StaffPerformanceReport(
      staffId: staffId,
      staffName: staffMember.name,
      department: staffMember.department,
      reportPeriod: dateRange,
      workloadSummary: workloadSummary,
      teachingSummary: teachingSummary,
      efficiencyMetrics: efficiencyMetrics,
      strengths: strengths,
      improvementAreas: improvementAreas,
      recommendations: recommendations,
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<double> calculateWorkingHours(
    String staffId, 
    DateRange dateRange
  ) async {
    _ensureInitialized();
    
    // Get workload data for the period
    final workloadData = await _getWorkloadDataForPeriod(staffId, dateRange);
    
    if (workloadData == null) {
      return 0.0;
    }
    
    // Calculate total periods per week
    final totalPeriodsPerWeek = workloadData.periodsPerSubject.values
        .fold<int>(0, (sum, periods) => sum + periods);
    
    // Assume each period is 1 hour, plus additional time for preparation and evaluation
    final teachingHours = totalPeriodsPerWeek.toDouble();
    final preparationHours = teachingHours * 0.5; // 50% additional time for preparation
    final evaluationHours = teachingHours * 0.3; // 30% additional time for evaluation
    const administrativeHours = 5.0; // Fixed 5 hours per week for administrative tasks
    
    final weeklyHours = teachingHours + preparationHours + evaluationHours + administrativeHours;
    final weeksInRange = _getWeeksInRange(dateRange);
    
    return weeklyHours * weeksInRange;
  }

  @override
  Future<Map<ActivityType, double>> calculateActivityDistribution(
    String staffId, 
    DateRange dateRange
  ) async {
    _ensureInitialized();
    
    final totalHours = await calculateWorkingHours(staffId, dateRange);
    
    if (totalHours == 0) {
      return {};
    }
    
    // Get workload data to calculate distribution
    final workloadData = await _getWorkloadDataForPeriod(staffId, dateRange);
    
    if (workloadData == null) {
      return {};
    }
    
    final totalPeriodsPerWeek = workloadData.periodsPerSubject.values
        .fold<int>(0, (sum, periods) => sum + periods);
    
    final weeksInRange = _getWeeksInRange(dateRange);
    
    // Calculate hours per activity type
    final teachingHours = totalPeriodsPerWeek.toDouble() * weeksInRange;
    final preparationHours = teachingHours * 0.5;
    final evaluationHours = teachingHours * 0.3;
    final administrativeHours = 5.0 * weeksInRange;
    final odProcessingHours = 2.0 * weeksInRange; // Estimated 2 hours per week
    final meetingHours = 3.0 * weeksInRange; // Estimated 3 hours per week
    
    return {
      ActivityType.teaching: teachingHours,
      ActivityType.preparation: preparationHours,
      ActivityType.evaluation: evaluationHours,
      ActivityType.administrative: administrativeHours,
      ActivityType.odProcessing: odProcessingHours,
      ActivityType.meetings: meetingHours,
      ActivityType.other: totalHours - (teachingHours + preparationHours + 
          evaluationHours + administrativeHours + odProcessingHours + meetingHours),
    };
  }

  @override
  Future<WorkloadTrend> getWorkloadTrend(
    String staffId, 
    DateRange dateRange
  ) async {
    _ensureInitialized();
    
    // Get historical data for trend analysis
    final currentHours = await calculateWorkingHours(staffId, dateRange);
    
    // Get previous period for comparison
    final previousPeriod = DateRange(
      startDate: dateRange.startDate.subtract(dateRange.endDate.difference(dateRange.startDate)),
      endDate: dateRange.startDate,
    );
    
    final previousHours = await calculateWorkingHours(staffId, previousPeriod);
    
    if (previousHours == 0) {
      return WorkloadTrend.stable;
    }
    
    final changePercentage = ((currentHours - previousHours) / previousHours) * 100;
    
    if (changePercentage > 10) {
      return WorkloadTrend.increasing;
    } else if (changePercentage < -10) {
      return WorkloadTrend.decreasing;
    } else {
      return WorkloadTrend.stable;
    }
  }

  @override
  Future<List<WorkloadAlert>> generateWorkloadAlerts(
    String staffId, 
    DateRange dateRange
  ) async {
    _ensureInitialized();
    
    final alerts = <WorkloadAlert>[];
    final workingHours = await calculateWorkingHours(staffId, dateRange);
    final weeklyAverage = workingHours / _getWeeksInRange(dateRange);
    
    // Check for overwork
    if (weeklyAverage > 50) {
      alerts.add(WorkloadAlert(
        id: '${staffId}_overwork_${DateTime.now().millisecondsSinceEpoch}',
        message: 'High workload detected: ${weeklyAverage.toStringAsFixed(1)} hours per week',
        severity: 'high',
        timestamp: DateTime.now(),
      ));
    }
    
    // Check for underwork
    if (weeklyAverage < 20) {
      alerts.add(WorkloadAlert(
        id: '${staffId}_underwork_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Low workload detected: ${weeklyAverage.toStringAsFixed(1)} hours per week',
        severity: 'medium',
        timestamp: DateTime.now(),
      ));
    }
    
    // Check activity distribution
    final activityDistribution = await calculateActivityDistribution(staffId, dateRange);
    final teachingPercentage = (activityDistribution[ActivityType.teaching] ?? 0) / workingHours * 100;
    
    if (teachingPercentage < 40) {
      alerts.add(WorkloadAlert(
        id: '${staffId}_low_teaching_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Low teaching percentage: ${teachingPercentage.toStringAsFixed(1)}%',
        severity: 'medium',
        timestamp: DateTime.now(),
      ));
    }
    
    return alerts;
  }

  @override
  Future<void> storeWorkloadData(StaffWorkloadData data) async {
    _ensureInitialized();
    
    final key = '${data.staffId}_${data.semester}';
    await _workloadBox!.put(key, data);
  }

  @override
  Future<StaffWorkloadData?> getWorkloadData(String staffId, String semester) async {
    _ensureInitialized();
    
    final key = '${staffId}_$semester';
    return _workloadBox!.get(key);
  }

  @override
  Future<void> updateWorkloadData(String staffId, StaffWorkloadData data) async {
    _ensureInitialized();
    
    final key = '${staffId}_${data.semester}';
    await _workloadBox!.put(key, data);
  }

  @override
  Future<void> deleteWorkloadData(String staffId, String semester) async {
    _ensureInitialized();
    
    final key = '${staffId}_$semester';
    await _workloadBox!.delete(key);
  }

  @override
  Future<void> refreshAnalyticsCache() async {
    _ensureInitialized();
    
    // Clear analytics cache to force recalculation
    await _analyticsBox!.clear();
  }

  // Helper methods
  
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('HiveStaffAnalyticsService not initialized. Call initialize() first.');
    }
  }

  Future<StaffWorkloadData?> _getWorkloadDataForPeriod(
    String staffId, 
    DateRange dateRange
  ) async {
    // For now, get the most recent semester data
    // In a real implementation, this would filter by date range
    final keys = _workloadBox!.keys
        .where((key) => key.toString().startsWith(staffId))
        .toList();
    
    if (keys.isEmpty) return null;
    
    // Get the most recent data
    keys.sort();
    return _workloadBox!.get(keys.last);
  }

  double _getWeeksInRange(DateRange dateRange) {
    final days = dateRange.endDate.difference(dateRange.startDate).inDays;
    return days / 7.0;
  }

  Future<Map<String, double>> _calculateHoursByWeek(
    String staffId, 
    DateRange dateRange
  ) async {
    final totalHours = await calculateWorkingHours(staffId, dateRange);
    final weeks = _getWeeksInRange(dateRange);
    final hoursPerWeek = totalHours / weeks;
    
    final result = <String, double>{};
    final startDate = dateRange.startDate;
    
    for (int i = 0; i < weeks.ceil(); i++) {
      final weekStart = startDate.add(Duration(days: i * 7));
      final weekKey = 'Week ${i + 1} (${weekStart.month}/${weekStart.day})';
      result[weekKey] = hoursPerWeek;
    }
    
    return result;
  }

  Future<Map<String, double>> _calculateHoursByMonth(
    String staffId, 
    DateRange dateRange
  ) async {
    final totalHours = await calculateWorkingHours(staffId, dateRange);
    final months = (dateRange.endDate.year - dateRange.startDate.year) * 12 + 
                   dateRange.endDate.month - dateRange.startDate.month + 1;
    final hoursPerMonth = totalHours / months;
    
    final result = <String, double>{};
    var currentDate = DateTime(dateRange.startDate.year, dateRange.startDate.month);
    
    for (int i = 0; i < months; i++) {
      final monthKey = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}';
      result[monthKey] = hoursPerMonth;
      currentDate = DateTime(currentDate.year, currentDate.month + 1);
    }
    
    return result;
  }

  Grade _parseGrade(String gradeString) {
    switch (gradeString.toLowerCase()) {
      case 'grade1': return Grade.grade1;
      case 'grade2': return Grade.grade2;
      case 'grade3': return Grade.grade3;
      case 'grade4': return Grade.grade4;
      case 'grade5': return Grade.grade5;
      case 'grade6': return Grade.grade6;
      case 'grade7': return Grade.grade7;
      case 'grade8': return Grade.grade8;
      case 'grade9': return Grade.grade9;
      case 'grade10': return Grade.grade10;
      case 'grade11': return Grade.grade11;
      case 'grade12': return Grade.grade12;
      case 'post_graduate': return Grade.postGraduate;
      default: return Grade.grade1;
    }
  }

  Future<ComparisonMetrics> _getDepartmentComparison(String staffId) async {
    // Simplified implementation - would calculate actual department averages
    return const ComparisonMetrics(
      averageProcessingTime: 48.5,
      averageApprovalRate: 75.2,
      averageResponseTime: 36.8,
      percentileRank: 68.5,
    );
  }

  Future<ComparisonMetrics> _getInstitutionComparison(String staffId) async {
    // Simplified implementation - would calculate actual institution averages
    return const ComparisonMetrics(
      averageProcessingTime: 52.1,
      averageApprovalRate: 72.8,
      averageResponseTime: 41.2,
      percentileRank: 71.3,
    );
  }
}