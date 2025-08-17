import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/services/analytics/staff_analytics_service.dart';
import 'package:odtrack_academia/services/analytics/hive_staff_analytics_service.dart';

/// Provider for the staff analytics service
final staffAnalyticsServiceProvider = Provider<StaffAnalyticsService>((ref) {
  return HiveStaffAnalyticsService();
});

/// State class for staff analytics data
class StaffAnalyticsState {
  final WorkloadAnalytics? workloadAnalytics;
  final TeachingAnalytics? teachingAnalytics;
  final TimeAllocationAnalytics? timeAllocationAnalytics;
  final EfficiencyMetrics? efficiencyMetrics;
  final ComparativeAnalytics? comparativeAnalytics;
  final DepartmentBenchmarks? departmentBenchmarks;
  final StaffPerformanceReport? performanceReport;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final String? currentStaffId;
  final DateRange? currentDateRange;

  const StaffAnalyticsState({
    this.workloadAnalytics,
    this.teachingAnalytics,
    this.timeAllocationAnalytics,
    this.efficiencyMetrics,
    this.comparativeAnalytics,
    this.departmentBenchmarks,
    this.performanceReport,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
    this.currentStaffId,
    this.currentDateRange,
  });

  StaffAnalyticsState copyWith({
    WorkloadAnalytics? workloadAnalytics,
    TeachingAnalytics? teachingAnalytics,
    TimeAllocationAnalytics? timeAllocationAnalytics,
    EfficiencyMetrics? efficiencyMetrics,
    ComparativeAnalytics? comparativeAnalytics,
    DepartmentBenchmarks? departmentBenchmarks,
    StaffPerformanceReport? performanceReport,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    String? currentStaffId,
    DateRange? currentDateRange,
  }) {
    return StaffAnalyticsState(
      workloadAnalytics: workloadAnalytics ?? this.workloadAnalytics,
      teachingAnalytics: teachingAnalytics ?? this.teachingAnalytics,
      timeAllocationAnalytics: timeAllocationAnalytics ?? this.timeAllocationAnalytics,
      efficiencyMetrics: efficiencyMetrics ?? this.efficiencyMetrics,
      comparativeAnalytics: comparativeAnalytics ?? this.comparativeAnalytics,
      departmentBenchmarks: departmentBenchmarks ?? this.departmentBenchmarks,
      performanceReport: performanceReport ?? this.performanceReport,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentStaffId: currentStaffId ?? this.currentStaffId,
      currentDateRange: currentDateRange ?? this.currentDateRange,
    );
  }
}

/// Staff analytics provider for managing staff analytics state
class StaffAnalyticsNotifier extends StateNotifier<StaffAnalyticsState> {
  final StaffAnalyticsService _staffAnalyticsService;

  StaffAnalyticsNotifier(this._staffAnalyticsService) : super(const StaffAnalyticsState());

  /// Initialize the staff analytics service
  Future<void> initialize() async {
    try {
      await _staffAnalyticsService.initialize();
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize staff analytics: $e');
    }
  }

  /// Load all analytics data for a staff member
  Future<void> loadStaffAnalytics(String staffId, DateRange dateRange, String semester) async {
    state = state.copyWith(
      isLoading: true, 
      error: null,
      currentStaffId: staffId,
      currentDateRange: dateRange,
    );
    
    try {
      // Load all analytics data in parallel
      final futures = await Future.wait([
        _staffAnalyticsService.getWorkloadAnalytics(staffId, dateRange),
        _staffAnalyticsService.getTeachingAnalytics(staffId, semester),
        _staffAnalyticsService.getTimeAllocationAnalytics(staffId, dateRange),
        _staffAnalyticsService.getEfficiencyMetrics(staffId, dateRange),
      ]);

      state = state.copyWith(
        workloadAnalytics: futures[0] as WorkloadAnalytics,
        teachingAnalytics: futures[1] as TeachingAnalytics,
        timeAllocationAnalytics: futures[2] as TimeAllocationAnalytics,
        efficiencyMetrics: futures[3] as EfficiencyMetrics,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load staff analytics: $e',
      );
    }
  }

  /// Load workload analytics
  Future<void> loadWorkloadAnalytics(String staffId, DateRange dateRange) async {
    try {
      final workloadAnalytics = await _staffAnalyticsService.getWorkloadAnalytics(staffId, dateRange);
      state = state.copyWith(
        workloadAnalytics: workloadAnalytics,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load workload analytics: $e');
    }
  }

  /// Load teaching analytics
  Future<void> loadTeachingAnalytics(String staffId, String semester) async {
    try {
      final teachingAnalytics = await _staffAnalyticsService.getTeachingAnalytics(staffId, semester);
      state = state.copyWith(
        teachingAnalytics: teachingAnalytics,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load teaching analytics: $e');
    }
  }

  /// Load time allocation analytics
  Future<void> loadTimeAllocationAnalytics(String staffId, DateRange dateRange) async {
    try {
      final timeAllocationAnalytics = await _staffAnalyticsService.getTimeAllocationAnalytics(staffId, dateRange);
      state = state.copyWith(
        timeAllocationAnalytics: timeAllocationAnalytics,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load time allocation analytics: $e');
    }
  }

  /// Load efficiency metrics
  Future<void> loadEfficiencyMetrics(String staffId, DateRange dateRange) async {
    try {
      final efficiencyMetrics = await _staffAnalyticsService.getEfficiencyMetrics(staffId, dateRange);
      state = state.copyWith(
        efficiencyMetrics: efficiencyMetrics,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load efficiency metrics: $e');
    }
  }

  /// Load comparative analytics
  Future<void> loadComparativeAnalytics(String staffId, List<String> semesters) async {
    try {
      final comparativeAnalytics = await _staffAnalyticsService.getComparativeAnalytics(staffId, semesters);
      state = state.copyWith(
        comparativeAnalytics: comparativeAnalytics,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load comparative analytics: $e');
    }
  }

  /// Load department benchmarks
  Future<void> loadDepartmentBenchmarks(String department, String semester) async {
    try {
      final departmentBenchmarks = await _staffAnalyticsService.getDepartmentBenchmarks(department, semester);
      state = state.copyWith(
        departmentBenchmarks: departmentBenchmarks,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load department benchmarks: $e');
    }
  }

  /// Generate performance report
  Future<void> generatePerformanceReport(String staffId, ReportOptions options) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final performanceReport = await _staffAnalyticsService.generatePerformanceReport(staffId, options);
      state = state.copyWith(
        performanceReport: performanceReport,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to generate performance report: $e',
      );
    }
  }

  /// Refresh all analytics data
  Future<void> refreshAnalytics() async {
    if (state.currentStaffId != null && state.currentDateRange != null) {
      await _staffAnalyticsService.refreshAnalyticsCache();
      await loadStaffAnalytics(state.currentStaffId!, state.currentDateRange!, 'current');
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
}

/// Provider for the staff analytics notifier
final staffAnalyticsProvider = StateNotifierProvider<StaffAnalyticsNotifier, StaffAnalyticsState>((ref) {
  final staffAnalyticsService = ref.watch(staffAnalyticsServiceProvider);
  return StaffAnalyticsNotifier(staffAnalyticsService);
});

/// Convenience providers for specific analytics data

/// Provider for workload analytics
final workloadAnalyticsProvider = Provider<WorkloadAnalytics?>((ref) {
  return ref.watch(staffAnalyticsProvider).workloadAnalytics;
});

/// Provider for teaching analytics
final teachingAnalyticsProvider = Provider<TeachingAnalytics?>((ref) {
  return ref.watch(staffAnalyticsProvider).teachingAnalytics;
});

/// Provider for time allocation analytics
final timeAllocationAnalyticsProvider = Provider<TimeAllocationAnalytics?>((ref) {
  return ref.watch(staffAnalyticsProvider).timeAllocationAnalytics;
});

/// Provider for efficiency metrics
final efficiencyMetricsProvider = Provider<EfficiencyMetrics?>((ref) {
  return ref.watch(staffAnalyticsProvider).efficiencyMetrics;
});

/// Provider for comparative analytics
final comparativeAnalyticsProvider = Provider<ComparativeAnalytics?>((ref) {
  return ref.watch(staffAnalyticsProvider).comparativeAnalytics;
});

/// Provider for department benchmarks
final departmentBenchmarksProvider = Provider<DepartmentBenchmarks?>((ref) {
  return ref.watch(staffAnalyticsProvider).departmentBenchmarks;
});

/// Provider for performance report
final performanceReportProvider = Provider<StaffPerformanceReport?>((ref) {
  return ref.watch(staffAnalyticsProvider).performanceReport;
});

/// Provider for staff analytics loading state
final staffAnalyticsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(staffAnalyticsProvider).isLoading;
});

/// Provider for staff analytics error state
final staffAnalyticsErrorProvider = Provider<String?>((ref) {
  return ref.watch(staffAnalyticsProvider).error;
});

/// Provider for staff analytics last updated time
final staffAnalyticsLastUpdatedProvider = Provider<DateTime?>((ref) {
  return ref.watch(staffAnalyticsProvider).lastUpdated;
});

/// Provider for checking if staff analytics needs refresh
final staffAnalyticsNeedsRefreshProvider = Provider<bool>((ref) {
  return ref.watch(staffAnalyticsProvider.notifier).needsRefresh;
});