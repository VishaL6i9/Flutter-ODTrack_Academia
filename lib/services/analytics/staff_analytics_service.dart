import 'dart:async';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/models/analytics_models.dart';

/// Abstract interface for staff analytics service
/// Handles staff workload data aggregation and analytics computation
abstract class StaffAnalyticsService {
  /// Initialize the staff analytics service
  Future<void> initialize();
  
  /// Get workload analytics for a specific staff member
  Future<WorkloadAnalytics> getWorkloadAnalytics(
    String staffId, 
    DateRange dateRange
  );
  
  /// Get teaching analytics for a specific staff member
  Future<TeachingAnalytics> getTeachingAnalytics(
    String staffId, 
    String semester
  );
  
  /// Get time allocation analytics for a specific staff member
  Future<TimeAllocationAnalytics> getTimeAllocationAnalytics(
    String staffId, 
    DateRange dateRange
  );
  
  /// Get efficiency metrics for a specific staff member
  Future<EfficiencyMetrics> getEfficiencyMetrics(
    String staffId, 
    DateRange dateRange
  );
  
  /// Get comparative analytics across multiple semesters
  Future<ComparativeAnalytics> getComparativeAnalytics(
    String staffId, 
    List<String> semesters
  );
  
  /// Get department benchmarks for comparison
  Future<DepartmentBenchmarks> getDepartmentBenchmarks(
    String department, 
    String semester
  );
  
  /// Generate comprehensive performance report
  Future<StaffPerformanceReport> generatePerformanceReport(
    String staffId, 
    ReportOptions options
  );
  
  /// Calculate working hours for a staff member
  Future<double> calculateWorkingHours(
    String staffId, 
    DateRange dateRange
  );
  
  /// Calculate activity distribution for a staff member
  Future<Map<ActivityType, double>> calculateActivityDistribution(
    String staffId, 
    DateRange dateRange
  );
  
  /// Get workload trend analysis
  Future<WorkloadTrend> getWorkloadTrend(
    String staffId, 
    DateRange dateRange
  );
  
  /// Generate workload alerts for a staff member
  Future<List<WorkloadAlert>> generateWorkloadAlerts(
    String staffId, 
    DateRange dateRange
  );
  
  /// Store staff workload data
  Future<void> storeWorkloadData(StaffWorkloadData data);
  
  /// Get stored workload data
  Future<StaffWorkloadData?> getWorkloadData(String staffId, String semester);
  
  /// Update workload data
  Future<void> updateWorkloadData(String staffId, StaffWorkloadData data);
  
  /// Delete workload data
  Future<void> deleteWorkloadData(String staffId, String semester);
  
  /// Refresh analytics cache
  Future<void> refreshAnalyticsCache();
  
  /// Enhanced time allocation tracking with detailed activity monitoring
  Future<Map<ActivityType, Duration>> calculateDetailedTimeAllocation(
    String staffId, 
    DateRange dateRange
  );
  
  /// Enhanced efficiency metrics with detailed performance indicators
  Future<Map<String, double>> calculateDetailedEfficiencyMetrics(
    String staffId, 
    DateRange dateRange
  );
  
  /// Calculate comparative benchmarks with department and institution
  Future<Map<String, ComparisonMetrics>> calculateComparativeBenchmarks(
    String staffId, 
    DateRange dateRange
  );
  
  /// Enhanced time conflict detection
  Future<List<TimeConflict>> detectTimeConflicts(
    String staffId, 
    DateRange dateRange
  );
  
  /// Calculate activity efficiency scores
  Future<Map<ActivityType, double>> calculateActivityEfficiencyScores(
    String staffId, 
    DateRange dateRange
  );
}

/// Teaching analytics model
class TeachingAnalytics {
  final String staffId;
  final String semester;
  final int totalPeriodsAllocated;
  final int totalClassesAssigned;
  final Map<String, SubjectAllocation> subjectAllocations;
  final Map<String, ClassAllocation> classAllocations;
  final Map<Grade, int> gradeDistribution;
  final double averageClassSize;
  final TeachingEfficiency efficiency;

  const TeachingAnalytics({
    required this.staffId,
    required this.semester,
    required this.totalPeriodsAllocated,
    required this.totalClassesAssigned,
    required this.subjectAllocations,
    required this.classAllocations,
    required this.gradeDistribution,
    required this.averageClassSize,
    required this.efficiency,
  });
}

/// Teaching efficiency model
class TeachingEfficiency {
  final double periodsUtilizationRate;
  final double averageStudentsPerPeriod;
  final double subjectDiversityIndex;
  final double gradeLevelSpread;

  const TeachingEfficiency({
    required this.periodsUtilizationRate,
    required this.averageStudentsPerPeriod,
    required this.subjectDiversityIndex,
    required this.gradeLevelSpread,
  });
}

/// Time allocation analytics model
class TimeAllocationAnalytics {
  final Map<ActivityType, Duration> timeByActivity;
  final Map<int, Duration> timeByDay; // DayOfWeek as int
  final Map<TimeSlot, ActivityType> scheduleBreakdown;
  final double teachingPercentage;
  final double administrativePercentage;
  final double odProcessingPercentage;
  final double otherActivitiesPercentage;
  final List<TimeConflict> conflicts;

  const TimeAllocationAnalytics({
    required this.timeByActivity,
    required this.timeByDay,
    required this.scheduleBreakdown,
    required this.teachingPercentage,
    required this.administrativePercentage,
    required this.odProcessingPercentage,
    required this.otherActivitiesPercentage,
    required this.conflicts,
  });
}

/// Time conflict model
class TimeConflict {
  final String id;
  final String description;
  final DateTime conflictTime;
  final List<String> conflictingActivities;
  final String severity;

  const TimeConflict({
    required this.id,
    required this.description,
    required this.conflictTime,
    required this.conflictingActivities,
    required this.severity,
  });
}

/// Efficiency metrics model
class EfficiencyMetrics {
  final double averageODProcessingTime; // in hours
  final double odApprovalRate;
  final double odResponseTime; // average time to respond
  final int totalODsProcessed;
  final Map<String, int> odsByStatus;
  final double studentSatisfactionScore;
  final ComparisonMetrics departmentComparison;
  final ComparisonMetrics institutionComparison;

  const EfficiencyMetrics({
    required this.averageODProcessingTime,
    required this.odApprovalRate,
    required this.odResponseTime,
    required this.totalODsProcessed,
    required this.odsByStatus,
    required this.studentSatisfactionScore,
    required this.departmentComparison,
    required this.institutionComparison,
  });
}

/// Comparison metrics model
class ComparisonMetrics {
  final double averageProcessingTime;
  final double averageApprovalRate;
  final double averageResponseTime;
  final double percentileRank;

  const ComparisonMetrics({
    required this.averageProcessingTime,
    required this.averageApprovalRate,
    required this.averageResponseTime,
    required this.percentileRank,
  });
}

/// Comparative analytics model
class ComparativeAnalytics {
  final String staffId;
  final List<SemesterComparison> semesterComparisons;
  final TrendAnalysis workloadTrend;
  final TrendAnalysis efficiencyTrend;
  final TrendAnalysis studentSatisfactionTrend;
  final List<PerformanceImprovement> improvements;
  final List<PerformanceDecline> declines;

  const ComparativeAnalytics({
    required this.staffId,
    required this.semesterComparisons,
    required this.workloadTrend,
    required this.efficiencyTrend,
    required this.studentSatisfactionTrend,
    required this.improvements,
    required this.declines,
  });
}

/// Semester comparison model
class SemesterComparison {
  final String semester;
  final double workingHours;
  final int periodsAllocated;
  final double efficiencyScore;
  final double satisfactionScore;

  const SemesterComparison({
    required this.semester,
    required this.workingHours,
    required this.periodsAllocated,
    required this.efficiencyScore,
    required this.satisfactionScore,
  });
}

/// Trend analysis model
class TrendAnalysis {
  final String metric;
  final List<TrendPoint> points;
  final double slope;
  final String direction; // 'improving', 'declining', 'stable'
  final double confidence;

  const TrendAnalysis({
    required this.metric,
    required this.points,
    required this.slope,
    required this.direction,
    required this.confidence,
  });
}

/// Trend point model
class TrendPoint {
  final String period;
  final double value;
  final DateTime timestamp;

  const TrendPoint({
    required this.period,
    required this.value,
    required this.timestamp,
  });
}

/// Performance improvement model
class PerformanceImprovement {
  final String area;
  final double improvementPercentage;
  final String description;
  final DateTime detectedAt;

  const PerformanceImprovement({
    required this.area,
    required this.improvementPercentage,
    required this.description,
    required this.detectedAt,
  });
}

/// Performance decline model
class PerformanceDecline {
  final String area;
  final double declinePercentage;
  final String description;
  final DateTime detectedAt;
  final List<String> suggestedActions;

  const PerformanceDecline({
    required this.area,
    required this.declinePercentage,
    required this.description,
    required this.detectedAt,
    required this.suggestedActions,
  });
}

/// Department benchmarks model
class DepartmentBenchmarks {
  final String department;
  final String semester;
  final double averageWorkingHours;
  final double averagePeriodsAllocated;
  final double averageEfficiencyScore;
  final double averageSatisfactionScore;
  final Map<String, double> subjectDistribution;
  final Map<Grade, double> gradeDistribution;

  const DepartmentBenchmarks({
    required this.department,
    required this.semester,
    required this.averageWorkingHours,
    required this.averagePeriodsAllocated,
    required this.averageEfficiencyScore,
    required this.averageSatisfactionScore,
    required this.subjectDistribution,
    required this.gradeDistribution,
  });
}

/// Staff performance report model
class StaffPerformanceReport {
  final String staffId;
  final String staffName;
  final String department;
  final DateRange reportPeriod;
  final WorkloadAnalytics workloadSummary;
  final TeachingAnalytics teachingSummary;
  final EfficiencyMetrics efficiencyMetrics;
  final List<String> strengths;
  final List<String> improvementAreas;
  final List<String> recommendations;
  final DateTime generatedAt;

  const StaffPerformanceReport({
    required this.staffId,
    required this.staffName,
    required this.department,
    required this.reportPeriod,
    required this.workloadSummary,
    required this.teachingSummary,
    required this.efficiencyMetrics,
    required this.strengths,
    required this.improvementAreas,
    required this.recommendations,
    required this.generatedAt,
  });
}

/// Report options model
class ReportOptions {
  final bool includeWorkloadAnalysis;
  final bool includeTeachingAnalysis;
  final bool includeEfficiencyMetrics;
  final bool includeComparativeAnalysis;
  final bool includeBenchmarks;
  final bool includeRecommendations;
  final String format; // 'summary', 'detailed', 'comprehensive'

  const ReportOptions({
    this.includeWorkloadAnalysis = true,
    this.includeTeachingAnalysis = true,
    this.includeEfficiencyMetrics = true,
    this.includeComparativeAnalysis = false,
    this.includeBenchmarks = false,
    this.includeRecommendations = true,
    this.format = 'summary',
  });
}