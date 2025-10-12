import 'dart:async';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/analytics_models.dart';

/// Abstract interface for PDF export service
/// Handles PDF generation and document export functionality
abstract class ExportService {
  /// Initialize the export service
  Future<void> initialize();

  /// Export student OD request report
  Future<ExportResult> exportStudentReport(
    String studentId,
    DateRange dateRange,
    ExportOptions options,
  );

  /// Export staff analytics report
  Future<ExportResult> exportStaffReport(
    String staffId,
    DateRange dateRange,
    ExportOptions options,
  );

  /// Export analytics report with charts
  Future<ExportResult> exportAnalyticsReport(
    AnalyticsData data,
    ExportOptions options,
  );

  /// Export bulk OD requests
  Future<ExportResult> exportBulkRequests(
    List<ODRequest> requests,
    ExportOptions options,
  );

  /// Stream of export progress updates
  Stream<ExportProgress> get exportProgressStream;

  /// Cancel ongoing export operation
  Future<void> cancelExport(String exportId);

  /// Get export history
  Future<List<ExportResult>> getExportHistory();

  /// Share exported file
  Future<void> shareExportedFile(String filePath);

  /// Open exported file
  Future<void> openExportedFile(String filePath);

  /// Delete exported file
  Future<void> deleteExportedFile(String filePath);

  /// Get filtered export history
  Future<List<ExportResult>> getFilteredExportHistory(ExportHistoryFilter filter);

  /// Get export statistics
  Future<ExportStatistics> getExportStatistics();

  /// Clear export history
  Future<void> clearExportHistory();

  /// Delete specific export from history
  Future<void> deleteExportFromHistory(String exportId);

  /// Cleanup old export files and history
  Future<void> cleanupOldExports({Duration? olderThan});
}
