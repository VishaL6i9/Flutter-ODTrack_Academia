import 'dart:typed_data';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/export_filters.dart';

/// PDF Generator service for creating professionally formatted PDF documents
class PDFGenerator {
  static const String _institutionName = 'ODTrack Academia';
  static const String _institutionAddress = 'Academic Institution Address';
  static const String _institutionPhone = '+91 XXXXX XXXXX';
  static const String _institutionEmail = 'info@odtrack-academia.edu';

  /// Generate student OD report PDF with filtering options
  Future<Uint8List> generateStudentReport(
    StudentReportData data, {
    StudentReportFilter? filter,
    ExportOptions? options,
  }) async {
    final pdf = pw.Document();

    // Apply filtering if provided
    final filteredData = filter != null
        ? _applyStudentFilter(data, filter)
        : data;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context, 'Student OD Report'),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildStudentReportContent(filteredData, options),
      ),
    );

    return pdf.save();
  }

  /// Generate staff analytics report PDF with charts and summaries
  Future<Uint8List> generateStaffReport(
    StaffReportData data, {
    StaffReportFilter? filter,
    ExportOptions? options,
  }) async {
    final pdf = pw.Document();

    // Apply filtering if provided
    final filteredData = filter != null
        ? _applyStaffFilter(data, filter)
        : data;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context, 'Staff Analytics Report'),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildStaffReportContent(filteredData, options),
      ),
    );

    return pdf.save();
  }

  /// Generate analytics dashboard report PDF
  Future<Uint8List> generateAnalyticsReport(AnalyticsReportData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) =>
            _buildHeader(context, 'Analytics Dashboard Report'),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildAnalyticsReportContent(data),
      ),
    );

    return pdf.save();
  }

  /// Generate bulk requests export PDF with custom formatting
  Future<Uint8List> generateBulkRequestsReport(
    BulkRequestsReportData data, {
    BulkReportFilter? filter,
    ExportOptions? options,
  }) async {
    final pdf = pw.Document();

    // Apply filtering if provided
    final filteredData = filter != null ? _applyBulkFilter(data, filter) : data;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          context,
          options?.customTitle ?? 'Bulk OD Requests Export',
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildBulkRequestsContent(filteredData, options),
      ),
    );

    return pdf.save();
  }

  // Header with institutional branding
  pw.Widget _buildHeader(pw.Context context, String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _institutionName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _institutionAddress,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Phone: $_institutionPhone | Email: $_institutionEmail',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Container(
                width: 60,
                height: 60,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue800, width: 2),
                  borderRadius: pw.BorderRadius.circular(30),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'OD',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            width: double.infinity,
            height: 2,
            color: PdfColors.blue800,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  // Footer with page numbers and generation info
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            height: 1,
            color: PdfColors.grey400,
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated on: ${DateTime.now().toString().substring(0, 19)}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Student report content with enhanced filtering and charts
  List<pw.Widget> _buildStudentReportContent(
    StudentReportData data,
    ExportOptions? options,
  ) {
    return [
      // Student Information Section
      _buildSectionTitle('Student Information'),
      _buildInfoTable([
        ['Student ID', data.studentId],
        ['Student Name', data.studentName],
        ['Register Number', data.registerNumber],
        ['Department', data.department],
        ['Year/Semester', data.yearSemester],
        [
          'Report Period',
          '${data.dateRange.startDate.toString().substring(0, 10)} to ${data.dateRange.endDate.toString().substring(0, 10)}',
        ],
      ]),

      pw.SizedBox(height: 20),

      // Summary Statistics
      _buildSectionTitle('OD Request Summary'),
      _buildSummaryCards([
        SummaryCard(
          'Total Requests',
          data.totalRequests.toString(),
          PdfColors.blue,
        ),
        SummaryCard(
          'Approved',
          data.approvedRequests.toString(),
          PdfColors.green,
        ),
        SummaryCard(
          'Rejected',
          data.rejectedRequests.toString(),
          PdfColors.red,
        ),
        SummaryCard(
          'Pending',
          data.pendingRequests.toString(),
          PdfColors.orange,
        ),
      ]),

      pw.SizedBox(height: 20),

      // Request Details Table
      _buildSectionTitle('Request Details'),
      _buildRequestsTable(data.requests),

      if (data.frequentReasons.isNotEmpty) ...[
        pw.SizedBox(height: 20),
        _buildSectionTitle('Frequent Request Reasons'),
        _buildFrequentReasonsList(data.frequentReasons),
      ],

      // Include charts if requested
      if (options?.includeCharts == true) ...[
        pw.SizedBox(height: 20),
        _buildSectionTitle('Request Status Distribution'),
        _buildStudentStatusChart(data),

        pw.SizedBox(height: 20),
        _buildSectionTitle('Monthly Request Trend'),
        _buildStudentMonthlyChart(data),
      ],

      // Include additional analytics if available
      if (data.requests.isNotEmpty) ...[
        pw.SizedBox(height: 20),
        _buildSectionTitle('Request Analysis'),
        _buildStudentAnalytics(data),
      ],
    ];
  }

  // Staff report content with enhanced analytics and charts
  List<pw.Widget> _buildStaffReportContent(
    StaffReportData data,
    ExportOptions? options,
  ) {
    return [
      // Staff Information Section
      _buildSectionTitle('Staff Information'),
      _buildInfoTable([
        ['Staff ID', data.staffId],
        ['Staff Name', data.staffName],
        ['Department', data.department],
        ['Designation', data.designation],
        [
          'Report Period',
          '${data.dateRange.startDate.toString().substring(0, 10)} to ${data.dateRange.endDate.toString().substring(0, 10)}',
        ],
      ]),

      pw.SizedBox(height: 20),

      // Processing Statistics
      _buildSectionTitle('OD Processing Summary'),
      _buildSummaryCards([
        SummaryCard(
          'Requests Processed',
          data.requestsProcessed.toString(),
          PdfColors.blue,
        ),
        SummaryCard(
          'Approved',
          data.requestsApproved.toString(),
          PdfColors.green,
        ),
        SummaryCard(
          'Rejected',
          data.requestsRejected.toString(),
          PdfColors.red,
        ),
        SummaryCard(
          'Avg. Processing Time',
          '${data.averageProcessingTime.toStringAsFixed(1)} hrs',
          PdfColors.purple,
        ),
      ]),

      pw.SizedBox(height: 20),

      // Performance Metrics
      _buildSectionTitle('Performance Metrics'),
      _buildInfoTable([
        [
          'Approval Rate',
          '${((data.requestsApproved / data.requestsProcessed) * 100).toStringAsFixed(1)}%',
        ],
        [
          'Response Time',
          '${data.averageProcessingTime.toStringAsFixed(1)} hours',
        ],
        [
          'Efficiency Score',
          _calculateEfficiencyScore(data).toStringAsFixed(1),
        ],
      ]),

      if (data.commonRejectionReasons.isNotEmpty) ...[
        pw.SizedBox(height: 20),
        _buildSectionTitle('Common Rejection Reasons'),
        _buildFrequentReasonsList(data.commonRejectionReasons),
      ],

      // Include charts if requested
      if (options?.includeCharts == true) ...[
        pw.SizedBox(height: 20),
        _buildSectionTitle('Processing Performance Charts'),
        _buildStaffPerformanceChart(data),

        pw.SizedBox(height: 20),
        _buildSectionTitle('Approval vs Rejection Ratio'),
        _buildStaffApprovalChart(data),
      ],

      // Include detailed analytics
      pw.SizedBox(height: 20),
      _buildSectionTitle('Detailed Performance Analysis'),
      _buildStaffDetailedAnalytics(data),
    ];
  }

  // Analytics report content
  List<pw.Widget> _buildAnalyticsReportContent(AnalyticsReportData data) {
    return [
      // Report Information
      _buildSectionTitle('Analytics Overview'),
      _buildInfoTable([
        [
          'Report Period',
          '${data.dateRange.startDate.toString().substring(0, 10)} to ${data.dateRange.endDate.toString().substring(0, 10)}',
        ],
        ['Generated By', data.generatedBy],
        ['Department Filter', data.departmentFilter ?? 'All Departments'],
      ]),

      pw.SizedBox(height: 20),

      // Overall Statistics
      _buildSectionTitle('Overall Statistics'),
      _buildSummaryCards([
        SummaryCard(
          'Total Requests',
          data.analyticsData.totalRequests.toString(),
          PdfColors.blue,
        ),
        SummaryCard(
          'Approved',
          data.analyticsData.approvedRequests.toString(),
          PdfColors.green,
        ),
        SummaryCard(
          'Rejected',
          data.analyticsData.rejectedRequests.toString(),
          PdfColors.red,
        ),
        SummaryCard(
          'Approval Rate',
          '${data.analyticsData.approvalRate.toStringAsFixed(1)}%',
          PdfColors.purple,
        ),
      ]),

      pw.SizedBox(height: 20),

      // Department-wise Breakdown
      if (data.analyticsData.requestsByDepartment.isNotEmpty) ...[
        _buildSectionTitle('Department-wise Breakdown'),
        _buildDepartmentTable(data.analyticsData.requestsByDepartment),
        pw.SizedBox(height: 20),
      ],

      // Monthly Trends
      if (data.analyticsData.requestsByMonth.isNotEmpty) ...[
        _buildSectionTitle('Monthly Trends'),
        _buildMonthlyTable(data.analyticsData.requestsByMonth),
        pw.SizedBox(height: 20),
      ],

      // Top Rejection Reasons
      if (data.analyticsData.topRejectionReasons.isNotEmpty) ...[
        _buildSectionTitle('Top Rejection Reasons'),
        _buildRejectionReasonsTable(data.analyticsData.topRejectionReasons),
      ],
    ];
  }

  // Bulk requests content with custom formatting
  List<pw.Widget> _buildBulkRequestsContent(
    BulkRequestsReportData data,
    ExportOptions? options,
  ) {
    return [
      // Export Information
      _buildSectionTitle('Export Information'),
      _buildInfoTable([
        ['Total Requests', data.requests.length.toString()],
        ['Export Date', DateTime.now().toString().substring(0, 19)],
        ['Exported By', data.exportedBy],
        ['Filter Applied', data.filterDescription ?? 'None'],
      ]),

      pw.SizedBox(height: 20),

      // Summary Statistics
      if (data.requests.isNotEmpty) ...[
        _buildSectionTitle('Summary Statistics'),
        _buildBulkSummaryStats(data.requests),
        pw.SizedBox(height: 20),
      ],

      // Requests Table with custom formatting
      _buildSectionTitle('OD Requests'),
      _buildEnhancedBulkRequestsTable(data.requests, options),

      // Include charts if requested
      if (options?.includeCharts == true && data.requests.isNotEmpty) ...[
        pw.SizedBox(height: 20),
        _buildSectionTitle('Request Distribution'),
        _buildBulkRequestsChart(data.requests),
      ],
    ];
  }

  // Helper methods for building components

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
    );
  }

  pw.Widget _buildInfoTable(List<List<String>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(150),
        1: const pw.FlexColumnWidth(),
      },
      children: data
          .map(
            (row) => pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.grey100,
                  child: pw.Text(
                    row[0],
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(row[1]),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildSummaryCards(List<SummaryCard> cards) {
    return pw.Row(
      children: cards
          .map(
            (card) => pw.Expanded(
              child: pw.Container(
                margin: const pw.EdgeInsets.only(right: 10),
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: _getLightColor(card.color),
                  border: pw.Border.all(color: card.color),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      card.value,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: card.color,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      card.title,
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildRequestsTable(List<ODRequest> requests) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(80),
        1: const pw.FixedColumnWidth(100),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(80),
        4: const pw.FixedColumnWidth(80),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Periods', isHeader: true),
            _buildTableCell('Reason', isHeader: true),
            _buildTableCell('Status', isHeader: true),
            _buildTableCell('Approved By', isHeader: true),
          ],
        ),
        // Data rows
        ...requests.map(
          (request) => pw.TableRow(
            children: [
              _buildTableCell(request.date.toString().substring(0, 10)),
              _buildTableCell(request.periods.join(', ')),
              _buildTableCell(request.reason),
              _buildTableCell(request.status.toUpperCase()),
              _buildTableCell(request.approvedBy ?? '-'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildBulkRequestsTable(List<ODRequest> requests) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(100),
        1: const pw.FixedColumnWidth(120),
        2: const pw.FixedColumnWidth(80),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FixedColumnWidth(80),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Student Name', isHeader: true),
            _buildTableCell('Register No.', isHeader: true),
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Reason', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        // Data rows
        ...requests.map(
          (request) => pw.TableRow(
            children: [
              _buildTableCell(request.studentName),
              _buildTableCell(request.registerNumber),
              _buildTableCell(request.date.toString().substring(0, 10)),
              _buildTableCell(request.reason),
              _buildTableCell(request.status.toUpperCase()),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDepartmentTable(Map<String, int> departmentData) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FixedColumnWidth(100),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Department', isHeader: true),
            _buildTableCell('Requests', isHeader: true),
          ],
        ),
        // Data rows
        ...departmentData.entries.map(
          (entry) => pw.TableRow(
            children: [
              _buildTableCell(entry.key),
              _buildTableCell(entry.value.toString()),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMonthlyTable(Map<String, int> monthlyData) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FixedColumnWidth(100),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Month', isHeader: true),
            _buildTableCell('Requests', isHeader: true),
          ],
        ),
        // Data rows
        ...monthlyData.entries.map(
          (entry) => pw.TableRow(
            children: [
              _buildTableCell(entry.key),
              _buildTableCell(entry.value.toString()),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildRejectionReasonsTable(List<RejectionReason> reasons) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FixedColumnWidth(80),
        2: const pw.FixedColumnWidth(80),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Reason', isHeader: true),
            _buildTableCell('Count', isHeader: true),
            _buildTableCell('Percentage', isHeader: true),
          ],
        ),
        // Data rows
        ...reasons.map(
          (reason) => pw.TableRow(
            children: [
              _buildTableCell(reason.reason),
              _buildTableCell(reason.count.toString()),
              _buildTableCell('${reason.percentage.toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFrequentReasonsList(List<String> reasons) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: reasons
          .map(
            (reason) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 6,
                    height: 6,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue800,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(reason),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }

  double _calculateEfficiencyScore(StaffReportData data) {
    // Simple efficiency calculation based on processing time and approval rate
    final approvalRate = data.requestsApproved / data.requestsProcessed;
    final timeEfficiency =
        1 / (data.averageProcessingTime + 1); // Inverse of processing time
    return (approvalRate * 0.6 + timeEfficiency * 0.4) * 100;
  }

  PdfColor _getLightColor(PdfColor color) {
    // Create a lighter version of the color for backgrounds
    if (color == PdfColors.blue) return PdfColors.blue50;
    if (color == PdfColors.green) return PdfColors.green50;
    if (color == PdfColors.red) return PdfColors.red50;
    if (color == PdfColors.orange) return PdfColors.orange50;
    if (color == PdfColors.purple) return PdfColors.purple50;
    return PdfColors.grey100; // Default light color
  }

  // Filtering methods

  StudentReportData _applyStudentFilter(
    StudentReportData data,
    StudentReportFilter filter,
  ) {
    var filteredRequests = data.requests.where((request) {
      // Filter by status
      if (filter.statuses != null && filter.statuses!.isNotEmpty) {
        if (!filter.statuses!.contains(request.status)) return false;
      }

      // Filter by date range
      if (filter.dateRange != null) {
        if (request.date.isBefore(filter.dateRange!.startDate) ||
            request.date.isAfter(filter.dateRange!.endDate)) {
          return false;
        }
      }

      // Filter by reason
      if (filter.reasonKeyword != null && filter.reasonKeyword!.isNotEmpty) {
        if (!request.reason.toLowerCase().contains(
          filter.reasonKeyword!.toLowerCase(),
        )) {
          return false;
        }
      }

      return true;
    }).toList();

    // Recalculate statistics based on filtered requests
    final approved = filteredRequests
        .where((r) => r.status == 'approved')
        .length;
    final rejected = filteredRequests
        .where((r) => r.status == 'rejected')
        .length;
    final pending = filteredRequests.where((r) => r.status == 'pending').length;

    return StudentReportData(
      studentId: data.studentId,
      studentName: data.studentName,
      registerNumber: data.registerNumber,
      department: data.department,
      yearSemester: data.yearSemester,
      dateRange: filter.dateRange ?? data.dateRange,
      totalRequests: filteredRequests.length,
      approvedRequests: approved,
      rejectedRequests: rejected,
      pendingRequests: pending,
      requests: filteredRequests,
      frequentReasons: _calculateFrequentReasons(filteredRequests),
    );
  }

  StaffReportData _applyStaffFilter(
    StaffReportData data,
    StaffReportFilter filter,
  ) {
    // For staff reports, filtering would be applied to the underlying request data
    // This is a simplified implementation
    return data;
  }

  BulkRequestsReportData _applyBulkFilter(
    BulkRequestsReportData data,
    BulkReportFilter filter,
  ) {
    var filteredRequests = data.requests.where((request) {
      // Filter by status
      if (filter.statuses != null && filter.statuses!.isNotEmpty) {
        if (!filter.statuses!.contains(request.status)) return false;
      }

      // Filter by department
      if (filter.departments != null && filter.departments!.isNotEmpty) {
        // Assuming we have department info in the request or can derive it
        // For now, we'll skip this filter
      }

      // Filter by date range
      if (filter.dateRange != null) {
        if (request.date.isBefore(filter.dateRange!.startDate) ||
            request.date.isAfter(filter.dateRange!.endDate)) {
          return false;
        }
      }

      return true;
    }).toList();

    return BulkRequestsReportData(
      requests: filteredRequests,
      exportedBy: data.exportedBy,
      filterDescription: _buildFilterDescription(filter),
    );
  }

  List<String> _calculateFrequentReasons(List<ODRequest> requests) {
    final reasonCounts = <String, int>{};
    for (final request in requests) {
      reasonCounts[request.reason] = (reasonCounts[request.reason] ?? 0) + 1;
    }

    final sortedReasons = reasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedReasons.take(5).map((e) => e.key).toList();
  }

  String _buildFilterDescription(BulkReportFilter filter) {
    final descriptions = <String>[];

    if (filter.statuses != null && filter.statuses!.isNotEmpty) {
      descriptions.add('Status: ${filter.statuses!.join(', ')}');
    }

    if (filter.departments != null && filter.departments!.isNotEmpty) {
      descriptions.add('Departments: ${filter.departments!.join(', ')}');
    }

    if (filter.dateRange != null) {
      descriptions.add(
        'Date Range: ${filter.dateRange!.startDate.toString().substring(0, 10)} to ${filter.dateRange!.endDate.toString().substring(0, 10)}',
      );
    }

    return descriptions.isEmpty
        ? 'No filters applied'
        : descriptions.join('; ');
  }

  // Chart building methods

  pw.Widget _buildStudentStatusChart(StudentReportData data) {
    return _buildPieChart([
      ChartSegment(
        'Approved',
        data.approvedRequests.toDouble(),
        PdfColors.green,
      ),
      ChartSegment('Rejected', data.rejectedRequests.toDouble(), PdfColors.red),
      ChartSegment(
        'Pending',
        data.pendingRequests.toDouble(),
        PdfColors.orange,
      ),
    ]);
  }

  pw.Widget _buildStudentMonthlyChart(StudentReportData data) {
    final monthlyData = <String, int>{};
    for (final request in data.requests) {
      final monthKey =
          '${request.date.year}-${request.date.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
    }

    return _buildBarChart(
      monthlyData.entries
          .map((e) => ChartSegment(e.key, e.value.toDouble(), PdfColors.blue))
          .toList(),
    );
  }

  pw.Widget _buildStaffPerformanceChart(StaffReportData data) {
    return _buildBarChart([
      ChartSegment(
        'Processed',
        data.requestsProcessed.toDouble(),
        PdfColors.blue,
      ),
      ChartSegment(
        'Approved',
        data.requestsApproved.toDouble(),
        PdfColors.green,
      ),
      ChartSegment('Rejected', data.requestsRejected.toDouble(), PdfColors.red),
    ]);
  }

  pw.Widget _buildStaffApprovalChart(StaffReportData data) {
    if (data.requestsProcessed == 0) {
      return pw.Text('No data available for chart');
    }

    return _buildPieChart([
      ChartSegment(
        'Approved',
        data.requestsApproved.toDouble(),
        PdfColors.green,
      ),
      ChartSegment('Rejected', data.requestsRejected.toDouble(), PdfColors.red),
    ]);
  }

  pw.Widget _buildBulkRequestsChart(List<ODRequest> requests) {
    final statusCounts = <String, int>{};
    for (final request in requests) {
      statusCounts[request.status] = (statusCounts[request.status] ?? 0) + 1;
    }

    final colors = {
      'approved': PdfColors.green,
      'rejected': PdfColors.red,
      'pending': PdfColors.orange,
    };

    return _buildPieChart(
      statusCounts.entries
          .map(
            (e) => ChartSegment(
              e.key.toUpperCase(),
              e.value.toDouble(),
              colors[e.key] ?? PdfColors.grey,
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildPieChart(List<ChartSegment> segments) {
    if (segments.isEmpty) {
      return pw.Text('No data available for chart');
    }

    final total = segments.fold(0.0, (sum, segment) => sum + segment.value);
    if (total == 0) {
      return pw.Text('No data available for chart');
    }

    return pw.Container(
      height: 200,
      child: pw.Row(
        children: [
          // Simplified chart representation using colored rectangles
          pw.Container(
            width: 200,
            height: 200,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Center(
              child: pw.Text(
                'Pie Chart\n(${segments.length} segments)',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
          ),

          pw.SizedBox(width: 20),

          // Legend with data
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: segments
                  .map(
                    (segment) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 12,
                            height: 12,
                            color: segment.color,
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: pw.Text(
                              '${segment.label}: ${segment.value.toInt()} (${((segment.value / total) * 100).toStringAsFixed(1)}%)',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBarChart(List<ChartSegment> segments) {
    if (segments.isEmpty) {
      return pw.Text('No data available for chart');
    }

    final maxValue = segments.fold(
      0.0,
      (max, segment) => math.max(max, segment.value),
    );
    if (maxValue == 0) {
      return pw.Text('No data available for chart');
    }

    return pw.Container(
      height: 200,
      child: pw.Column(
        children: [
          // Chart area with simplified bars
          pw.Expanded(
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: segments.map((segment) {
                  final heightPercentage = (segment.value / maxValue);
                  final barHeight = heightPercentage * 120; // Max height of 120

                  return pw.Expanded(
                    child: pw.Container(
                      margin: const pw.EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            segment.value.toInt().toString(),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            width: double.infinity,
                            height: math.max(
                              barHeight,
                              10,
                            ), // Minimum height of 10
                            color: segment.color,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          pw.SizedBox(height: 8),

          // Labels
          pw.Row(
            children: segments
                .map(
                  (segment) => pw.Expanded(
                    child: pw.Text(
                      segment.label,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // Enhanced analytics methods

  pw.Widget _buildStudentAnalytics(StudentReportData data) {
    final avgPeriodsPerRequest = data.requests.isEmpty
        ? 0.0
        : data.requests.fold(0, (sum, req) => sum + req.periods.length) /
              data.requests.length;

    final mostCommonPeriod = _getMostCommonPeriod(data.requests);
    final avgProcessingTime = _calculateAvgProcessingTime(data.requests);

    return _buildInfoTable([
      ['Average Periods per Request', avgPeriodsPerRequest.toStringAsFixed(1)],
      ['Most Common Period', mostCommonPeriod],
      [
        'Average Processing Time',
        '${avgProcessingTime.toStringAsFixed(1)} days',
      ],
      [
        'Success Rate',
        '${((data.approvedRequests / (data.totalRequests == 0 ? 1 : data.totalRequests)) * 100).toStringAsFixed(1)}%',
      ],
    ]);
  }

  pw.Widget _buildStaffDetailedAnalytics(StaffReportData data) {
    final efficiencyScore = _calculateEfficiencyScore(data);
    final workloadLevel = _calculateWorkloadLevel(data);

    return _buildInfoTable([
      ['Efficiency Score', '${efficiencyScore.toStringAsFixed(1)}/100'],
      ['Workload Level', workloadLevel],
      [
        'Approval Rate',
        '${((data.requestsApproved / (data.requestsProcessed == 0 ? 1 : data.requestsProcessed)) * 100).toStringAsFixed(1)}%',
      ],
      [
        'Processing Speed',
        _getProcessingSpeedCategory(data.averageProcessingTime),
      ],
    ]);
  }

  pw.Widget _buildBulkSummaryStats(List<ODRequest> requests) {
    final statusCounts = <String, int>{};

    for (final request in requests) {
      statusCounts[request.status] = (statusCounts[request.status] ?? 0) + 1;
    }

    return pw.Column(
      children: [
        _buildSummaryCards([
          SummaryCard(
            'Total Requests',
            requests.length.toString(),
            PdfColors.blue,
          ),
          SummaryCard(
            'Approved',
            (statusCounts['approved'] ?? 0).toString(),
            PdfColors.green,
          ),
          SummaryCard(
            'Rejected',
            (statusCounts['rejected'] ?? 0).toString(),
            PdfColors.red,
          ),
          SummaryCard(
            'Pending',
            (statusCounts['pending'] ?? 0).toString(),
            PdfColors.orange,
          ),
        ]),
      ],
    );
  }

  pw.Widget _buildEnhancedBulkRequestsTable(
    List<ODRequest> requests,
    ExportOptions? options,
  ) {
    // Determine columns based on options
    final includeTimestamps =
        options?.customData?['includeTimestamps'] as bool? ?? false;

    if (includeTimestamps) {
      return _buildDetailedBulkRequestsTable(requests);
    } else {
      return _buildBulkRequestsTable(requests);
    }
  }

  pw.Widget _buildDetailedBulkRequestsTable(List<ODRequest> requests) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(80),
        1: const pw.FixedColumnWidth(100),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FixedColumnWidth(60),
        5: const pw.FixedColumnWidth(80),
        6: const pw.FixedColumnWidth(80),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Student', isHeader: true),
            _buildTableCell('Register No.', isHeader: true),
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Reason', isHeader: true),
            _buildTableCell('Periods', isHeader: true),
            _buildTableCell('Status', isHeader: true),
            _buildTableCell('Created', isHeader: true),
          ],
        ),
        // Data rows
        ...requests.map(
          (request) => pw.TableRow(
            children: [
              _buildTableCell(request.studentName),
              _buildTableCell(request.registerNumber),
              _buildTableCell(request.date.toString().substring(0, 10)),
              _buildTableCell(request.reason),
              _buildTableCell(request.periods.join(', ')),
              _buildTableCell(request.status.toUpperCase()),
              _buildTableCell(request.createdAt.toString().substring(0, 10)),
            ],
          ),
        ),
      ],
    );
  }

  // Utility methods for analytics calculations

  String _getMostCommonPeriod(List<ODRequest> requests) {
    final periodCounts = <int, int>{};
    for (final request in requests) {
      for (final period in request.periods) {
        periodCounts[period] = (periodCounts[period] ?? 0) + 1;
      }
    }

    if (periodCounts.isEmpty) return 'N/A';

    final mostCommon = periodCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return 'Period ${mostCommon.key}';
  }

  double _calculateAvgProcessingTime(List<ODRequest> requests) {
    final processedRequests = requests
        .where((r) => r.approvedAt != null)
        .toList();
    if (processedRequests.isEmpty) return 0.0;

    final totalDays = processedRequests.fold(0.0, (sum, req) {
      final processingTime = req.approvedAt!.difference(req.createdAt).inDays;
      return sum + processingTime;
    });

    return totalDays / processedRequests.length;
  }

  String _calculateWorkloadLevel(StaffReportData data) {
    if (data.requestsProcessed < 10) return 'Light';
    if (data.requestsProcessed < 25) return 'Moderate';
    if (data.requestsProcessed < 50) return 'Heavy';
    return 'Very Heavy';
  }

  String _getProcessingSpeedCategory(double avgTime) {
    if (avgTime <= 1.0) return 'Very Fast';
    if (avgTime <= 2.0) return 'Fast';
    if (avgTime <= 4.0) return 'Average';
    if (avgTime <= 7.0) return 'Slow';
    return 'Very Slow';
  }
}

// Chart data model for PDF generation

class ChartSegment {
  final String label;
  final double value;
  final PdfColor color;

  const ChartSegment(this.label, this.value, this.color);
}

// Data models for PDF generation

class StudentReportData {
  final String studentId;
  final String studentName;
  final String registerNumber;
  final String department;
  final String yearSemester;
  final DateRange dateRange;
  final int totalRequests;
  final int approvedRequests;
  final int rejectedRequests;
  final int pendingRequests;
  final List<ODRequest> requests;
  final List<String> frequentReasons;

  const StudentReportData({
    required this.studentId,
    required this.studentName,
    required this.registerNumber,
    required this.department,
    required this.yearSemester,
    required this.dateRange,
    required this.totalRequests,
    required this.approvedRequests,
    required this.rejectedRequests,
    required this.pendingRequests,
    required this.requests,
    required this.frequentReasons,
  });
}

class StaffReportData {
  final String staffId;
  final String staffName;
  final String department;
  final String designation;
  final DateRange dateRange;
  final int requestsProcessed;
  final int requestsApproved;
  final int requestsRejected;
  final double averageProcessingTime;
  final List<String> commonRejectionReasons;

  const StaffReportData({
    required this.staffId,
    required this.staffName,
    required this.department,
    required this.designation,
    required this.dateRange,
    required this.requestsProcessed,
    required this.requestsApproved,
    required this.requestsRejected,
    required this.averageProcessingTime,
    required this.commonRejectionReasons,
  });
}

class AnalyticsReportData {
  final DateRange dateRange;
  final String generatedBy;
  final String? departmentFilter;
  final AnalyticsData analyticsData;

  const AnalyticsReportData({
    required this.dateRange,
    required this.generatedBy,
    this.departmentFilter,
    required this.analyticsData,
  });
}

class BulkRequestsReportData {
  final List<ODRequest> requests;
  final String exportedBy;
  final String? filterDescription;

  const BulkRequestsReportData({
    required this.requests,
    required this.exportedBy,
    this.filterDescription,
  });
}

class SummaryCard {
  final String title;
  final String value;
  final PdfColor color;

  const SummaryCard(this.title, this.value, this.color);
}
