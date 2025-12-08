import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/services/analytics/analytics_service.dart';
import 'package:odtrack_academia/services/analytics/hive_analytics_service.dart';
import 'package:odtrack_academia/core/storage/storage_manager.dart';

/// Provider for the enhanced storage manager
final enhancedStorageManagerProvider = Provider<EnhancedStorageManager>((ref) {
  return EnhancedStorageManager();
});

/// Provider for the analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final storageManager = ref.watch(enhancedStorageManagerProvider);
  return HiveAnalyticsService(storageManager);
});

/// State class for analytics data
class AnalyticsState {
  final AnalyticsData? analyticsData;
  final Map<String, DepartmentAnalytics> departmentAnalytics;
  final Map<String, StudentAnalytics> studentAnalytics;
  final Map<String, StaffAnalytics> staffAnalytics;
  final Map<AnalyticsType, List<TrendData>> trendData;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const AnalyticsState({
    this.analyticsData,
    this.departmentAnalytics = const {},
    this.studentAnalytics = const {},
    this.staffAnalytics = const {},
    this.trendData = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  AnalyticsState copyWith({
    AnalyticsData? analyticsData,
    Map<String, DepartmentAnalytics>? departmentAnalytics,
    Map<String, StudentAnalytics>? studentAnalytics,
    Map<String, StaffAnalytics>? staffAnalytics,
    Map<AnalyticsType, List<TrendData>>? trendData,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return AnalyticsState(
      analyticsData: analyticsData ?? this.analyticsData,
      departmentAnalytics: departmentAnalytics ?? this.departmentAnalytics,
      studentAnalytics: studentAnalytics ?? this.studentAnalytics,
      staffAnalytics: staffAnalytics ?? this.staffAnalytics,
      trendData: trendData ?? this.trendData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Analytics provider for managing analytics state
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsService _analyticsService;

  AnalyticsNotifier(this._analyticsService) : super(const AnalyticsState());

  /// Initialize the analytics service
  Future<void> initialize() async {
    try {
      await _analyticsService.initialize();
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize analytics: $e');
    }
  }

  /// Load OD request analytics for a date range
  Future<void> loadODRequestAnalytics(DateRange dateRange) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final analyticsData = await _analyticsService.getODRequestAnalytics(dateRange);
      state = state.copyWith(
        analyticsData: analyticsData,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load analytics: $e',
      );
    }
  }

  /// Load department analytics
  Future<void> loadDepartmentAnalytics(String department) async {
    try {
      final departmentData = await _analyticsService.getDepartmentAnalytics(department);
      final updatedDepartmentAnalytics = Map<String, DepartmentAnalytics>.from(state.departmentAnalytics);
      updatedDepartmentAnalytics[department] = departmentData;
      
      state = state.copyWith(
        departmentAnalytics: updatedDepartmentAnalytics,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load department analytics: $e');
    }
  }

  /// Load student analytics
  Future<void> loadStudentAnalytics(String studentId) async {
    try {
      final studentData = await _analyticsService.getStudentAnalytics(studentId);
      final updatedStudentAnalytics = Map<String, StudentAnalytics>.from(state.studentAnalytics);
      updatedStudentAnalytics[studentId] = studentData;
      
      state = state.copyWith(
        studentAnalytics: updatedStudentAnalytics,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load student analytics: $e');
    }
  }

  /// Load staff analytics
  Future<void> loadStaffAnalytics(String staffId) async {
    try {
      final staffData = await _analyticsService.getStaffAnalytics(staffId);
      final updatedStaffAnalytics = Map<String, StaffAnalytics>.from(state.staffAnalytics);
      updatedStaffAnalytics[staffId] = staffData;
      
      state = state.copyWith(
        staffAnalytics: updatedStaffAnalytics,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load staff analytics: $e');
    }
  }

  /// Load trend analysis data
  Future<void> loadTrendAnalysis(AnalyticsType type) async {
    try {
      final trends = await _analyticsService.getTrendAnalysis(type);
      final updatedTrendData = Map<AnalyticsType, List<TrendData>>.from(state.trendData);
      updatedTrendData[type] = trends;
      
      state = state.copyWith(
        trendData: updatedTrendData,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load trend analysis: $e');
    }
  }

  /// Get chart data for visualization
  Future<List<ChartData>> getChartData(ChartType type, AnalyticsFilter filter) async {
    try {
      return await _analyticsService.getChartData(type, filter);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load chart data: $e');
      return [];
    }
  }

  /// Get approval rate for a filter
  Future<double> getApprovalRate(AnalyticsFilter filter) async {
    try {
      return await _analyticsService.getApprovalRate(filter);
    } catch (e) {
      state = state.copyWith(error: 'Failed to calculate approval rate: $e');
      return 0.0;
    }
  }

  /// Get rejection reasons statistics
  Future<Map<String, int>> getRejectionReasonsStats(AnalyticsFilter filter) async {
    try {
      return await _analyticsService.getRejectionReasonsStats(filter);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load rejection reasons: $e');
      return {};
    }
  }

  /// Prepare analytics data for export
  Future<ExportData?> prepareAnalyticsForExport(AnalyticsFilter filter) async {
    try {
      return await _analyticsService.prepareAnalyticsForExport(filter);
    } catch (e) {
      state = state.copyWith(error: 'Failed to prepare export data: $e');
      return null;
    }
  }

  /// Refresh analytics cache
  Future<void> refreshAnalyticsCache() async {
    try {
      await _analyticsService.refreshAnalyticsCache();
      state = state.copyWith(
        analyticsData: null,
        departmentAnalytics: {},
        studentAnalytics: {},
        staffAnalytics: {},
        trendData: {},
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to refresh cache: $e');
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Check if data needs refresh (older than 1 hour)
  bool get needsRefresh {
    if (state.lastUpdated == null) return true;
    final now = DateTime.now();
    final difference = now.difference(state.lastUpdated!);
    return difference.inHours >= 1;
  }

  /// Get cached department analytics
  DepartmentAnalytics? getDepartmentAnalytics(String department) {
    return state.departmentAnalytics[department];
  }

  /// Get cached student analytics
  StudentAnalytics? getStudentAnalytics(String studentId) {
    return state.studentAnalytics[studentId];
  }

  /// Get cached staff analytics
  StaffAnalytics? getStaffAnalytics(String staffId) {
    return state.staffAnalytics[staffId];
  }

  /// Get cached trend data
  List<TrendData>? getTrendData(AnalyticsType type) {
    return state.trendData[type];
  }
}

/// Provider for the analytics notifier
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return AnalyticsNotifier(analyticsService);
});

/// Convenience providers for specific analytics data

/// Provider for current analytics data
final currentAnalyticsDataProvider = Provider<AnalyticsData?>((ref) {
  return ref.watch(analyticsProvider).analyticsData;
});

/// Provider for analytics loading state
final analyticsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(analyticsProvider).isLoading;
});

/// Provider for analytics error state
final analyticsErrorProvider = Provider<String?>((ref) {
  return ref.watch(analyticsProvider).error;
});

/// Provider for analytics last updated time
final analyticsLastUpdatedProvider = Provider<DateTime?>((ref) {
  return ref.watch(analyticsProvider).lastUpdated;
});

/// Provider for checking if analytics needs refresh
final analyticsNeedsRefreshProvider = Provider<bool>((ref) {
  return ref.watch(analyticsProvider.notifier).needsRefresh;
});

/// Provider for department analytics by department name
final departmentAnalyticsProvider = Provider.family<DepartmentAnalytics?, String>((ref, department) {
  return ref.watch(analyticsProvider.notifier).getDepartmentAnalytics(department);
});

/// Provider for student analytics by student ID
final studentAnalyticsProvider = Provider.family<StudentAnalytics?, String>((ref, studentId) {
  return ref.watch(analyticsProvider.notifier).getStudentAnalytics(studentId);
});

/// Provider for staff analytics by staff ID
final staffAnalyticsProvider = Provider.family<StaffAnalytics?, String>((ref, staffId) {
  return ref.watch(analyticsProvider.notifier).getStaffAnalytics(staffId);
});

/// Provider for trend data by analytics type
final trendDataProvider = Provider.family<List<TrendData>?, AnalyticsType>((ref, type) {
  return ref.watch(analyticsProvider.notifier).getTrendData(type);
});