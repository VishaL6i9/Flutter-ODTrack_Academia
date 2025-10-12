import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/export/export_service.dart';
import 'package:odtrack_academia/services/export/hive_export_service.dart';
import 'package:odtrack_academia/providers/analytics_provider.dart';

/// Provider for the export service
final exportServiceProvider = Provider<ExportService>((ref) {
  final storageManager = ref.watch(enhancedStorageManagerProvider);
  return HiveExportService(storageManager);
});

/// State class for export operations
class ExportState {
  final Map<String, ExportProgress> activeExports;
  final List<ExportResult> exportHistory;
  final List<ExportResult> filteredHistory;
  final ExportHistoryFilter currentFilter;
  final ExportStatistics? statistics;
  final bool isLoading;
  final bool isLoadingHistory;
  final bool isLoadingStatistics;
  final String? error;

  const ExportState({
    this.activeExports = const {},
    this.exportHistory = const [],
    this.filteredHistory = const [],
    this.currentFilter = const ExportHistoryFilter(),
    this.statistics,
    this.isLoading = false,
    this.isLoadingHistory = false,
    this.isLoadingStatistics = false,
    this.error,
  });

  ExportState copyWith({
    Map<String, ExportProgress>? activeExports,
    List<ExportResult>? exportHistory,
    List<ExportResult>? filteredHistory,
    ExportHistoryFilter? currentFilter,
    ExportStatistics? statistics,
    bool? isLoading,
    bool? isLoadingHistory,
    bool? isLoadingStatistics,
    String? error,
  }) {
    return ExportState(
      activeExports: activeExports ?? this.activeExports,
      exportHistory: exportHistory ?? this.exportHistory,
      filteredHistory: filteredHistory ?? this.filteredHistory,
      currentFilter: currentFilter ?? this.currentFilter,
      statistics: statistics ?? this.statistics,
      isLoading: isLoading ?? this.isLoading,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isLoadingStatistics: isLoadingStatistics ?? this.isLoadingStatistics,
      error: error,
    );
  }
}

/// Export provider for managing export operations
class ExportNotifier extends StateNotifier<ExportState> {
  final ExportService _exportService;

  ExportNotifier(this._exportService) : super(const ExportState()) {
    _initializeExportService();
  }

  /// Initialize the export service and listen to progress updates
  Future<void> _initializeExportService() async {
    try {
      await _exportService.initialize();
      
      // Listen to export progress updates
      _exportService.exportProgressStream.listen(
        (progress) {
          final updatedExports = Map<String, ExportProgress>.from(state.activeExports);
          updatedExports[progress.exportId] = progress;
          
          // Remove completed exports from active list
          if (progress.progress >= 1.0) {
            updatedExports.remove(progress.exportId);
          }
          
          state = state.copyWith(activeExports: updatedExports);
        },
        onError: (Object error) {
          state = state.copyWith(error: 'Export progress error: $error');
        },
      );
      
      // Load export history
      await _loadExportHistory();
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize export service: $e');
    }
  }

  /// Load export history
  Future<void> _loadExportHistory() async {
    try {
      final history = await _exportService.getExportHistory();
      state = state.copyWith(exportHistory: history);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load export history: $e');
    }
  }

  /// Export student OD request report
  Future<ExportResult> exportStudentReport(
    String studentId,
    DateRange dateRange,
    ExportOptions options,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _exportService.exportStudentReport(
        studentId,
        dateRange,
        options,
      );
      
      // Update export history
      final updatedHistory = List<ExportResult>.from(state.exportHistory);
      updatedHistory.insert(0, result);
      
      state = state.copyWith(
        exportHistory: updatedHistory,
        isLoading: false,
      );
      
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to export student report: $e',
      );
      rethrow;
    }
  }

  /// Export staff analytics report
  Future<ExportResult> exportStaffReport(
    String staffId,
    DateRange dateRange,
    ExportOptions options,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _exportService.exportStaffReport(
        staffId,
        dateRange,
        options,
      );
      
      // Update export history
      final updatedHistory = List<ExportResult>.from(state.exportHistory);
      updatedHistory.insert(0, result);
      
      state = state.copyWith(
        exportHistory: updatedHistory,
        isLoading: false,
      );
      
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to export staff report: $e',
      );
      rethrow;
    }
  }

  /// Export analytics report with charts
  Future<ExportResult> exportAnalyticsReport(
    AnalyticsData data,
    ExportOptions options,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _exportService.exportAnalyticsReport(data, options);
      
      // Update export history
      final updatedHistory = List<ExportResult>.from(state.exportHistory);
      updatedHistory.insert(0, result);
      
      state = state.copyWith(
        exportHistory: updatedHistory,
        isLoading: false,
      );
      
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to export analytics report: $e',
      );
      rethrow;
    }
  }

  /// Export bulk OD requests
  Future<ExportResult> exportBulkRequests(
    List<ODRequest> requests,
    ExportOptions options,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _exportService.exportBulkRequests(requests, options);
      
      // Update export history
      final updatedHistory = List<ExportResult>.from(state.exportHistory);
      updatedHistory.insert(0, result);
      
      state = state.copyWith(
        exportHistory: updatedHistory,
        isLoading: false,
      );
      
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to export bulk requests: $e',
      );
      rethrow;
    }
  }

  /// Cancel ongoing export operation
  Future<void> cancelExport(String exportId) async {
    try {
      await _exportService.cancelExport(exportId);
      
      // Remove from active exports
      final updatedExports = Map<String, ExportProgress>.from(state.activeExports);
      updatedExports.remove(exportId);
      
      state = state.copyWith(activeExports: updatedExports);
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel export: $e');
    }
  }

  /// Share exported file
  Future<void> shareExportedFile(String filePath) async {
    try {
      await _exportService.shareExportedFile(filePath);
    } catch (e) {
      state = state.copyWith(error: 'Failed to share file: $e');
    }
  }

  /// Open exported file
  Future<void> openExportedFile(String filePath) async {
    try {
      await _exportService.openExportedFile(filePath);
    } catch (e) {
      state = state.copyWith(error: 'Failed to open file: $e');
    }
  }

  /// Delete exported file
  Future<void> deleteExportedFile(String filePath) async {
    try {
      await _exportService.deleteExportedFile(filePath);
      
      // Remove from export history
      final updatedHistory = state.exportHistory
          .where((result) => result.filePath != filePath)
          .toList();
      
      state = state.copyWith(exportHistory: updatedHistory);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete file: $e');
    }
  }

  /// Refresh export history
  Future<void> refreshExportHistory() async {
    await _loadExportHistory();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get active export progress
  ExportProgress? getExportProgress(String exportId) {
    return state.activeExports[exportId];
  }

  /// Check if any exports are currently active
  bool get hasActiveExports => state.activeExports.isNotEmpty;

  /// Get the number of active exports
  int get activeExportCount => state.activeExports.length;

  /// Apply filter to export history
  Future<void> applyHistoryFilter(ExportHistoryFilter filter) async {
    state = state.copyWith(isLoadingHistory: true, error: null);
    
    try {
      final filteredHistory = await _exportService.getFilteredExportHistory(filter);
      
      state = state.copyWith(
        filteredHistory: filteredHistory,
        currentFilter: filter,
        isLoadingHistory: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        error: 'Failed to filter export history: $e',
      );
    }
  }

  /// Load export statistics
  Future<void> loadExportStatistics() async {
    state = state.copyWith(isLoadingStatistics: true, error: null);
    
    try {
      final statistics = await _exportService.getExportStatistics();
      
      state = state.copyWith(
        statistics: statistics,
        isLoadingStatistics: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingStatistics: false,
        error: 'Failed to load export statistics: $e',
      );
    }
  }

  /// Clear export history
  Future<void> clearExportHistory() async {
    try {
      await _exportService.clearExportHistory();
      
      state = state.copyWith(
        exportHistory: [],
        filteredHistory: [],
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear export history: $e');
    }
  }

  /// Delete specific export from history
  Future<void> deleteExportFromHistory(String exportId) async {
    try {
      await _exportService.deleteExportFromHistory(exportId);
      
      // Update local state
      final updatedHistory = state.exportHistory
          .where((result) => result.id != exportId)
          .toList();
      
      final updatedFilteredHistory = state.filteredHistory
          .where((result) => result.id != exportId)
          .toList();
      
      state = state.copyWith(
        exportHistory: updatedHistory,
        filteredHistory: updatedFilteredHistory,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete export: $e');
    }
  }

  /// Cleanup old exports
  Future<void> cleanupOldExports({Duration? olderThan}) async {
    try {
      await _exportService.cleanupOldExports(olderThan: olderThan);
      
      // Refresh history and statistics
      await _loadExportHistory();
      await loadExportStatistics();
    } catch (e) {
      state = state.copyWith(error: 'Failed to cleanup old exports: $e');
    }
  }

  /// Get export progress with enhanced details
  ExportProgress? getEnhancedExportProgress(String exportId) {
    return state.activeExports[exportId];
  }

  /// Check if export can be cancelled
  bool canCancelExport(String exportId) {
    final progress = state.activeExports[exportId];
    return progress?.isCancellable ?? false;
  }

  /// Get estimated completion time for export
  DateTime? getEstimatedCompletionTime(String exportId) {
    final progress = state.activeExports[exportId];
    if (progress?.estimatedTimeRemaining != null) {
      return DateTime.now().add(progress!.estimatedTimeRemaining!);
    }
    return null;
  }
}

/// Provider for the export notifier
final exportProvider = StateNotifierProvider<ExportNotifier, ExportState>((ref) {
  final exportService = ref.watch(exportServiceProvider);
  return ExportNotifier(exportService);
});

/// Convenience providers for specific export data

/// Provider for export loading state
final exportLoadingProvider = Provider<bool>((ref) {
  return ref.watch(exportProvider).isLoading;
});

/// Provider for export error state
final exportErrorProvider = Provider<String?>((ref) {
  return ref.watch(exportProvider).error;
});

/// Provider for export history
final exportHistoryProvider = Provider<List<ExportResult>>((ref) {
  return ref.watch(exportProvider).exportHistory;
});

/// Provider for active exports
final activeExportsProvider = Provider<Map<String, ExportProgress>>((ref) {
  return ref.watch(exportProvider).activeExports;
});

/// Provider for checking if exports are active
final hasActiveExportsProvider = Provider<bool>((ref) {
  return ref.watch(exportProvider.notifier).hasActiveExports;
});

/// Provider for active export count
final activeExportCountProvider = Provider<int>((ref) {
  return ref.watch(exportProvider.notifier).activeExportCount;
});

/// Provider for specific export progress
final exportProgressProvider = Provider.family<ExportProgress?, String>((ref, exportId) {
  return ref.watch(exportProvider.notifier).getExportProgress(exportId);
});

/// Provider for filtered export history
final filteredExportHistoryProvider = Provider<List<ExportResult>>((ref) {
  return ref.watch(exportProvider).filteredHistory;
});

/// Provider for current export filter
final currentExportFilterProvider = Provider<ExportHistoryFilter>((ref) {
  return ref.watch(exportProvider).currentFilter;
});

/// Provider for export statistics
final exportStatisticsProvider = Provider<ExportStatistics?>((ref) {
  return ref.watch(exportProvider).statistics;
});

/// Provider for export history loading state
final exportHistoryLoadingProvider = Provider<bool>((ref) {
  return ref.watch(exportProvider).isLoadingHistory;
});

/// Provider for export statistics loading state
final exportStatisticsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(exportProvider).isLoadingStatistics;
});

/// Provider for enhanced export progress
final enhancedExportProgressProvider = Provider.family<ExportProgress?, String>((ref, exportId) {
  return ref.watch(exportProvider.notifier).getEnhancedExportProgress(exportId);
});

/// Provider for checking if export can be cancelled
final canCancelExportProvider = Provider.family<bool, String>((ref, exportId) {
  return ref.watch(exportProvider.notifier).canCancelExport(exportId);
});

/// Provider for estimated completion time
final estimatedCompletionTimeProvider = Provider.family<DateTime?, String>((ref, exportId) {
  return ref.watch(exportProvider.notifier).getEstimatedCompletionTime(exportId);
});