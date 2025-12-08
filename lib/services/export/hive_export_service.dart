import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/export_filters.dart';

import 'package:odtrack_academia/services/export/export_service.dart';
import 'package:odtrack_academia/services/export/pdf_generator.dart';
import 'package:odtrack_academia/core/storage/storage_manager.dart';

/// Hive-based implementation of ExportService
class HiveExportService implements ExportService {
  final EnhancedStorageManager _storageManager;
  final PDFGenerator _pdfGenerator;
  final StreamController<ExportProgress> _progressController =
      StreamController<ExportProgress>.broadcast();
  final List<ExportResult> _exportHistory = [];

  HiveExportService(this._storageManager) : _pdfGenerator = PDFGenerator();

  @override
  Future<void> initialize() async {
    // Initialize storage if needed
    await _storageManager.initialize();

    // Load export history from storage
    await _loadExportHistory();
  }

  @override
  Stream<ExportProgress> get exportProgressStream => _progressController.stream;

  @override
  Future<ExportResult> exportStudentReport(
    String studentId,
    DateRange dateRange,
    ExportOptions options,
  ) async {
    final exportId = _generateExportId();

    try {
      _updateProgress(exportId, 0.1, 'Preparing student data...');

      // Get student data from storage with enhanced filtering
      final studentData = await _getEnhancedStudentData(
        studentId,
        dateRange,
        options,
      );

      _updateProgress(exportId, 0.4, 'Generating enhanced report...');

      // Generate the report with filtering and chart options
      final result = await _generateEnhancedReport(
        exportId,
        'Student Report - $studentId',
        studentData,
        options,
        ReportType.student,
      );

      _updateProgress(exportId, 1.0, 'Export completed');

      // Add to history
      _exportHistory.insert(0, result);
      await _saveExportHistory();

      return result;
    } catch (e) {
      final errorResult = ExportResult(
        id: exportId,
        fileName: 'student_report_error.txt',
        filePath: '',
        format: options.format,
        fileSize: 0,
        createdAt: DateTime.now(),
        success: false,
        errorMessage: e.toString(),
      );

      _exportHistory.insert(0, errorResult);
      await _saveExportHistory();

      rethrow;
    }
  }

  @override
  Future<ExportResult> exportStaffReport(
    String staffId,
    DateRange dateRange,
    ExportOptions options,
  ) async {
    final exportId = _generateExportId();

    try {
      _updateProgress(exportId, 0.1, 'Preparing staff analytics data...');

      // Get enhanced staff data with analytics
      final staffData = await _getEnhancedStaffData(
        staffId,
        dateRange,
        options,
      );

      _updateProgress(
        exportId,
        0.4,
        'Generating analytics report with charts...',
      );

      // Generate the enhanced report with charts and summaries
      final result = await _generateEnhancedReport(
        exportId,
        'Staff Analytics Report - $staffId',
        staffData,
        options,
        ReportType.staff,
      );

      _updateProgress(exportId, 1.0, 'Export completed');

      // Add to history
      _exportHistory.insert(0, result);
      await _saveExportHistory();

      return result;
    } catch (e) {
      final errorResult = ExportResult(
        id: exportId,
        fileName: 'staff_report_error.txt',
        filePath: '',
        format: options.format,
        fileSize: 0,
        createdAt: DateTime.now(),
        success: false,
        errorMessage: e.toString(),
      );

      _exportHistory.insert(0, errorResult);
      await _saveExportHistory();

      rethrow;
    }
  }

  @override
  Future<ExportResult> exportAnalyticsReport(
    AnalyticsData data,
    ExportOptions options,
  ) async {
    final exportId = _generateExportId();

    try {
      _updateProgress(exportId, 0.1, 'Preparing analytics data...');

      final reportData = {
        'title': options.customTitle ?? 'Analytics Report',
        'generatedAt': DateTime.now().toIso8601String(),
        'totalRequests': data.totalRequests,
        'approvedRequests': data.approvedRequests,
        'rejectedRequests': data.rejectedRequests,
        'pendingRequests': data.pendingRequests,
        'approvalRate': data.approvalRate,
        'requestsByMonth': data.requestsByMonth,
        'requestsByDepartment': data.requestsByDepartment,
        'topRejectionReasons': data.topRejectionReasons
            .map(
              (r) => {
                'reason': r.reason,
                'count': r.count,
                'percentage': r.percentage,
              },
            )
            .toList(),
        'patterns': data.patterns
            .map(
              (p) => {
                'pattern': p.pattern,
                'description': p.description,
                'confidence': p.confidence,
              },
            )
            .toList(),
      };

      _updateProgress(exportId, 0.4, 'Generating report...');

      // Generate the report based on format
      final result = await _generateReport(
        exportId,
        options.customTitle ?? 'Analytics Report',
        reportData,
        options,
      );

      _updateProgress(exportId, 1.0, 'Export completed');

      // Add to history
      _exportHistory.insert(0, result);
      await _saveExportHistory();

      return result;
    } catch (e) {
      final errorResult = ExportResult(
        id: exportId,
        fileName: 'analytics_report_error.txt',
        filePath: '',
        format: options.format,
        fileSize: 0,
        createdAt: DateTime.now(),
        success: false,
        errorMessage: e.toString(),
      );

      _exportHistory.insert(0, errorResult);
      await _saveExportHistory();

      rethrow;
    }
  }

  @override
  Future<ExportResult> exportBulkRequests(
    List<ODRequest> requests,
    ExportOptions options,
  ) async {
    final exportId = _generateExportId();

    try {
      _updateProgress(
        exportId,
        0.1,
        'Preparing bulk request data with custom formatting...',
      );

      // Apply custom filtering if specified in options
      final filteredRequests = _applyBulkFiltering(requests, options);

      final reportData = {
        'title': options.customTitle ?? 'Bulk OD Requests Export',
        'generatedAt': DateTime.now().toIso8601String(),
        'totalRequests': filteredRequests.length,
        'originalCount': requests.length,
        'filterApplied': filteredRequests.length != requests.length,
        'requests': filteredRequests
            .map(
              (request) => {
                'id': request.id,
                'studentId': request.studentId,
                'studentName': request.studentName,
                'registerNumber': request.registerNumber,
                'reason': request.reason,
                'date': request.date.toIso8601String(),
                'periods': request.periods,
                'status': request.status,
                'createdAt': request.createdAt.toIso8601String(),
                'approvedBy': request.approvedBy,
                'approvedAt': request.approvedAt?.toIso8601String(),
                'rejectionReason': request.rejectionReason,
                'attachmentUrl': request.attachmentUrl,
              },
            )
            .toList(),
        'summary': _generateBulkSummary(filteredRequests),
      };

      _updateProgress(exportId, 0.4, 'Generating custom formatted report...');

      // Generate the enhanced report with custom formatting
      final result = await _generateEnhancedReport(
        exportId,
        options.customTitle ?? 'Bulk OD Requests Export',
        reportData,
        options,
        ReportType.bulk,
      );

      _updateProgress(exportId, 1.0, 'Export completed');

      // Add to history
      _exportHistory.insert(0, result);
      await _saveExportHistory();

      return result;
    } catch (e) {
      final errorResult = ExportResult(
        id: exportId,
        fileName: 'bulk_requests_error.txt',
        filePath: '',
        format: options.format,
        fileSize: 0,
        createdAt: DateTime.now(),
        success: false,
        errorMessage: e.toString(),
      );

      _exportHistory.insert(0, errorResult);
      await _saveExportHistory();

      rethrow;
    }
  }

  @override
  Future<void> cancelExport(String exportId) async {
    // In a real implementation, this would cancel ongoing operations
    // For now, we'll just remove it from progress tracking
    _updateProgress(exportId, 1.0, 'Cancelled', isCancellable: false);
    
    // Add cancelled export to history
    final cancelledResult = ExportResult(
      id: exportId,
      fileName: 'cancelled_export.txt',
      filePath: '',
      format: ExportFormat.pdf,
      fileSize: 0,
      createdAt: DateTime.now(),
      success: false,
      errorMessage: 'Export cancelled by user',
    );
    
    _exportHistory.insert(0, cancelledResult);
    await _saveExportHistory();
  }

  @override
  Future<List<ExportResult>> getExportHistory() async {
    return List.from(_exportHistory);
  }

  @override
  Future<void> shareExportedFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(filePath)]);
    } else {
      throw Exception('File not found: $filePath');
    }
  }

  @override
  Future<void> openExportedFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await OpenFile.open(filePath);
    } else {
      throw Exception('File not found: $filePath');
    }
  }

  @override
  Future<void> deleteExportedFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();

      // Remove from history
      _exportHistory.removeWhere((result) => result.filePath == filePath);
      await _saveExportHistory();
    }
  }

  // Private helper methods

  String _generateExportId() {
    return 'export_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _updateProgress(
    String exportId, 
    double progress, 
    String message, {
    int? totalItems,
    int? processedItems,
    Duration? estimatedTimeRemaining,
    bool isCancellable = true,
  }) {
    _progressController.add(
      ExportProgress(
        exportId: exportId,
        progress: progress,
        currentStep: message,
        message: message,
        timestamp: DateTime.now(),
        totalItems: totalItems,
        processedItems: processedItems,
        estimatedTimeRemaining: estimatedTimeRemaining,
        isCancellable: isCancellable,
      ),
    );
  }

  // Enhanced data retrieval methods

  Future<Map<String, dynamic>> _getEnhancedStudentData(
    String studentId,
    DateRange dateRange,
    ExportOptions options,
  ) async {
    final baseData = await _getStudentData(studentId, dateRange);

    // Add enhanced analytics
    final requests =
        (baseData['requests'] as List<dynamic>?)
            ?.map((r) => ODRequest.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    // Calculate additional metrics
    final analytics = _calculateStudentAnalytics(requests);

    return {
      ...baseData,
      'analytics': analytics,
      'exportOptions': options.toJson(),
    };
  }

  Future<Map<String, dynamic>> _getEnhancedStaffData(
    String staffId,
    DateRange dateRange,
    ExportOptions options,
  ) async {
    final baseData = await _getStaffData(staffId, dateRange);

    // Add enhanced analytics and performance metrics
    final analytics = _calculateStaffAnalytics(baseData);

    return {
      ...baseData,
      'analytics': analytics,
      'performanceMetrics': _calculatePerformanceMetrics(baseData),
      'exportOptions': options.toJson(),
    };
  }

  Future<Map<String, dynamic>> _getStudentData(
    String studentId,
    DateRange dateRange,
  ) async {
    // Mock implementation - in real app, this would fetch from Hive storage
    final mockRequests = [
      {
        'id': 'req_1',
        'studentId': studentId,
        'studentName': 'John Doe',
        'registerNumber': 'REG001',
        'date': '2024-01-15T00:00:00.000Z',
        'periods': [1, 2],
        'reason': 'Medical appointment',
        'status': 'approved',
        'attachmentUrl': null,
        'createdAt': '2024-01-15T08:00:00.000Z',
        'approvedAt': '2024-01-15T10:00:00.000Z',
        'approvedBy': 'Dr. Smith',
        'rejectionReason': null,
        'staffId': 'staff_001',
      },
      {
        'id': 'req_2',
        'studentId': studentId,
        'studentName': 'John Doe',
        'registerNumber': 'REG001',
        'date': '2024-01-20T00:00:00.000Z',
        'periods': [3, 4, 5],
        'reason': 'Family function',
        'status': 'rejected',
        'attachmentUrl': null,
        'createdAt': '2024-01-20T08:00:00.000Z',
        'approvedAt': null,
        'approvedBy': null,
        'rejectionReason': 'Insufficient notice period',
        'staffId': 'staff_001',
      },
    ];

    return {
      'studentId': studentId,
      'studentName': 'John Doe',
      'registerNumber': 'REG001',
      'department': 'Computer Science',
      'yearSemester': '3rd Year, 5th Semester',
      'dateRange': {
        'startDate': dateRange.startDate.toIso8601String(),
        'endDate': dateRange.endDate.toIso8601String(),
      },
      'totalRequests': 5,
      'approvedRequests': 3,
      'rejectedRequests': 1,
      'pendingRequests': 1,
      'requests': mockRequests,
      'frequentReasons': [
        'Medical appointment',
        'Family function',
        'Personal work',
      ],
    };
  }

  Future<Map<String, dynamic>> _getStaffData(
    String staffId,
    DateRange dateRange,
  ) async {
    // Mock implementation - in real app, this would fetch from Hive storage
    return {
      'staffId': staffId,
      'staffName': 'Dr. Jane Smith',
      'department': 'Computer Science',
      'designation': 'Associate Professor',
      'dateRange': {
        'startDate': dateRange.startDate.toIso8601String(),
        'endDate': dateRange.endDate.toIso8601String(),
      },
      'requestsProcessed': 25,
      'requestsApproved': 20,
      'requestsRejected': 3,
      'requestsPending': 2,
      'averageProcessingTime': 2.5,
      'commonRejectionReasons': [
        'Insufficient notice period',
        'Missing documentation',
        'Exceeds monthly limit',
      ],
    };
  }

  // Enhanced report generation methods

  Future<ExportResult> _generateEnhancedReport(
    String exportId,
    String title,
    Map<String, dynamic> data,
    ExportOptions options,
    ReportType reportType,
  ) async {
    switch (options.format) {
      case ExportFormat.pdf:
        return await _generateEnhancedPdfReport(
          exportId,
          title,
          data,
          options,
          reportType,
        );
      case ExportFormat.csv:
        return await _generateEnhancedCsvReport(
          exportId,
          title,
          data,
          options,
          reportType,
        );
      case ExportFormat.excel:
        throw UnimplementedError('Excel export not yet implemented');
    }
  }

  Future<ExportResult> _generateReport(
    String exportId,
    String title,
    Map<String, dynamic> data,
    ExportOptions options,
  ) async {
    switch (options.format) {
      case ExportFormat.pdf:
        return await _generatePdfReport(exportId, title, data, options);
      case ExportFormat.csv:
        return await _generateCsvReport(exportId, title, data, options);
      case ExportFormat.excel:
        throw UnimplementedError('Excel export not yet implemented');
    }
  }

  Future<ExportResult> _generateEnhancedPdfReport(
    String exportId,
    String title,
    Map<String, dynamic> data,
    ExportOptions options,
    ReportType reportType,
  ) async {
    _updateProgress(
      exportId,
      0.5,
      'Creating enhanced PDF document with charts...',
    );

    late Uint8List pdfBytes;

    // Generate appropriate PDF with enhanced features
    switch (reportType) {
      case ReportType.student:
        final studentData = _mapToStudentReportData(data);
        final filter = _extractStudentFilter(options);
        pdfBytes = await _pdfGenerator.generateStudentReport(
          studentData,
          filter: filter,
          options: options,
        );
        break;
      case ReportType.staff:
        final staffData = _mapToStaffReportData(data);
        final filter = _extractStaffFilter(options);
        pdfBytes = await _pdfGenerator.generateStaffReport(
          staffData,
          filter: filter,
          options: options,
        );
        break;
      case ReportType.analytics:
        final analyticsData = _mapToAnalyticsReportData(data);
        pdfBytes = await _pdfGenerator.generateAnalyticsReport(analyticsData);
        break;
      case ReportType.bulk:
        final bulkData = _mapToBulkRequestsReportData(data);
        final filter = _extractBulkFilter(options);
        pdfBytes = await _pdfGenerator.generateBulkRequestsReport(
          bulkData,
          filter: filter,
          options: options,
        );
        break;
    }

    _updateProgress(exportId, 0.8, 'Saving enhanced PDF file...');

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${title.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsBytes(pdfBytes);

    return ExportResult(
      id: exportId,
      fileName: fileName,
      filePath: filePath,
      format: ExportFormat.pdf,
      fileSize: pdfBytes.length,
      createdAt: DateTime.now(),
      success: true,
    );
  }

  Future<ExportResult> _generateEnhancedCsvReport(
    String exportId,
    String title,
    Map<String, dynamic> data,
    ExportOptions options,
    ReportType reportType,
  ) async {
    _updateProgress(exportId, 0.5, 'Creating enhanced CSV file...');

    final csvContent = StringBuffer();

    // Add metadata if requested
    if (options.includeMetadata) {
      csvContent.writeln('# $title');
      csvContent.writeln('# Generated on: ${DateTime.now()}');
      csvContent.writeln(
        '# Export Options: Charts=${options.includeCharts}, Metadata=${options.includeMetadata}',
      );
      csvContent.writeln('');
    }

    // Generate CSV content based on report type
    switch (reportType) {
      case ReportType.student:
        _generateStudentCsvContent(csvContent, data, options);
        break;
      case ReportType.staff:
        _generateStaffCsvContent(csvContent, data, options);
        break;
      case ReportType.analytics:
        _generateAnalyticsCsvContent(csvContent, data, options);
        break;
      case ReportType.bulk:
        _generateBulkCsvContent(csvContent, data, options);
        break;
    }

    _updateProgress(exportId, 0.8, 'Saving enhanced CSV file...');

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${title.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsString(csvContent.toString());

    final fileSize = await file.length();

    return ExportResult(
      id: exportId,
      fileName: fileName,
      filePath: filePath,
      format: ExportFormat.csv,
      fileSize: fileSize,
      createdAt: DateTime.now(),
      success: true,
    );
  }

  Future<ExportResult> _generatePdfReport(
    String exportId,
    String title,
    Map<String, dynamic> data,
    ExportOptions options,
  ) async {
    _updateProgress(exportId, 0.5, 'Creating PDF document...');

    late Uint8List pdfBytes;

    // Determine report type and generate appropriate PDF
    if (title.contains('Student Report')) {
      final studentData = _mapToStudentReportData(data);
      pdfBytes = await _pdfGenerator.generateStudentReport(studentData);
    } else if (title.contains('Staff Report')) {
      final staffData = _mapToStaffReportData(data);
      pdfBytes = await _pdfGenerator.generateStaffReport(staffData);
    } else if (title.contains('Analytics Report')) {
      final analyticsData = _mapToAnalyticsReportData(data);
      pdfBytes = await _pdfGenerator.generateAnalyticsReport(analyticsData);
    } else if (title.contains('Bulk')) {
      final bulkData = _mapToBulkRequestsReportData(data);
      pdfBytes = await _pdfGenerator.generateBulkRequestsReport(bulkData);
    } else {
      // Fallback to generic PDF generation
      pdfBytes = await _generateGenericPdf(title, data, options);
    }

    _updateProgress(exportId, 0.8, 'Saving PDF file...');

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${title.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsBytes(pdfBytes);

    return ExportResult(
      id: exportId,
      fileName: fileName,
      filePath: filePath,
      format: ExportFormat.pdf,
      fileSize: pdfBytes.length,
      createdAt: DateTime.now(),
      success: true,
    );
  }

  Future<ExportResult> _generateCsvReport(
    String exportId,
    String title,
    Map<String, dynamic> data,
    ExportOptions options,
  ) async {
    _updateProgress(exportId, 0.5, 'Creating CSV file...');

    final csvContent = StringBuffer();

    // Add metadata if requested
    if (options.includeMetadata) {
      csvContent.writeln('# $title');
      csvContent.writeln('# Generated on: ${DateTime.now()}');
      csvContent.writeln('');
    }

    // Add headers
    csvContent.writeln('Field,Value');

    // Add data
    for (final entry in data.entries) {
      final value = entry.value.toString().replaceAll(',', ';');
      csvContent.writeln('${entry.key},$value');
    }

    _updateProgress(exportId, 0.8, 'Saving CSV file...');

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${title.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsString(csvContent.toString());

    final fileSize = await file.length();

    return ExportResult(
      id: exportId,
      fileName: fileName,
      filePath: filePath,
      format: ExportFormat.csv,
      fileSize: fileSize,
      createdAt: DateTime.now(),
      success: true,
    );
  }

  Future<void> _loadExportHistory() async {
    // In a real implementation, this would load from Hive storage
    // For now, we'll keep it in memory
  }

  Future<void> _saveExportHistory() async {
    // In a real implementation, this would save to Hive storage
    // For now, we'll keep it in memory
  }

  /// Get filtered export history
  @override
  Future<List<ExportResult>> getFilteredExportHistory(ExportHistoryFilter filter) async {
    var filteredHistory = List<ExportResult>.from(_exportHistory);

    // Apply format filter
    if (filter.format != null) {
      filteredHistory = filteredHistory
          .where((result) => result.format == filter.format)
          .toList();
    }

    // Apply date range filter
    if (filter.startDate != null) {
      filteredHistory = filteredHistory
          .where((result) => result.createdAt.isAfter(filter.startDate!))
          .toList();
    }

    if (filter.endDate != null) {
      filteredHistory = filteredHistory
          .where((result) => result.createdAt.isBefore(filter.endDate!))
          .toList();
    }

    // Apply success filter
    if (filter.successOnly != null) {
      filteredHistory = filteredHistory
          .where((result) => result.success == filter.successOnly)
          .toList();
    }

    // Apply search query filter
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      filteredHistory = filteredHistory
          .where((result) =>
              result.fileName.toLowerCase().contains(query) ||
              (result.errorMessage?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return filteredHistory;
  }

  /// Get export statistics
  @override
  Future<ExportStatistics> getExportStatistics() async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final thisWeek = now.subtract(Duration(days: now.weekday - 1));

    final successfulExports = _exportHistory.where((e) => e.success).length;
    final failedExports = _exportHistory.where((e) => !e.success).length;

    final exportsByFormat = <ExportFormat, int>{};
    for (final format in ExportFormat.values) {
      exportsByFormat[format] = _exportHistory
          .where((e) => e.format == format && e.success)
          .length;
    }

    final totalFileSize = _exportHistory
        .where((e) => e.success)
        .fold<int>(0, (sum, e) => sum + e.fileSize);
    final averageFileSize = successfulExports > 0 
        ? totalFileSize / successfulExports 
        : 0.0;

    final exportsThisMonth = _exportHistory
        .where((e) => e.createdAt.isAfter(thisMonth))
        .length;

    final exportsThisWeek = _exportHistory
        .where((e) => e.createdAt.isAfter(thisWeek))
        .length;

    final lastExportDate = _exportHistory.isNotEmpty 
        ? _exportHistory.first.createdAt 
        : null;

    return ExportStatistics(
      totalExports: _exportHistory.length,
      successfulExports: successfulExports,
      failedExports: failedExports,
      exportsByFormat: exportsByFormat,
      averageFileSize: averageFileSize,
      lastExportDate: lastExportDate,
      exportsThisMonth: exportsThisMonth,
      exportsThisWeek: exportsThisWeek,
    );
  }

  /// Clear export history
  @override
  Future<void> clearExportHistory() async {
    _exportHistory.clear();
    await _saveExportHistory();
  }

  /// Delete specific export from history
  @override
  Future<void> deleteExportFromHistory(String exportId) async {
    _exportHistory.removeWhere((result) => result.id == exportId);
    await _saveExportHistory();
  }

  /// Cleanup old export files and history
  @override
  Future<void> cleanupOldExports({Duration? olderThan}) async {
    final cutoffDate = DateTime.now().subtract(olderThan ?? const Duration(days: 30));
    
    final oldExports = _exportHistory
        .where((result) => result.createdAt.isBefore(cutoffDate))
        .toList();

    for (final export in oldExports) {
      // Delete file if it exists
      try {
        final file = File(export.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore file deletion errors
      }

      // Remove from history
      _exportHistory.remove(export);
    }

    await _saveExportHistory();
  }

  // Data mapping methods for PDF generation

  StudentReportData _mapToStudentReportData(Map<String, dynamic> data) {
    final requests =
        (data['requests'] as List<dynamic>?)
            ?.map((r) => ODRequest.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return StudentReportData(
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      registerNumber: data['registerNumber'] as String? ?? '',
      department: data['department'] as String? ?? 'Unknown',
      yearSemester: data['yearSemester'] as String? ?? 'Unknown',
      dateRange: DateRange(
        startDate: DateTime.parse(
          (data['dateRange']?['startDate'] as String?) ??
              DateTime.now().toIso8601String(),
        ),
        endDate: DateTime.parse(
          (data['dateRange']?['endDate'] as String?) ??
              DateTime.now().toIso8601String(),
        ),
      ),
      totalRequests: data['totalRequests'] as int? ?? 0,
      approvedRequests: data['approvedRequests'] as int? ?? 0,
      rejectedRequests: data['rejectedRequests'] as int? ?? 0,
      pendingRequests: data['pendingRequests'] as int? ?? 0,
      requests: requests,
      frequentReasons:
          (data['frequentReasons'] as List<dynamic>?)
              ?.map((r) => r.toString())
              .toList() ??
          [],
    );
  }

  StaffReportData _mapToStaffReportData(Map<String, dynamic> data) {
    return StaffReportData(
      staffId: data['staffId'] as String? ?? '',
      staffName: data['staffName'] as String? ?? '',
      department: data['department'] as String? ?? 'Unknown',
      designation: data['designation'] as String? ?? 'Staff',
      dateRange: DateRange(
        startDate: DateTime.parse(
          (data['dateRange']?['startDate'] as String?) ??
              DateTime.now().toIso8601String(),
        ),
        endDate: DateTime.parse(
          (data['dateRange']?['endDate'] as String?) ??
              DateTime.now().toIso8601String(),
        ),
      ),
      requestsProcessed: data['requestsProcessed'] as int? ?? 0,
      requestsApproved: data['requestsApproved'] as int? ?? 0,
      requestsRejected: data['requestsRejected'] as int? ?? 0,
      averageProcessingTime:
          (data['averageProcessingTime'] as num?)?.toDouble() ?? 0.0,
      commonRejectionReasons:
          (data['commonRejectionReasons'] as List<dynamic>?)
              ?.map((r) => r.toString())
              .toList() ??
          [],
    );
  }

  AnalyticsReportData _mapToAnalyticsReportData(Map<String, dynamic> data) {
    final analyticsData = AnalyticsData(
      totalRequests: data['totalRequests'] as int? ?? 0,
      approvedRequests: data['approvedRequests'] as int? ?? 0,
      rejectedRequests: data['rejectedRequests'] as int? ?? 0,
      pendingRequests: data['pendingRequests'] as int? ?? 0,
      approvalRate: (data['approvalRate'] as num?)?.toDouble() ?? 0.0,
      requestsByMonth: Map<String, int>.from(
        data['requestsByMonth'] as Map? ?? {},
      ),
      requestsByDepartment: Map<String, int>.from(
        data['requestsByDepartment'] as Map? ?? {},
      ),
      topRejectionReasons:
          (data['topRejectionReasons'] as List<dynamic>?)
              ?.map((r) => RejectionReason.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      patterns:
          (data['patterns'] as List<dynamic>?)
              ?.map((p) => RequestPattern.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );

    return AnalyticsReportData(
      dateRange: DateRange(
        startDate: DateTime.parse(
          (data['dateRange']?['startDate'] as String?) ??
              DateTime.now().toIso8601String(),
        ),
        endDate: DateTime.parse(
          (data['dateRange']?['endDate'] as String?) ??
              DateTime.now().toIso8601String(),
        ),
      ),
      generatedBy: (data['generatedBy'] as String?) ?? 'System',
      departmentFilter: data['departmentFilter'] as String?,
      analyticsData: analyticsData,
    );
  }

  BulkRequestsReportData _mapToBulkRequestsReportData(
    Map<String, dynamic> data,
  ) {
    final requests =
        (data['requests'] as List<dynamic>?)
            ?.map((r) => ODRequest.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return BulkRequestsReportData(
      requests: requests,
      exportedBy: (data['exportedBy'] as String?) ?? 'System',
      filterDescription: data['filterDescription'] as String?,
    );
  }

  Future<Uint8List> _generateGenericPdf(
    String title,
    Map<String, dynamic> data,
    ExportOptions options,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            // Metadata
            if (options.includeMetadata) ...[
              pw.Text(
                'Generated on: ${DateTime.now().toString()}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 10),
            ],

            // Data content
            pw.Text(
              'Report Data:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 10),

            // Convert data to readable format
            ...data.entries.map(
              (entry) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 150,
                      child: pw.Text(
                        '${entry.key}:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(child: pw.Text(entry.value.toString())),
                  ],
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Enhanced helper methods for filtering and analytics

  List<ODRequest> _applyBulkFiltering(
    List<ODRequest> requests,
    ExportOptions options,
  ) {
    final customData = options.customData;
    if (customData == null) return requests;

    var filtered = requests;

    // Apply status filter
    final statusFilter = customData['statusFilter'] as List<String>?;
    if (statusFilter != null && statusFilter.isNotEmpty) {
      filtered = filtered
          .where((r) => statusFilter.contains(r.status))
          .toList();
    }

    // Apply date range filter
    final dateRangeData = customData['dateRange'] as Map<String, dynamic>?;
    if (dateRangeData != null) {
      final startDate = DateTime.parse(dateRangeData['startDate'] as String);
      final endDate = DateTime.parse(dateRangeData['endDate'] as String);
      filtered = filtered
          .where(
            (r) =>
                r.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                r.date.isBefore(endDate.add(const Duration(days: 1))),
          )
          .toList();
    }

    return filtered;
  }

  Map<String, dynamic> _generateBulkSummary(List<ODRequest> requests) {
    final statusCounts = <String, int>{};
    final reasonCounts = <String, int>{};

    for (final request in requests) {
      statusCounts[request.status] = (statusCounts[request.status] ?? 0) + 1;
      reasonCounts[request.reason] = (reasonCounts[request.reason] ?? 0) + 1;
    }

    return {
      'totalRequests': requests.length,
      'statusBreakdown': statusCounts,
      'topReasons': reasonCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5).map((e) => {'reason': e.key, 'count': e.value}).toList(),
    };
  }

  Map<String, dynamic> _calculateStudentAnalytics(List<ODRequest> requests) {
    if (requests.isEmpty) {
      return {
        'averagePeriodsPerRequest': 0.0,
        'mostCommonPeriod': 'N/A',
        'averageProcessingTime': 0.0,
        'successRate': 0.0,
      };
    }

    final totalPeriods = requests.fold(
      0,
      (sum, req) => sum + req.periods.length,
    );
    final avgPeriods = totalPeriods / requests.length;

    final periodCounts = <int, int>{};
    for (final request in requests) {
      for (final period in request.periods) {
        periodCounts[period] = (periodCounts[period] ?? 0) + 1;
      }
    }

    final mostCommonPeriod = periodCounts.isEmpty
        ? 'N/A'
        : 'Period ${periodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key}';

    final processedRequests = requests
        .where((r) => r.approvedAt != null)
        .toList();
    final avgProcessingTime = processedRequests.isEmpty
        ? 0.0
        : processedRequests.fold(0.0, (sum, req) {
                return sum + req.approvedAt!.difference(req.createdAt).inDays;
              }) /
              processedRequests.length;

    final approvedCount = requests.where((r) => r.status == 'approved').length;
    final successRate = (approvedCount / requests.length) * 100;

    return {
      'averagePeriodsPerRequest': avgPeriods,
      'mostCommonPeriod': mostCommonPeriod,
      'averageProcessingTime': avgProcessingTime,
      'successRate': successRate,
    };
  }

  Map<String, dynamic> _calculateStaffAnalytics(Map<String, dynamic> baseData) {
    final processed = baseData['requestsProcessed'] as int? ?? 0;
    final approved = baseData['requestsApproved'] as int? ?? 0;
    final rejected = baseData['requestsRejected'] as int? ?? 0;
    final avgTime =
        (baseData['averageProcessingTime'] as num?)?.toDouble() ?? 0.0;

    final approvalRate = processed == 0 ? 0.0 : (approved / processed) * 100;
    final rejectionRate = processed == 0 ? 0.0 : (rejected / processed) * 100;

    // Calculate efficiency score (0-100)
    final timeEfficiency = avgTime <= 1.0
        ? 100.0
        : math.max(0.0, 100.0 - (avgTime - 1.0) * 10);
    final approvalEfficiency = approvalRate;
    final overallEfficiency = (timeEfficiency * 0.4 + approvalEfficiency * 0.6);

    return {
      'approvalRate': approvalRate,
      'rejectionRate': rejectionRate,
      'efficiencyScore': overallEfficiency,
      'timeEfficiency': timeEfficiency,
      'workloadLevel': _getWorkloadLevel(processed),
      'performanceCategory': _getPerformanceCategory(overallEfficiency),
    };
  }

  Map<String, dynamic> _calculatePerformanceMetrics(
    Map<String, dynamic> staffData,
  ) {
    final processed = staffData['requestsProcessed'] as int? ?? 0;
    final avgTime =
        (staffData['averageProcessingTime'] as num?)?.toDouble() ?? 0.0;

    return {
      'requestsPerDay': processed / 30.0, // Assuming monthly data
      'speedCategory': _getSpeedCategory(avgTime),
      'productivityScore': _calculateProductivityScore(processed, avgTime),
    };
  }

  String _getWorkloadLevel(int processed) {
    if (processed < 10) return 'Light';
    if (processed < 25) return 'Moderate';
    if (processed < 50) return 'Heavy';
    return 'Very Heavy';
  }

  String _getPerformanceCategory(double efficiency) {
    if (efficiency >= 90) return 'Excellent';
    if (efficiency >= 80) return 'Good';
    if (efficiency >= 70) return 'Average';
    if (efficiency >= 60) return 'Below Average';
    return 'Poor';
  }

  String _getSpeedCategory(double avgTime) {
    if (avgTime <= 1.0) return 'Very Fast';
    if (avgTime <= 2.0) return 'Fast';
    if (avgTime <= 4.0) return 'Average';
    if (avgTime <= 7.0) return 'Slow';
    return 'Very Slow';
  }

  double _calculateProductivityScore(int processed, double avgTime) {
    final volumeScore = math.min(100.0, processed * 2.0);
    final speedScore = avgTime <= 1.0
        ? 100.0
        : math.max(0.0, 100.0 - (avgTime - 1.0) * 15);
    return (volumeScore * 0.6 + speedScore * 0.4);
  }

  // Filter extraction methods

  StudentReportFilter? _extractStudentFilter(ExportOptions options) {
    final customData = options.customData;
    if (customData == null) return null;

    return StudentReportFilter(
      statuses: (customData['statusFilter'] as List<dynamic>?)?.cast<String>(),
      dateRange: customData['dateRange'] != null
          ? DateRange(
              startDate: DateTime.parse(
                customData['dateRange']['startDate'] as String,
              ),
              endDate: DateTime.parse(
                customData['dateRange']['endDate'] as String,
              ),
            )
          : null,
      reasonKeyword: customData['reasonKeyword'] as String?,
    );
  }

  StaffReportFilter? _extractStaffFilter(ExportOptions options) {
    final customData = options.customData;
    if (customData == null) return null;

    return StaffReportFilter(
      dateRange: customData['dateRange'] != null
          ? DateRange(
              startDate: DateTime.parse(
                customData['dateRange']['startDate'] as String,
              ),
              endDate: DateTime.parse(
                customData['dateRange']['endDate'] as String,
              ),
            )
          : null,
      departments: (customData['departments'] as List<dynamic>?)
          ?.cast<String>(),
    );
  }

  BulkReportFilter? _extractBulkFilter(ExportOptions options) {
    final customData = options.customData;
    if (customData == null) return null;

    return BulkReportFilter(
      statuses: (customData['statusFilter'] as List<dynamic>?)?.cast<String>(),
      departments: (customData['departments'] as List<dynamic>?)
          ?.cast<String>(),
      dateRange: customData['dateRange'] != null
          ? DateRange(
              startDate: DateTime.parse(
                customData['dateRange']['startDate'] as String,
              ),
              endDate: DateTime.parse(
                customData['dateRange']['endDate'] as String,
              ),
            )
          : null,
    );
  }

  // Enhanced CSV generation methods

  void _generateStudentCsvContent(
    StringBuffer csvContent,
    Map<String, dynamic> data,
    ExportOptions options,
  ) {
    // Student information header
    csvContent.writeln('Student Information');
    csvContent.writeln('Field,Value');
    csvContent.writeln('Student ID,${data['studentId']}');
    csvContent.writeln('Student Name,${data['studentName']}');
    csvContent.writeln('Register Number,${data['registerNumber']}');
    csvContent.writeln('Department,${data['department']}');
    csvContent.writeln('Year/Semester,${data['yearSemester']}');
    csvContent.writeln('');

    // Summary statistics
    csvContent.writeln('Summary Statistics');
    csvContent.writeln('Metric,Value');
    csvContent.writeln('Total Requests,${data['totalRequests']}');
    csvContent.writeln('Approved Requests,${data['approvedRequests']}');
    csvContent.writeln('Rejected Requests,${data['rejectedRequests']}');
    csvContent.writeln('Pending Requests,${data['pendingRequests']}');
    csvContent.writeln('');

    // Request details
    csvContent.writeln('Request Details');
    csvContent.writeln('Date,Periods,Reason,Status,Approved By,Created At');

    final requests = (data['requests'] as List<dynamic>?) ?? [];
    for (final requestData in requests) {
      final request = ODRequest.fromJson(requestData as Map<String, dynamic>);
      csvContent.writeln(
        '${request.date.toString().substring(0, 10)},${request.periods.join(';')},${request.reason.replaceAll(',', ';')},${request.status},${request.approvedBy ?? ''},${request.createdAt.toString().substring(0, 10)}',
      );
    }
  }

  void _generateStaffCsvContent(
    StringBuffer csvContent,
    Map<String, dynamic> data,
    ExportOptions options,
  ) {
    // Staff information header
    csvContent.writeln('Staff Information');
    csvContent.writeln('Field,Value');
    csvContent.writeln('Staff ID,${data['staffId']}');
    csvContent.writeln('Staff Name,${data['staffName']}');
    csvContent.writeln('Department,${data['department']}');
    csvContent.writeln('Designation,${data['designation']}');
    csvContent.writeln('');

    // Performance metrics
    csvContent.writeln('Performance Metrics');
    csvContent.writeln('Metric,Value');
    csvContent.writeln('Requests Processed,${data['requestsProcessed']}');
    csvContent.writeln('Requests Approved,${data['requestsApproved']}');
    csvContent.writeln('Requests Rejected,${data['requestsRejected']}');
    csvContent.writeln(
      'Average Processing Time,${data['averageProcessingTime']} hours',
    );

    final analytics = data['analytics'] as Map<String, dynamic>? ?? {};
    csvContent.writeln(
      'Approval Rate,${analytics['approvalRate']?.toStringAsFixed(1) ?? '0.0'}%',
    );
    csvContent.writeln(
      'Efficiency Score,${analytics['efficiencyScore']?.toStringAsFixed(1) ?? '0.0'}',
    );
    csvContent.writeln('');
  }

  void _generateAnalyticsCsvContent(
    StringBuffer csvContent,
    Map<String, dynamic> data,
    ExportOptions options,
  ) {
    csvContent.writeln('Analytics Report');
    csvContent.writeln('Metric,Value');
    csvContent.writeln('Total Requests,${data['totalRequests']}');
    csvContent.writeln('Approved Requests,${data['approvedRequests']}');
    csvContent.writeln('Rejected Requests,${data['rejectedRequests']}');
    csvContent.writeln('Pending Requests,${data['pendingRequests']}');
    csvContent.writeln('Approval Rate,${data['approvalRate']}%');
    csvContent.writeln('');
  }

  void _generateBulkCsvContent(
    StringBuffer csvContent,
    Map<String, dynamic> data,
    ExportOptions options,
  ) {
    // Summary
    csvContent.writeln('Bulk Export Summary');
    csvContent.writeln('Field,Value');
    csvContent.writeln('Total Requests,${data['totalRequests']}');
    csvContent.writeln('Export Date,${data['generatedAt']}');
    csvContent.writeln('');

    // Request details
    csvContent.writeln('Request Details');
    csvContent.writeln(
      'Student Name,Register Number,Date,Reason,Periods,Status,Created At',
    );

    final requests = (data['requests'] as List<dynamic>?) ?? [];
    for (final requestData in requests) {
      final request = ODRequest.fromJson(requestData as Map<String, dynamic>);
      csvContent.writeln(
        '${request.studentName},${request.registerNumber},${request.date.toString().substring(0, 10)},${request.reason.replaceAll(',', ';')},${request.periods.join(';')},${request.status},${request.createdAt.toString().substring(0, 10)}',
      );
    }
  }
}

// Enums and additional models

enum ReportType { student, staff, analytics, bulk }
