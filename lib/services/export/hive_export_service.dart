import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/analytics_models.dart';

import 'package:odtrack_academia/services/export/export_service.dart';
import 'package:odtrack_academia/services/export/pdf_generator.dart';
import 'package:odtrack_academia/core/storage/enhanced_storage_manager.dart';

/// Hive-based implementation of ExportService
class HiveExportService implements ExportService {
  final EnhancedStorageManager _storageManager;
  final PDFGenerator _pdfGenerator;
  final StreamController<ExportProgress> _progressController = StreamController<ExportProgress>.broadcast();
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
      
      // Get student data from storage
      final studentData = await _getStudentData(studentId, dateRange);
      
      _updateProgress(exportId, 0.4, 'Generating report...');
      
      // Generate the report based on format
      final result = await _generateReport(
        exportId,
        'Student Report - $studentId',
        studentData,
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
      _updateProgress(exportId, 0.1, 'Preparing staff data...');
      
      // Get staff data from storage
      final staffData = await _getStaffData(staffId, dateRange);
      
      _updateProgress(exportId, 0.4, 'Generating report...');
      
      // Generate the report based on format
      final result = await _generateReport(
        exportId,
        'Staff Report - $staffId',
        staffData,
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
        'topRejectionReasons': data.topRejectionReasons.map((r) => {
          'reason': r.reason,
          'count': r.count,
          'percentage': r.percentage,
        }).toList(),
        'patterns': data.patterns.map((p) => {
          'pattern': p.pattern,
          'description': p.description,
          'confidence': p.confidence,
        }).toList(),
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
      _updateProgress(exportId, 0.1, 'Preparing bulk request data...');
      
      final reportData = {
        'title': options.customTitle ?? 'Bulk OD Requests Export',
        'generatedAt': DateTime.now().toIso8601String(),
        'totalRequests': requests.length,
        'requests': requests.map((request) => {
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
        }).toList(),
      };
      
      _updateProgress(exportId, 0.4, 'Generating report...');
      
      // Generate the report based on format
      final result = await _generateReport(
        exportId,
        options.customTitle ?? 'Bulk OD Requests',
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
    _updateProgress(exportId, 1.0, 'Cancelled');
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

  void _updateProgress(String exportId, double progress, String message) {
    _progressController.add(ExportProgress(
      exportId: exportId,
      progress: progress,
      currentStep: message,
      message: message,
    ));
  }

  Future<Map<String, dynamic>> _getStudentData(String studentId, DateRange dateRange) async {
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
      'frequentReasons': ['Medical appointment', 'Family function', 'Personal work'],
    };
  }

  Future<Map<String, dynamic>> _getStaffData(String staffId, DateRange dateRange) async {
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
        'Exceeds monthly limit'
      ],
    };
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
    final fileName = '${title.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
    final fileName = '${title.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.csv';
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

  // Data mapping methods for PDF generation

  StudentReportData _mapToStudentReportData(Map<String, dynamic> data) {
    final requests = (data['requests'] as List<dynamic>?)
        ?.map((r) => ODRequest.fromJson(r as Map<String, dynamic>))
        .toList() ?? [];
    
    return StudentReportData(
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      registerNumber: data['registerNumber'] as String? ?? '',
      department: data['department'] as String? ?? 'Unknown',
      yearSemester: data['yearSemester'] as String? ?? 'Unknown',
      dateRange: DateRange(
        startDate: DateTime.parse((data['dateRange']?['startDate'] as String?) ?? DateTime.now().toIso8601String()),
        endDate: DateTime.parse((data['dateRange']?['endDate'] as String?) ?? DateTime.now().toIso8601String()),
      ),
      totalRequests: data['totalRequests'] as int? ?? 0,
      approvedRequests: data['approvedRequests'] as int? ?? 0,
      rejectedRequests: data['rejectedRequests'] as int? ?? 0,
      pendingRequests: data['pendingRequests'] as int? ?? 0,
      requests: requests,
      frequentReasons: (data['frequentReasons'] as List<dynamic>?)
          ?.map((r) => r.toString())
          .toList() ?? [],
    );
  }

  StaffReportData _mapToStaffReportData(Map<String, dynamic> data) {
    return StaffReportData(
      staffId: data['staffId'] as String? ?? '',
      staffName: data['staffName'] as String? ?? '',
      department: data['department'] as String? ?? 'Unknown',
      designation: data['designation'] as String? ?? 'Staff',
      dateRange: DateRange(
        startDate: DateTime.parse((data['dateRange']?['startDate'] as String?) ?? DateTime.now().toIso8601String()),
        endDate: DateTime.parse((data['dateRange']?['endDate'] as String?) ?? DateTime.now().toIso8601String()),
      ),
      requestsProcessed: data['requestsProcessed'] as int? ?? 0,
      requestsApproved: data['requestsApproved'] as int? ?? 0,
      requestsRejected: data['requestsRejected'] as int? ?? 0,
      averageProcessingTime: (data['averageProcessingTime'] as num?)?.toDouble() ?? 0.0,
      commonRejectionReasons: (data['commonRejectionReasons'] as List<dynamic>?)
          ?.map((r) => r.toString())
          .toList() ?? [],
    );
  }

  AnalyticsReportData _mapToAnalyticsReportData(Map<String, dynamic> data) {
    final analyticsData = AnalyticsData(
      totalRequests: data['totalRequests'] as int? ?? 0,
      approvedRequests: data['approvedRequests'] as int? ?? 0,
      rejectedRequests: data['rejectedRequests'] as int? ?? 0,
      pendingRequests: data['pendingRequests'] as int? ?? 0,
      approvalRate: (data['approvalRate'] as num?)?.toDouble() ?? 0.0,
      requestsByMonth: Map<String, int>.from(data['requestsByMonth'] as Map? ?? {}),
      requestsByDepartment: Map<String, int>.from(data['requestsByDepartment'] as Map? ?? {}),
      topRejectionReasons: (data['topRejectionReasons'] as List<dynamic>?)
          ?.map((r) => RejectionReason.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      patterns: (data['patterns'] as List<dynamic>?)
          ?.map((p) => RequestPattern.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
    );

    return AnalyticsReportData(
      dateRange: DateRange(
        startDate: DateTime.parse((data['dateRange']?['startDate'] as String?) ?? DateTime.now().toIso8601String()),
        endDate: DateTime.parse((data['dateRange']?['endDate'] as String?) ?? DateTime.now().toIso8601String()),
      ),
      generatedBy: (data['generatedBy'] as String?) ?? 'System',
      departmentFilter: data['departmentFilter'] as String?,
      analyticsData: analyticsData,
    );
  }

  BulkRequestsReportData _mapToBulkRequestsReportData(Map<String, dynamic> data) {
    final requests = (data['requests'] as List<dynamic>?)
        ?.map((r) => ODRequest.fromJson(r as Map<String, dynamic>))
        .toList() ?? [];

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
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            
            pw.SizedBox(height: 10),
            
            // Convert data to readable format
            ...data.entries.map((entry) => pw.Padding(
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
                  pw.Expanded(
                    child: pw.Text(entry.value.toString()),
                  ),
                ],
              ),
            )),
          ];
        },
      ),
    );
    
    return pdf.save();
  }
}