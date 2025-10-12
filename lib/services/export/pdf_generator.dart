import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/analytics_models.dart';


/// PDF Generator service for creating professionally formatted PDF documents
class PDFGenerator {
  static const String _institutionName = 'ODTrack Academia';
  static const String _institutionAddress = 'Academic Institution Address';
  static const String _institutionPhone = '+91 XXXXX XXXXX';
  static const String _institutionEmail = 'info@odtrack-academia.edu';

  /// Generate student OD report PDF
  Future<Uint8List> generateStudentReport(StudentReportData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context, 'Student OD Report'),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildStudentReportContent(data),
      ),
    );

    return pdf.save();
  }

  /// Generate staff analytics report PDF
  Future<Uint8List> generateStaffReport(StaffReportData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context, 'Staff Analytics Report'),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildStaffReportContent(data),
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
        header: (context) => _buildHeader(context, 'Analytics Dashboard Report'),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildAnalyticsReportContent(data),
      ),
    );

    return pdf.save();
  }

  /// Generate bulk requests export PDF
  Future<Uint8List> generateBulkRequestsReport(BulkRequestsReportData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context, 'Bulk OD Requests Export'),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildBulkRequestsContent(data),
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

  // Student report content
  List<pw.Widget> _buildStudentReportContent(StudentReportData data) {
    return [
      // Student Information Section
      _buildSectionTitle('Student Information'),
      _buildInfoTable([
        ['Student ID', data.studentId],
        ['Student Name', data.studentName],
        ['Register Number', data.registerNumber],
        ['Department', data.department],
        ['Year/Semester', data.yearSemester],
        ['Report Period', '${data.dateRange.startDate.toString().substring(0, 10)} to ${data.dateRange.endDate.toString().substring(0, 10)}'],
      ]),
      
      pw.SizedBox(height: 20),
      
      // Summary Statistics
      _buildSectionTitle('OD Request Summary'),
      _buildSummaryCards([
        SummaryCard('Total Requests', data.totalRequests.toString(), PdfColors.blue),
        SummaryCard('Approved', data.approvedRequests.toString(), PdfColors.green),
        SummaryCard('Rejected', data.rejectedRequests.toString(), PdfColors.red),
        SummaryCard('Pending', data.pendingRequests.toString(), PdfColors.orange),
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
    ];
  }

  // Staff report content
  List<pw.Widget> _buildStaffReportContent(StaffReportData data) {
    return [
      // Staff Information Section
      _buildSectionTitle('Staff Information'),
      _buildInfoTable([
        ['Staff ID', data.staffId],
        ['Staff Name', data.staffName],
        ['Department', data.department],
        ['Designation', data.designation],
        ['Report Period', '${data.dateRange.startDate.toString().substring(0, 10)} to ${data.dateRange.endDate.toString().substring(0, 10)}'],
      ]),
      
      pw.SizedBox(height: 20),
      
      // Processing Statistics
      _buildSectionTitle('OD Processing Summary'),
      _buildSummaryCards([
        SummaryCard('Requests Processed', data.requestsProcessed.toString(), PdfColors.blue),
        SummaryCard('Approved', data.requestsApproved.toString(), PdfColors.green),
        SummaryCard('Rejected', data.requestsRejected.toString(), PdfColors.red),
        SummaryCard('Avg. Processing Time', '${data.averageProcessingTime.toStringAsFixed(1)} hrs', PdfColors.purple),
      ]),
      
      pw.SizedBox(height: 20),
      
      // Performance Metrics
      _buildSectionTitle('Performance Metrics'),
      _buildInfoTable([
        ['Approval Rate', '${((data.requestsApproved / data.requestsProcessed) * 100).toStringAsFixed(1)}%'],
        ['Response Time', '${data.averageProcessingTime.toStringAsFixed(1)} hours'],
        ['Efficiency Score', _calculateEfficiencyScore(data).toStringAsFixed(1)],
      ]),
      
      if (data.commonRejectionReasons.isNotEmpty) ...[
        pw.SizedBox(height: 20),
        _buildSectionTitle('Common Rejection Reasons'),
        _buildFrequentReasonsList(data.commonRejectionReasons),
      ],
    ];
  }

  // Analytics report content
  List<pw.Widget> _buildAnalyticsReportContent(AnalyticsReportData data) {
    return [
      // Report Information
      _buildSectionTitle('Analytics Overview'),
      _buildInfoTable([
        ['Report Period', '${data.dateRange.startDate.toString().substring(0, 10)} to ${data.dateRange.endDate.toString().substring(0, 10)}'],
        ['Generated By', data.generatedBy],
        ['Department Filter', data.departmentFilter ?? 'All Departments'],
      ]),
      
      pw.SizedBox(height: 20),
      
      // Overall Statistics
      _buildSectionTitle('Overall Statistics'),
      _buildSummaryCards([
        SummaryCard('Total Requests', data.analyticsData.totalRequests.toString(), PdfColors.blue),
        SummaryCard('Approved', data.analyticsData.approvedRequests.toString(), PdfColors.green),
        SummaryCard('Rejected', data.analyticsData.rejectedRequests.toString(), PdfColors.red),
        SummaryCard('Approval Rate', '${data.analyticsData.approvalRate.toStringAsFixed(1)}%', PdfColors.purple),
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

  // Bulk requests content
  List<pw.Widget> _buildBulkRequestsContent(BulkRequestsReportData data) {
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
      
      // Requests Table
      _buildSectionTitle('OD Requests'),
      _buildBulkRequestsTable(data.requests),
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
      children: data.map((row) => pw.TableRow(
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
      )).toList(),
    );
  }

  pw.Widget _buildSummaryCards(List<SummaryCard> cards) {
    return pw.Row(
      children: cards.map((card) => pw.Expanded(
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
      )).toList(),
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
        ...requests.map((request) => pw.TableRow(
          children: [
            _buildTableCell(request.date.toString().substring(0, 10)),
            _buildTableCell(request.periods.join(', ')),
            _buildTableCell(request.reason),
            _buildTableCell(request.status.toUpperCase()),
            _buildTableCell(request.approvedBy ?? '-'),
          ],
        )),
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
        ...requests.map((request) => pw.TableRow(
          children: [
            _buildTableCell(request.studentName),
            _buildTableCell(request.registerNumber),
            _buildTableCell(request.date.toString().substring(0, 10)),
            _buildTableCell(request.reason),
            _buildTableCell(request.status.toUpperCase()),
          ],
        )),
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
        ...departmentData.entries.map((entry) => pw.TableRow(
          children: [
            _buildTableCell(entry.key),
            _buildTableCell(entry.value.toString()),
          ],
        )),
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
        ...monthlyData.entries.map((entry) => pw.TableRow(
          children: [
            _buildTableCell(entry.key),
            _buildTableCell(entry.value.toString()),
          ],
        )),
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
        ...reasons.map((reason) => pw.TableRow(
          children: [
            _buildTableCell(reason.reason),
            _buildTableCell(reason.count.toString()),
            _buildTableCell('${reason.percentage.toStringAsFixed(1)}%'),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildFrequentReasonsList(List<String> reasons) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: reasons.map((reason) => pw.Container(
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
      )).toList(),
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
    final timeEfficiency = 1 / (data.averageProcessingTime + 1); // Inverse of processing time
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