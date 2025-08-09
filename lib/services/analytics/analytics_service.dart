import 'dart:async';
import '../../models/analytics_models.dart';

/// Abstract interface for analytics service
/// Handles data aggregation and analytics computation
abstract class AnalyticsService {
  /// Initialize the analytics service
  Future<void> initialize();
  
  /// Get OD request analytics for a date range
  Future<AnalyticsData> getODRequestAnalytics(DateRange dateRange);
  
  /// Get department-specific analytics
  Future<DepartmentAnalytics> getDepartmentAnalytics(String department);
  
  /// Get student-specific analytics
  Future<StudentAnalytics> getStudentAnalytics(String studentId);
  
  /// Get staff-specific analytics
  Future<StaffAnalytics> getStaffAnalytics(String staffId);
  
  /// Get trend analysis data
  Future<List<TrendData>> getTrendAnalysis(AnalyticsType type);
  
  /// Prepare analytics data for export
  Future<ExportData> prepareAnalyticsForExport(AnalyticsFilter filter);
  
  /// Get chart data for visualization
  Future<List<ChartData>> getChartData(ChartType type, AnalyticsFilter filter);
  
  /// Calculate approval rates
  Future<double> getApprovalRate(AnalyticsFilter filter);
  
  /// Get rejection reasons statistics
  Future<Map<String, int>> getRejectionReasonsStats(AnalyticsFilter filter);
  
  /// Refresh analytics cache
  Future<void> refreshAnalyticsCache();
}