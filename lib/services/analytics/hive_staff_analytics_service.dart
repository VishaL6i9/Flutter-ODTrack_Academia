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
  final Box<StaffWorkloadData> _workloadBox = Hive.box<StaffWorkloadData>('staff_workload_data');
  final Box<ODRequest> _odRequestsBox = Hive.box<ODRequest>('od_requests');
  final Box<StaffMember> _staffMembersBox = Hive.box<StaffMember>('staff_members');
  
  @override
  Future<void> initialize() async {
    // All boxes are opened in main.dart, so no need to open them here.
    // This method can be used for any other service-specific initialization.
    return Future.value();
  }

  @override
  Future<bool> staffExists(String staffId) async {
    return _staffMembersBox.containsKey(staffId);
  }

  @override
  Future<StaffMember?> findStaffByEmail(String email) async {
    for (final staff in _staffMembersBox.values) {
      if (staff.email == email) {
        return staff;
      }
    }
    return null;
  }

  @override
  Future<String?> getFirstStaffId() async {
    if (_staffMembersBox.isNotEmpty) {
      return _staffMembersBox.keys.first as String?;
    }
    return null;
  }

  @override
  Future<WorkloadAnalytics> getWorkloadAnalytics(
    String staffId, 
    DateRange dateRange
  ) async {
    // Debugging: Print staffId and box keys
    print('Attempting to get staff member with ID: $staffId');
    print('Staff members box keys: ${_staffMembersBox.keys.toList()}');

    final staffMember = _staffMembersBox.get(staffId);
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
    final workloadData = _workloadBox.get('${staffId}_$semester');
    if (workloadData == null) {
      throw Exception('No workload data found for staff $staffId in semester $semester');
    }
    
    // Calculate total periods allocated across all subjects
    final totalPeriods = workloadData.periodsPerSubject.values
        .fold<int>(0, (sum, periods) => sum + periods);
    
    // Calculate total classes assigned across all grades
    final totalClasses = workloadData.classesPerGrade.values
        .fold<int>(0, (sum, classes) => sum + classes.length);
    
    // Build comprehensive subject allocations with detailed analytics
    final subjectAllocations = <String, SubjectAllocation>{};
    for (final entry in workloadData.periodsPerSubject.entries) {
      final subjectCode = entry.key;
      final periodsPerWeek = entry.value;
      
      // Calculate class assignments for this subject across all grades
      final classAssignments = <ClassAssignment>[];
      double totalStudentsForSubject = 0;
      int totalPeriodsForSubject = 0;
      
      // Distribute periods across classes based on grade enrollment
      for (final gradeEntry in workloadData.classesPerGrade.entries) {
        final grade = _parseGrade(gradeEntry.key);
        final classesInGrade = gradeEntry.value;
        
        // Calculate periods per class for this subject in this grade
        final periodsPerClass = periodsPerWeek ~/ classesInGrade.length;
        final remainderPeriods = periodsPerWeek % classesInGrade.length;
        
        for (int i = 0; i < classesInGrade.length; i++) {
          final className = classesInGrade[i];
          
          // Generate realistic student count based on grade level
          final baseStudentCount = _getBaseStudentCountForGrade(grade);
          final variation = Random().nextInt(10) - 5; // ±5 students variation
          final studentCount = (baseStudentCount + variation).clamp(15, 50);
          
          // Assign extra period to first few classes if there's remainder
          final assignedPeriods = periodsPerClass + (i < remainderPeriods ? 1 : 0);
          
          classAssignments.add(ClassAssignment(
            className: className,
            grade: grade,
            section: _extractSection(className),
            studentCount: studentCount,
            periodsAssigned: assignedPeriods,
          ));
          
          totalStudentsForSubject += studentCount;
          totalPeriodsForSubject += assignedPeriods;
        }
      }
      
      // Determine subject type based on subject code patterns
      final subjectType = _determineSubjectType(subjectCode);
      
      subjectAllocations[subjectCode] = SubjectAllocation(
        subjectCode: subjectCode,
        subjectName: _getSubjectName(subjectCode),
        periodsPerWeek: periodsPerWeek,
        totalPeriods: totalPeriodsForSubject * 16, // 16 weeks per semester
        classAssignments: classAssignments,
        studentCount: totalStudentsForSubject,
        type: subjectType,
      );
    }
    
    // Build comprehensive class allocations with detailed analytics
    final classAllocations = <String, ClassAllocation>{};
    for (final gradeEntry in workloadData.classesPerGrade.entries) {
      final grade = _parseGrade(gradeEntry.key);
      final classesInGrade = gradeEntry.value;
      
      for (final className in classesInGrade) {
        // Calculate total periods assigned to this class across all subjects
        int totalPeriodsForClass = 0;
        final subjectsForClass = <String>[];
        
        for (final subjectEntry in workloadData.periodsPerSubject.entries) {
          final subjectCode = subjectEntry.key;
          final subjectPeriods = subjectEntry.value;
          
          // Calculate this class's share of the subject periods
          final classShare = subjectPeriods ~/ classesInGrade.length;
          final remainder = subjectPeriods % classesInGrade.length;
          final classIndex = classesInGrade.indexOf(className);
          final assignedPeriods = classShare + (classIndex < remainder ? 1 : 0);
          
          if (assignedPeriods > 0) {
            totalPeriodsForClass += assignedPeriods;
            subjectsForClass.add(subjectCode);
          }
        }
        
        // Generate realistic student count for this class
        final baseStudentCount = _getBaseStudentCountForGrade(grade);
        final variation = Random().nextInt(8) - 4; // ±4 students variation
        final studentCount = (baseStudentCount + variation).clamp(15, 50);
        
        // Determine class type based on naming patterns
        final classType = _determineClassType(className);
        
        classAllocations[className] = ClassAllocation(
          className: className,
          grade: grade,
          section: _extractSection(className),
          studentCount: studentCount,
          periodsAssigned: totalPeriodsForClass,
          subjects: subjectsForClass,
          type: classType,
        );
      }
    }
    
    // Calculate detailed grade distribution with analytics
    final gradeDistribution = <Grade, int>{};
    final gradeStudentCounts = <Grade, int>{};
    
    for (final gradeEntry in workloadData.classesPerGrade.entries) {
      final grade = _parseGrade(gradeEntry.key);
      final classCount = gradeEntry.value.length;
      gradeDistribution[grade] = classCount;
      
      // Calculate total students in this grade
      int totalStudentsInGrade = 0;
      for (final className in gradeEntry.value) {
        final classAllocation = classAllocations[className];
        if (classAllocation != null) {
          totalStudentsInGrade += classAllocation.studentCount;
        }
      }
      gradeStudentCounts[grade] = totalStudentsInGrade;
    }
    
    // Calculate comprehensive class size analytics
    final classSizes = classAllocations.values.map((c) => c.studentCount).toList();
    final averageClassSize = classSizes.isEmpty 
        ? 0.0 
        : classSizes.reduce((a, b) => a + b) / classSizes.length;
    
    // Calculate teaching efficiency with enhanced metrics
    const maxPossiblePeriods = 40.0; // Standard maximum periods per week
    final periodsUtilizationRate = totalPeriods / maxPossiblePeriods;
    
    // Calculate subject diversity (variety of subjects taught)
    final subjectDiversityIndex = subjectAllocations.length / 10.0; // Normalized to 0-1
    
    // Calculate grade level spread (variety of grades taught)
    final gradeLevelSpread = gradeDistribution.length / 12.0; // 12 possible grades
    
    // Calculate student load efficiency
    final totalStudents = classSizes.fold<int>(0, (sum, size) => sum + size);
    final averageStudentsPerPeriod = totalPeriods > 0 ? totalStudents / totalPeriods : 0.0;
    
    final efficiency = TeachingEfficiency(
      periodsUtilizationRate: periodsUtilizationRate,
      averageStudentsPerPeriod: averageStudentsPerPeriod,
      subjectDiversityIndex: subjectDiversityIndex,
      gradeLevelSpread: gradeLevelSpread,
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
    // Get OD requests processed by this staff member
    final odRequests = _odRequestsBox.values
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

  /// Calculate comparative benchmarks with department and institution
  @override
  Future<Map<String, ComparisonMetrics>> calculateComparativeBenchmarks(
    String staffId, 
    DateRange dateRange
  ) async {
    final staffMember = _staffMembersBox.get(staffId);
    if (staffMember == null) {
      throw Exception('Staff member not found: $staffId');
    }
    
    final staffMetrics = await getEfficiencyMetrics(staffId, dateRange);
    
    // Calculate department benchmarks
    final departmentStaff = _staffMembersBox.values
        .where((staff) => staff.department == staffMember.department && staff.id != staffId)
        .toList();
    
    final departmentMetrics = await _calculateAggregateMetrics(departmentStaff, dateRange);
    
    // Calculate institution benchmarks (all staff except current)
    final allStaff = _staffMembersBox.values
        .where((staff) => staff.id != staffId)
        .toList();
    
    final institutionMetrics = await _calculateAggregateMetrics(allStaff, dateRange);
    
    // Calculate percentile ranks
    final departmentProcessingTimes = await _getProcessingTimesForStaff(departmentStaff, dateRange);
    final institutionProcessingTimes = await _getProcessingTimesForStaff(allStaff, dateRange);
    
    final departmentPercentile = _calculatePercentileRank(
      staffMetrics.averageODProcessingTime, 
      departmentProcessingTimes
    );
    
    final institutionPercentile = _calculatePercentileRank(
      staffMetrics.averageODProcessingTime, 
      institutionProcessingTimes
    );
    
    return {
      'department': ComparisonMetrics(
        averageProcessingTime: departmentMetrics['avgProcessingTime'] ?? 0.0,
        averageApprovalRate: departmentMetrics['avgApprovalRate'] ?? 0.0,
        averageResponseTime: departmentMetrics['avgResponseTime'] ?? 0.0,
        percentileRank: departmentPercentile,
      ),
      'institution': ComparisonMetrics(
        averageProcessingTime: institutionMetrics['avgProcessingTime'] ?? 0.0,
        averageApprovalRate: institutionMetrics['avgApprovalRate'] ?? 0.0,
        averageResponseTime: institutionMetrics['avgResponseTime'] ?? 0.0,
        percentileRank: institutionPercentile,
      ),
    };
  }

  /// Calculate aggregate metrics for a group of staff members
  Future<Map<String, double>> _calculateAggregateMetrics(
    List<StaffMember> staffList, 
    DateRange dateRange
  ) async {
    if (staffList.isEmpty) {
      return {
        'avgProcessingTime': 0.0,
        'avgApprovalRate': 0.0,
        'avgResponseTime': 0.0,
      };
    }
    
    double totalProcessingTime = 0.0;
    double totalApprovalRate = 0.0;
    double totalResponseTime = 0.0;
    int validStaffCount = 0;
    
    for (final staff in staffList) {
      try {
        final metrics = await getEfficiencyMetrics(staff.id, dateRange);
        if (metrics.totalODsProcessed > 0) {
          totalProcessingTime += metrics.averageODProcessingTime;
          totalApprovalRate += metrics.odApprovalRate;
          totalResponseTime += metrics.odResponseTime;
          validStaffCount++;
        }
      } catch (e) {
        // Skip staff members with no data
        continue;
      }
    }
    
    if (validStaffCount == 0) {
      return {
        'avgProcessingTime': 0.0,
        'avgApprovalRate': 0.0,
        'avgResponseTime': 0.0,
      };
    }
    
    return {
      'avgProcessingTime': totalProcessingTime / validStaffCount,
      'avgApprovalRate': totalApprovalRate / validStaffCount,
      'avgResponseTime': totalResponseTime / validStaffCount,
    };
  }

  /// Get processing times for a list of staff members
  Future<List<double>> _getProcessingTimesForStaff(
    List<StaffMember> staffList, 
    DateRange dateRange
  ) async {
    final processingTimes = <double>[];
    
    for (final staff in staffList) {
      try {
        final metrics = await getEfficiencyMetrics(staff.id, dateRange);
        if (metrics.totalODsProcessed > 0) {
          processingTimes.add(metrics.averageODProcessingTime);
        }
      } catch (e) {
        // Skip staff members with no data
        continue;
      }
    }
    
    return processingTimes;
  }

  /// Calculate percentile rank for a value in a dataset
  double _calculatePercentileRank(double value, List<double> dataset) {
    if (dataset.isEmpty) return 0.0;
    
    dataset.sort();
    int countBelow = dataset.where((v) => v < value).length;
    int countEqual = dataset.where((v) => v == value).length;
    
    // Use the standard percentile rank formula
    return ((countBelow + 0.5 * countEqual) / dataset.length) * 100;
  }

  /// Enhanced time conflict detection
  @override
  Future<List<TimeConflict>> detectTimeConflicts(
    String staffId, 
    DateRange dateRange
  ) async {
    final conflicts = <TimeConflict>[];
    final workloadData = await _getWorkloadDataForPeriod(staffId, dateRange);
    
    if (workloadData == null) return conflicts;
    
    // Check for schedule conflicts in weekly timetable
    for (final dayEntry in workloadData.weeklySchedule.entries) {
      final dayPeriods = dayEntry.value;
      
      // Group periods by time slot to detect overlaps
      final timeSlotGroups = <String, List<Period>>{};
      
      for (final period in dayPeriods) {
        final timeKey = '${period.timeSlot.periodNumber}';
        timeSlotGroups[timeKey] = timeSlotGroups[timeKey] ?? [];
        timeSlotGroups[timeKey]!.add(period);
      }
      
      // Check for conflicts (multiple periods at same time)
      for (final entry in timeSlotGroups.entries) {
        if (entry.value.length > 1) {
          final conflictId = '${staffId}_${dayEntry.key}_${entry.key}_${DateTime.now().millisecondsSinceEpoch}';
          
          conflicts.add(TimeConflict(
            id: conflictId,
            description: 'Schedule conflict on ${dayEntry.key} period ${entry.key}',
            conflictTime: entry.value.first.timeSlot.startTime,
            conflictingActivities: entry.value.map((p) => '${p.subjectCode} - ${p.className}').toList(),
            severity: entry.value.length > 2 ? 'high' : 'medium',
          ));
        }
      }
    }
    
    // Check for workload conflicts (excessive hours)
    final totalHours = await calculateWorkingHours(staffId, dateRange);
    final weeklyAverage = totalHours / _getWeeksInRange(dateRange);
    
    if (weeklyAverage > 50) {
      conflicts.add(TimeConflict(
        id: '${staffId}_overload_${DateTime.now().millisecondsSinceEpoch}',
        description: 'Excessive workload: ${weeklyAverage.toStringAsFixed(1)} hours per week',
        conflictTime: DateTime.now(),
        conflictingActivities: ['Teaching', 'Administrative', 'OD Processing'],
        severity: weeklyAverage > 60 ? 'high' : 'medium',
      ));
    }
    
    return conflicts;
  }

  /// Calculate activity efficiency scores
  @override
  Future<Map<ActivityType, double>> calculateActivityEfficiencyScores(
    String staffId, 
    DateRange dateRange
  ) async {
    final activityDistribution = await calculateActivityDistribution(staffId, dateRange);
    final totalHours = await calculateWorkingHours(staffId, dateRange);
    
    final efficiencyScores = <ActivityType, double>{};
    
    if (totalHours == 0) return efficiencyScores;
    
    // Teaching efficiency: Based on student outcomes and period utilization
    final teachingHours = activityDistribution[ActivityType.teaching] ?? 0;
    final teachingPercentage = (teachingHours / totalHours) * 100;
    
    // Optimal teaching percentage is 60-70%
    final teachingEfficiency = teachingPercentage >= 60 && teachingPercentage <= 70 
        ? 10.0 
        : 10.0 - (teachingPercentage - 65).abs() * 0.2;
    
    efficiencyScores[ActivityType.teaching] = teachingEfficiency.clamp(0.0, 10.0);
    
    // OD Processing efficiency: Based on processing speed and quality
    final odHours = activityDistribution[ActivityType.odProcessing] ?? 0;
    final odRequests = _odRequestsBox.values
        .where((od) => od.staffId == staffId)
        .where((od) => od.createdAt.isAfter(dateRange.startDate) && 
                      od.createdAt.isBefore(dateRange.endDate))
        .length;
    
    final odEfficiency = odHours > 0 && odRequests > 0
        ? (odRequests / odHours).clamp(0.0, 10.0) // Requests per hour
        : 0.0;
    
    efficiencyScores[ActivityType.odProcessing] = odEfficiency;
    
    // Administrative efficiency: Based on time allocation balance
    final adminHours = activityDistribution[ActivityType.administrative] ?? 0;
    final adminPercentage = (adminHours / totalHours) * 100;
    
    // Optimal administrative percentage is 10-20%
    final adminEfficiency = adminPercentage >= 10 && adminPercentage <= 20
        ? 10.0
        : 10.0 - (adminPercentage - 15).abs() * 0.3;
    
    efficiencyScores[ActivityType.administrative] = adminEfficiency.clamp(0.0, 10.0);
    
    // Preparation efficiency: Based on ratio to teaching time
    final prepHours = activityDistribution[ActivityType.preparation] ?? 0;
    final prepRatio = teachingHours > 0 ? prepHours / teachingHours : 0;
    
    // Optimal preparation ratio is 0.4-0.8 (40-80% of teaching time)
    final prepEfficiency = prepRatio >= 0.4 && prepRatio <= 0.8
        ? 10.0
        : 10.0 - (prepRatio - 0.6).abs() * 10;
    
    efficiencyScores[ActivityType.preparation] = prepEfficiency.clamp(0.0, 10.0);
    
    // Evaluation efficiency: Based on ratio to teaching time
    final evalHours = activityDistribution[ActivityType.evaluation] ?? 0;
    final evalRatio = teachingHours > 0 ? evalHours / teachingHours : 0;
    
    // Optimal evaluation ratio is 0.2-0.5 (20-50% of teaching time)
    final evalEfficiency = evalRatio >= 0.2 && evalRatio <= 0.5
        ? 10.0
        : 10.0 - (evalRatio - 0.35).abs() * 15;
    
    efficiencyScores[ActivityType.evaluation] = evalEfficiency.clamp(0.0, 10.0);
    
    return efficiencyScores;
  }

  // Implementation of missing abstract methods

  @override
  Future<double> calculateWorkingHours(
    String staffId, 
    DateRange dateRange
  ) async {
    final workloadData = await _getWorkloadDataForPeriod(staffId, dateRange);
    if (workloadData == null) return 0.0;
    
    // Calculate total working hours based on periods allocated
    final totalPeriods = workloadData.periodsPerSubject.values
        .fold<int>(0, (sum, periods) => sum + periods);
    
    // Assume each period is 1 hour (adjust as needed)
    const hoursPerPeriod = 1.0;
    final teachingHours = totalPeriods * hoursPerPeriod;
    
    // Add administrative and other activities (estimated 20% of teaching time)
    final totalHours = teachingHours * 1.2;
    
    return totalHours;
  }

  @override
  Future<Map<ActivityType, double>> calculateActivityDistribution(
    String staffId, 
    DateRange dateRange
  ) async {
    final totalHours = await calculateWorkingHours(staffId, dateRange);
    
    if (totalHours == 0) {
      return {
        ActivityType.teaching: 0,
        ActivityType.administrative: 0,
        ActivityType.odProcessing: 0,
        ActivityType.preparation: 0,
        ActivityType.evaluation: 0,
      };
    }
    
    // Distribute hours across activities based on typical academic workload
    return {
      ActivityType.teaching: totalHours * 0.60, // 60% teaching
      ActivityType.preparation: totalHours * 0.20, // 20% preparation
      ActivityType.evaluation: totalHours * 0.10, // 10% evaluation
      ActivityType.administrative: totalHours * 0.08, // 8% admin
      ActivityType.odProcessing: totalHours * 0.02, // 2% OD processing
    };
  }

  @override
  Future<WorkloadTrend> getWorkloadTrend(
    String staffId, 
    DateRange dateRange
  ) async {
    // Simple trend calculation (in real implementation, would compare with historical data)
    final trendPercentage = Random().nextDouble() * 20 - 10; // ±10%
    
    // Return a simple enum value since WorkloadTrend is an enum, not a class
    return trendPercentage > 5 ? WorkloadTrend.increasing 
         : trendPercentage < -5 ? WorkloadTrend.decreasing 
         : WorkloadTrend.stable;
  }

  @override
  Future<List<WorkloadAlert>> generateWorkloadAlerts(
    String staffId, 
    DateRange dateRange
  ) async {
    final alerts = <WorkloadAlert>[];
    final totalHours = await calculateWorkingHours(staffId, dateRange);
    final weeklyAverage = totalHours / _getWeeksInRange(dateRange);
    
    // Check for excessive workload
    if (weeklyAverage > 50) {
      alerts.add(WorkloadAlert(
        id: '${staffId}_overload_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Excessive Workload Detected: Weekly average of ${weeklyAverage.toStringAsFixed(1)} hours exceeds recommended limits',
        severity: weeklyAverage > 60 ? 'high' : 'medium',
        timestamp: DateTime.now(),
      ));
    }
    
    // Check for underutilization
    if (weeklyAverage < 20) {
      alerts.add(WorkloadAlert(
        id: '${staffId}_underload_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Underutilization Detected: Weekly average of ${weeklyAverage.toStringAsFixed(1)} hours is below expected minimum',
        severity: 'low',
        timestamp: DateTime.now(),
      ));
    }
    
    return alerts;
  }

  @override
  Future<ComparativeAnalytics> getComparativeAnalytics(
    String staffId, 
    List<String> semesters
  ) async {
    // Simplified implementation - would analyze across multiple semesters
    final comparisons = <SemesterComparison>[];
    
    for (final semester in semesters) {
      final workloadData = _workloadBox.get('${staffId}_$semester');
      if (workloadData != null) {
        final totalPeriods = workloadData.periodsPerSubject.values
            .fold<int>(0, (sum, periods) => sum + periods);
        
        comparisons.add(SemesterComparison(
          semester: semester,
          workingHours: totalPeriods.toDouble(),
          periodsAllocated: totalPeriods,
          efficiencyScore: 75.0 + Random().nextDouble() * 20,
          satisfactionScore: 80.0 + Random().nextDouble() * 15,
        ));
      }
    }
    
    return ComparativeAnalytics(
      staffId: staffId,
      semesterComparisons: comparisons,
      workloadTrend: TrendAnalysis(
        metric: 'workload',
        points: [],
        slope: Random().nextDouble() * 2 - 1,
        direction: 'stable',
        confidence: 0.8,
      ),
      efficiencyTrend: TrendAnalysis(
        metric: 'efficiency',
        points: [],
        slope: Random().nextDouble() * 2 - 1,
        direction: 'improving',
        confidence: 0.7,
      ),
      studentSatisfactionTrend: TrendAnalysis(
        metric: 'satisfaction',
        points: [],
        slope: Random().nextDouble() * 2 - 1,
        direction: 'stable',
        confidence: 0.9,
      ),
      improvements: [],
      declines: [],
    );
  }

  @override
  Future<DepartmentBenchmarks> getDepartmentBenchmarks(
    String department, 
    String semester
  ) async {
    // Simplified implementation - would calculate actual department benchmarks
    return DepartmentBenchmarks(
      department: department,
      semester: semester,
      averageWorkingHours: 35.0 + Random().nextDouble() * 10,
      averagePeriodsAllocated: 25.0 + Random().nextDouble() * 10,
      averageEfficiencyScore: 75.0 + Random().nextDouble() * 15,
      averageSatisfactionScore: 80.0 + Random().nextDouble() * 15,
      subjectDistribution: {
        'Mathematics': 25.0,
        'Science': 20.0,
        'English': 15.0,
        'Social Studies': 15.0,
        'Other': 25.0,
      },
      gradeDistribution: {
        Grade.grade9: 20.0,
        Grade.grade10: 25.0,
        Grade.grade11: 25.0,
        Grade.grade12: 30.0,
      },
    );
  }

  @override
  Future<StaffPerformanceReport> generatePerformanceReport(
    String staffId, 
    ReportOptions options
  ) async {
    final staffMember = _staffMembersBox.get(staffId);
    if (staffMember == null) {
      throw Exception('Staff member not found: $staffId');
    }
    
    final dateRange = DateRange(
      startDate: DateTime.now().subtract(const Duration(days: 90)),
      endDate: DateTime.now(),
    );
    
    final workloadAnalytics = options.includeWorkloadAnalysis 
        ? await getWorkloadAnalytics(staffId, dateRange) 
        : null;
    
    final teachingAnalytics = options.includeTeachingAnalysis 
        ? await getTeachingAnalytics(staffId, 'current')
        : null;
    
    final efficiencyMetrics = options.includeEfficiencyMetrics 
        ? await getEfficiencyMetrics(staffId, dateRange)
        : null;
    
    return StaffPerformanceReport(
      staffId: staffId,
      staffName: staffMember.name,
      department: staffMember.department,
      reportPeriod: dateRange,
      workloadSummary: workloadAnalytics!,
      teachingSummary: teachingAnalytics!,
      efficiencyMetrics: efficiencyMetrics!,
      strengths: ['Excellent time management', 'High student satisfaction'],
      improvementAreas: ['Could improve administrative efficiency'],
      recommendations: ['Consider redistributing administrative tasks'],
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> storeWorkloadData(StaffWorkloadData data) async {
    final key = '${data.staffId}_${data.semester}';
    await _workloadBox.put(key, data);
  }

  @override
  Future<StaffWorkloadData?> getWorkloadData(String staffId, String semester) async {
    final key = '${staffId}_$semester';
    return _workloadBox.get(key);
  }

  @override
  Future<void> updateWorkloadData(String staffId, StaffWorkloadData data) async {
    final key = '${staffId}_${data.semester}';
    await _workloadBox.put(key, data);
  }

  @override
  Future<void> deleteWorkloadData(String staffId, String semester) async {
    final key = '${staffId}_$semester';
    await _workloadBox.delete(key);
  }

  @override
  Future<void> refreshAnalyticsCache() async {
    // In a real implementation, this would clear and rebuild analytics cache
    // For now, just return since we don't have a cache
    return;
  }

  @override
  Future<Map<ActivityType, Duration>> calculateDetailedTimeAllocation(
    String staffId, 
    DateRange dateRange
  ) async {
    final activityDistribution = await calculateActivityDistribution(staffId, dateRange);
    final result = <ActivityType, Duration>{};
    
    for (final entry in activityDistribution.entries) {
      result[entry.key] = Duration(minutes: (entry.value * 60).round());
    }
    
    return result;
  }

  @override
  Future<Map<String, double>> calculateDetailedEfficiencyMetrics(
    String staffId, 
    DateRange dateRange
  ) async {
    final efficiencyMetrics = await getEfficiencyMetrics(staffId, dateRange);
    
    return {
      'processing_time_efficiency': efficiencyMetrics.averageODProcessingTime > 0 
          ? (24.0 / efficiencyMetrics.averageODProcessingTime).clamp(0.0, 10.0)
          : 0.0,
      'approval_rate_score': efficiencyMetrics.odApprovalRate / 10.0,
      'response_time_efficiency': efficiencyMetrics.odResponseTime > 0 
          ? (12.0 / efficiencyMetrics.odResponseTime).clamp(0.0, 10.0)
          : 0.0,
      'satisfaction_score': efficiencyMetrics.studentSatisfactionScore / 10.0,
      'workload_balance': 8.0, // Simplified
      'time_management': 7.5, // Simplified
    };
  }

  // Additional helper methods for the enhanced functionality

  Future<StaffWorkloadData?> _getWorkloadDataForPeriod(
    String staffId, 
    DateRange dateRange
  ) async {
    // For now, get the most recent semester data
    // In a real implementation, this would filter by date range
    final keys = _workloadBox.keys
        .where((key) => key.toString().startsWith(staffId))
        .toList();
    
    if (keys.isEmpty) return null;
    
    // Get the most recent data
    keys.sort();
    return _workloadBox.get(keys.last);
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
      percentileRank: 62.3,
    );
  }

  // Enhanced helper methods for teaching analytics

  /// Get base student count for a grade level (realistic distribution)
  int _getBaseStudentCountForGrade(Grade grade) {
    switch (grade) {
      case Grade.grade1:
      case Grade.grade2:
      case Grade.grade3:
        return 25; // Lower grades typically have smaller classes
      case Grade.grade4:
      case Grade.grade5:
      case Grade.grade6:
        return 30; // Middle grades
      case Grade.grade7:
      case Grade.grade8:
      case Grade.grade9:
        return 35; // Junior high grades
      case Grade.grade10:
      case Grade.grade11:
      case Grade.grade12:
        return 40; // Senior high grades
      case Grade.postGraduate:
        return 20; // Smaller post-graduate classes
    }
  }

  /// Extract section from class name (e.g., "10A" -> "A")
  String _extractSection(String className) {
    final match = RegExp(r'[A-Z]$').firstMatch(className);
    return match?.group(0) ?? 'A';
  }

  /// Determine subject type based on subject code patterns
  SubjectType _determineSubjectType(String subjectCode) {
    final code = subjectCode.toUpperCase();
    
    if (code.contains('LAB') || code.contains('L')) {
      return SubjectType.lab;
    } else if (code.contains('PRAC') || code.contains('P')) {
      return SubjectType.practical;
    } else if (code.contains('PROJ')) {
      return SubjectType.project;
    } else if (code.contains('SEM')) {
      return SubjectType.seminar;
    } else {
      return SubjectType.theory;
    }
  }

  /// Get full subject name from subject code
  String _getSubjectName(String subjectCode) {
    // In a real implementation, this would lookup from a subjects database
    final subjectNames = {
      'MATH101': 'Mathematics I',
      'MATH201': 'Advanced Mathematics',
      'PHYS101': 'Physics I',
      'PHYS201': 'Advanced Physics',
      'CHEM101': 'Chemistry I',
      'CHEM201': 'Organic Chemistry',
      'BIO101': 'Biology I',
      'BIO201': 'Advanced Biology',
      'ENG101': 'English Literature',
      'ENG201': 'Advanced English',
      'HIST101': 'World History',
      'HIST201': 'Modern History',
      'CS101': 'Computer Science I',
      'CS201': 'Data Structures',
      'ART101': 'Fine Arts',
      'PE101': 'Physical Education',
    };
    
    return subjectNames[subjectCode] ?? subjectCode;
  }

  /// Determine class type based on class name patterns
  ClassType _determineClassType(String className) {
    final name = className.toUpperCase();
    
    if (name.contains('HON') || name.contains('ADV')) {
      return ClassType.honors;
    } else if (name.contains('REM') || name.contains('SUP')) {
      return ClassType.remedial;
    } else if (name.contains('SPEC') || name.contains('SP')) {
      return ClassType.special;
    } else if (name.contains('ADV')) {
      return ClassType.advanced;
    } else {
      return ClassType.regular;
    }
  }

  /// Calculate teaching load distribution across subjects
  Map<String, double> calculateSubjectLoadDistribution(
    Map<String, SubjectAllocation> subjectAllocations
  ) {
    final totalPeriods = subjectAllocations.values
        .fold<int>(0, (sum, allocation) => sum + allocation.periodsPerWeek);
    
    if (totalPeriods == 0) return {};
    
    final distribution = <String, double>{};
    for (final entry in subjectAllocations.entries) {
      final percentage = (entry.value.periodsPerWeek / totalPeriods) * 100;
      distribution[entry.key] = percentage;
    }
    
    return distribution;
  }

  /// Calculate grade-wise teaching load distribution
  Map<Grade, double> calculateGradeLoadDistribution(
    Map<String, ClassAllocation> classAllocations
  ) {
    final gradeLoads = <Grade, int>{};
    int totalPeriods = 0;
    
    for (final allocation in classAllocations.values) {
      gradeLoads[allocation.grade] = 
          (gradeLoads[allocation.grade] ?? 0) + allocation.periodsAssigned;
      totalPeriods += allocation.periodsAssigned;
    }
    
    if (totalPeriods == 0) return {};
    
    final distribution = <Grade, double>{};
    for (final entry in gradeLoads.entries) {
      distribution[entry.key] = (entry.value / totalPeriods) * 100;
    }
    
    return distribution;
  }

  /// Calculate class size analytics
  Map<String, dynamic> calculateClassSizeAnalytics(
    Map<String, ClassAllocation> classAllocations
  ) {
    final classSizes = classAllocations.values
        .map((allocation) => allocation.studentCount)
        .toList();
    
    if (classSizes.isEmpty) {
      return {
        'average': 0.0,
        'minimum': 0,
        'maximum': 0,
        'median': 0.0,
        'standardDeviation': 0.0,
        'totalStudents': 0,
      };
    }
    
    classSizes.sort();
    
    final average = classSizes.reduce((a, b) => a + b) / classSizes.length;
    final minimum = classSizes.first;
    final maximum = classSizes.last;
    final median = classSizes.length % 2 == 0
        ? (classSizes[classSizes.length ~/ 2 - 1] + classSizes[classSizes.length ~/ 2]) / 2.0
        : classSizes[classSizes.length ~/ 2].toDouble();
    
    // Calculate standard deviation
    final variance = classSizes
        .map((size) => (size - average) * (size - average))
        .reduce((a, b) => a + b) / classSizes.length;
    final standardDeviation = sqrt(variance);
    
    final totalStudents = classSizes.reduce((a, b) => a + b);
    
    return {
      'average': average,
      'minimum': minimum,
      'maximum': maximum,
      'median': median,
      'standardDeviation': standardDeviation,
      'totalStudents': totalStudents,
    };
  }

  /// Calculate student count tracking metrics
  Map<String, dynamic> calculateStudentCountMetrics(
    Map<String, SubjectAllocation> subjectAllocations,
    Map<String, ClassAllocation> classAllocations
  ) {
    // Subject-wise student counts
    final subjectStudentCounts = <String, double>{};
    for (final entry in subjectAllocations.entries) {
      subjectStudentCounts[entry.key] = entry.value.studentCount;
    }
    
    // Grade-wise student counts
    final gradeStudentCounts = <Grade, int>{};
    for (final allocation in classAllocations.values) {
      gradeStudentCounts[allocation.grade] = 
          (gradeStudentCounts[allocation.grade] ?? 0) + allocation.studentCount;
    }
    
    // Calculate student-to-period ratios
    final subjectStudentPeriodRatios = <String, double>{};
    for (final entry in subjectAllocations.entries) {
      final allocation = entry.value;
      if (allocation.periodsPerWeek > 0) {
        subjectStudentPeriodRatios[entry.key] = 
            allocation.studentCount / allocation.periodsPerWeek;
      }
    }
    
    return {
      'subjectStudentCounts': subjectStudentCounts,
      'gradeStudentCounts': gradeStudentCounts,
      'subjectStudentPeriodRatios': subjectStudentPeriodRatios,
    };
  }
}
