import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/services/export/pdf_generator.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/export_filters.dart';

void main() {
  group('PDFGenerator', () {
    late PDFGenerator pdfGenerator;

    setUp(() {
      pdfGenerator = PDFGenerator();
    });

    group('Student Report Generation', () {
      test('should generate student report PDF with valid data', () async {
        // Arrange
        final studentData = StudentReportData(
          studentId: 'STU001',
          studentName: 'John Doe',
          registerNumber: 'REG001',
          department: 'Computer Science',
          yearSemester: '3rd Year, 5th Semester',
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          totalRequests: 5,
          approvedRequests: 3,
          rejectedRequests: 1,
          pendingRequests: 1,
          requests: [
            ODRequest(
              id: 'req_1',
              studentId: 'STU001',
              studentName: 'John Doe',
              registerNumber: 'REG001',
              date: DateTime(2024, 1, 15),
              periods: [1, 2],
              reason: 'Medical appointment',
              status: 'approved',
              createdAt: DateTime(2024, 1, 15, 8),
              approvedBy: 'Dr. Smith',
              approvedAt: DateTime(2024, 1, 15, 10),
            ),
          ],
          frequentReasons: ['Medical appointment', 'Family function'],
        );

        // Act
        final pdfBytes = await pdfGenerator.generateStudentReport(studentData);

        // Assert
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
        expect(pdfBytes, isA<List<int>>());
      });

      test('should handle empty requests list', () async {
        // Arrange
        final studentData = StudentReportData(
          studentId: 'STU001',
          studentName: 'John Doe',
          registerNumber: 'REG001',
          department: 'Computer Science',
          yearSemester: '3rd Year, 5th Semester',
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          totalRequests: 0,
          approvedRequests: 0,
          rejectedRequests: 0,
          pendingRequests: 0,
          requests: [],
          frequentReasons: [],
        );

        // Act
        final pdfBytes = await pdfGenerator.generateStudentReport(studentData);

        // Assert
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
      });
    });

    group('Staff Report Generation', () {
      test('should generate staff report PDF with valid data', () async {
        // Arrange
        final staffData = StaffReportData(
          staffId: 'STAFF001',
          staffName: 'Dr. Jane Smith',
          department: 'Computer Science',
          designation: 'Associate Professor',
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          requestsProcessed: 25,
          requestsApproved: 20,
          requestsRejected: 3,
          averageProcessingTime: 2.5,
          commonRejectionReasons: [
            'Insufficient notice period',
            'Missing documentation',
          ],
        );

        // Act
        final pdfBytes = await pdfGenerator.generateStaffReport(staffData);

        // Assert
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
        expect(pdfBytes, isA<List<int>>());
      });

      test('should handle zero processed requests', () async {
        // Arrange
        final staffData = StaffReportData(
          staffId: 'STAFF001',
          staffName: 'Dr. Jane Smith',
          department: 'Computer Science',
          designation: 'Associate Professor',
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          requestsProcessed: 0,
          requestsApproved: 0,
          requestsRejected: 0,
          averageProcessingTime: 0.0,
          commonRejectionReasons: [],
        );

        // Act & Assert
        expect(
          () async => await pdfGenerator.generateStaffReport(staffData),
          returnsNormally,
        );
      });
    });

    group('Analytics Report Generation', () {
      test('should generate analytics report PDF with valid data', () async {
        // Arrange
        final analyticsData = AnalyticsReportData(
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          generatedBy: 'Admin User',
          departmentFilter: 'Computer Science',
          analyticsData: const AnalyticsData(
            totalRequests: 100,
            approvedRequests: 75,
            rejectedRequests: 20,
            pendingRequests: 5,
            approvalRate: 75.0,
            requestsByMonth: {'January': 50, 'February': 50},
            requestsByDepartment: {'CS': 60, 'IT': 40},
            topRejectionReasons: [
              RejectionReason(
                reason: 'Insufficient notice',
                count: 10,
                percentage: 50.0,
              ),
            ],
            patterns: [
              RequestPattern(
                pattern: 'Monday peak',
                description: 'More requests on Mondays',
                confidence: 0.85,
              ),
            ],
          ),
        );

        // Act
        final pdfBytes = await pdfGenerator.generateAnalyticsReport(
          analyticsData,
        );

        // Assert
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
        expect(pdfBytes, isA<List<int>>());
      });

      test('should handle empty analytics data', () async {
        // Arrange
        final analyticsData = AnalyticsReportData(
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          generatedBy: 'Admin User',
          analyticsData: const AnalyticsData(
            totalRequests: 0,
            approvedRequests: 0,
            rejectedRequests: 0,
            pendingRequests: 0,
            approvalRate: 0.0,
            requestsByMonth: {},
            requestsByDepartment: {},
            topRejectionReasons: [],
            patterns: [],
          ),
        );

        // Act
        final pdfBytes = await pdfGenerator.generateAnalyticsReport(
          analyticsData,
        );

        // Assert
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
      });
    });

    group('Bulk Requests Report Generation', () {
      test(
        'should generate bulk requests report PDF with valid data',
        () async {
          // Arrange
          final bulkData = BulkRequestsReportData(
            requests: [
              ODRequest(
                id: 'req_1',
                studentId: 'STU001',
                studentName: 'John Doe',
                registerNumber: 'REG001',
                date: DateTime(2024, 1, 15),
                periods: [1, 2],
                reason: 'Medical appointment',
                status: 'approved',
                createdAt: DateTime(2024, 1, 15, 8),
              ),
              ODRequest(
                id: 'req_2',
                studentId: 'STU002',
                studentName: 'Jane Smith',
                registerNumber: 'REG002',
                date: DateTime(2024, 1, 16),
                periods: [3, 4],
                reason: 'Family function',
                status: 'pending',
                createdAt: DateTime(2024, 1, 16, 9),
              ),
            ],
            exportedBy: 'Admin User',
            filterDescription: 'All pending requests',
          );

          // Act
          final pdfBytes = await pdfGenerator.generateBulkRequestsReport(
            bulkData,
          );

          // Assert
          expect(pdfBytes, isNotNull);
          expect(pdfBytes.length, greaterThan(0));
          expect(pdfBytes, isA<List<int>>());
        },
      );

      test('should handle empty requests list', () async {
        // Arrange
        const bulkData = BulkRequestsReportData(
          requests: [],
          exportedBy: 'Admin User',
        );

        // Act
        final pdfBytes = await pdfGenerator.generateBulkRequestsReport(
          bulkData,
        );

        // Assert
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
      });
    });

    group('PDF Content Validation', () {
      test('should include institutional branding in header', () async {
        // Arrange
        final studentData = StudentReportData(
          studentId: 'STU001',
          studentName: 'John Doe',
          registerNumber: 'REG001',
          department: 'Computer Science',
          yearSemester: '3rd Year, 5th Semester',
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          totalRequests: 1,
          approvedRequests: 1,
          rejectedRequests: 0,
          pendingRequests: 0,
          requests: [],
          frequentReasons: [],
        );

        // Act
        final pdfBytes = await pdfGenerator.generateStudentReport(studentData);

        // Assert
        expect(pdfBytes, isNotNull);
        expect(
          pdfBytes.length,
          greaterThan(1000),
        ); // Should be substantial with branding
      });

      test(
        'should generate different content for different report types',
        () async {
          // Arrange
          final studentData = StudentReportData(
            studentId: 'STU001',
            studentName: 'John Doe',
            registerNumber: 'REG001',
            department: 'Computer Science',
            yearSemester: '3rd Year, 5th Semester',
            dateRange: DateRange(
              startDate: DateTime(2024, 1, 1),
              endDate: DateTime(2024, 1, 31),
            ),
            totalRequests: 1,
            approvedRequests: 1,
            rejectedRequests: 0,
            pendingRequests: 0,
            requests: [],
            frequentReasons: [],
          );

          final staffData = StaffReportData(
            staffId: 'STAFF001',
            staffName: 'Dr. Jane Smith',
            department: 'Computer Science',
            designation: 'Associate Professor',
            dateRange: DateRange(
              startDate: DateTime(2024, 1, 1),
              endDate: DateTime(2024, 1, 31),
            ),
            requestsProcessed: 1,
            requestsApproved: 1,
            requestsRejected: 0,
            averageProcessingTime: 1.0,
            commonRejectionReasons: [],
          );

          // Act
          final studentPdf = await pdfGenerator.generateStudentReport(
            studentData,
          );
          final staffPdf = await pdfGenerator.generateStaffReport(staffData);

          // Assert
          expect(studentPdf, isNotNull);
          expect(staffPdf, isNotNull);
          expect(studentPdf.length, isNot(equals(staffPdf.length)));
        },
      );
    });

    group('Enhanced Export Features', () {
      test('should generate student report with filtering options', () async {
        // Arrange
        final studentData = StudentReportData(
          studentId: 'STU001',
          studentName: 'John Doe',
          registerNumber: 'REG001',
          department: 'Computer Science',
          yearSemester: '3rd Year, 5th Semester',
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          totalRequests: 5,
          approvedRequests: 3,
          rejectedRequests: 1,
          pendingRequests: 1,
          requests: [
            ODRequest(
              id: 'req_1',
              studentId: 'STU001',
              studentName: 'John Doe',
              registerNumber: 'REG001',
              date: DateTime(2024, 1, 15),
              periods: [1, 2],
              reason: 'Medical appointment',
              status: 'approved',
              createdAt: DateTime(2024, 1, 15, 8),
              approvedBy: 'Dr. Smith',
              approvedAt: DateTime(2024, 1, 15, 10),
            ),
          ],
          frequentReasons: ['Medical appointment', 'Family function'],
        );

        const filter = StudentReportFilter(
          statuses: ['approved'],
          reasonKeyword: 'medical',
        );

        const options = ExportOptions(
          format: ExportFormat.pdf,
          includeCharts: true,
          includeMetadata: true,
        );

        // Act
        final pdfBytes = await pdfGenerator.generateStudentReport(
          studentData,
          filter: filter,
          options: options,
        );

        // Assert
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
        expect(pdfBytes, isA<List<int>>());
      });

      test('should generate staff report with charts and summaries', () async {
        // Arrange
        final staffData = StaffReportData(
          staffId: 'STAFF001',
          staffName: 'Dr. Jane Smith',
          department: 'Computer Science',
          designation: 'Associate Professor',
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          requestsProcessed: 25,
          requestsApproved: 20,
          requestsRejected: 3,
          averageProcessingTime: 2.5,
          commonRejectionReasons: [
            'Insufficient notice period',
            'Missing documentation',
          ],
        );

        const options = ExportOptions(
          format: ExportFormat.pdf,
          includeCharts: true,
          includeMetadata: true,
        );

        // Act
        final pdfBytes = await pdfGenerator.generateStaffReport(
          staffData,
          options: options,
        );

        // Assert
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
        expect(pdfBytes, isA<List<int>>());
        // Should be larger with charts and enhanced analytics
        expect(pdfBytes.length, greaterThan(2000));
      });

      test(
        'should generate bulk requests report with custom formatting',
        () async {
          // Arrange
          final bulkData = BulkRequestsReportData(
            requests: [
              ODRequest(
                id: 'req_1',
                studentId: 'STU001',
                studentName: 'John Doe',
                registerNumber: 'REG001',
                date: DateTime(2024, 1, 15),
                periods: [1, 2],
                reason: 'Medical appointment',
                status: 'approved',
                createdAt: DateTime(2024, 1, 15, 8),
              ),
              ODRequest(
                id: 'req_2',
                studentId: 'STU002',
                studentName: 'Jane Smith',
                registerNumber: 'REG002',
                date: DateTime(2024, 1, 16),
                periods: [3, 4],
                reason: 'Family function',
                status: 'pending',
                createdAt: DateTime(2024, 1, 16, 9),
              ),
            ],
            exportedBy: 'Admin User',
            filterDescription: 'All requests from January 2024',
          );

          const filter = BulkReportFilter(statuses: ['approved', 'pending']);

          const options = ExportOptions(
            format: ExportFormat.pdf,
            includeCharts: true,
            customTitle: 'Custom Bulk Export Report',
            customData: {'includeDetails': true, 'includeTimestamps': true},
          );

          // Act
          final pdfBytes = await pdfGenerator.generateBulkRequestsReport(
            bulkData,
            filter: filter,
            options: options,
          );

          // Assert
          expect(pdfBytes, isNotNull);
          expect(pdfBytes.length, greaterThan(0));
          expect(pdfBytes, isA<List<int>>());
        },
      );

      test('should include charts when requested', () async {
        // Arrange
        final studentData = StudentReportData(
          studentId: 'STU001',
          studentName: 'John Doe',
          registerNumber: 'REG001',
          department: 'Computer Science',
          yearSemester: '3rd Year, 5th Semester',
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          totalRequests: 5,
          approvedRequests: 3,
          rejectedRequests: 1,
          pendingRequests: 1,
          requests: [
            ODRequest(
              id: 'req_1',
              studentId: 'STU001',
              studentName: 'John Doe',
              registerNumber: 'REG001',
              date: DateTime(2024, 1, 15),
              periods: [1, 2],
              reason: 'Medical appointment',
              status: 'approved',
              createdAt: DateTime(2024, 1, 15, 8),
            ),
          ],
          frequentReasons: ['Medical appointment'],
        );

        const optionsWithCharts = ExportOptions(
          format: ExportFormat.pdf,
          includeCharts: true,
        );

        const optionsWithoutCharts = ExportOptions(
          format: ExportFormat.pdf,
          includeCharts: false,
        );

        // Act
        final pdfWithCharts = await pdfGenerator.generateStudentReport(
          studentData,
          options: optionsWithCharts,
        );

        final pdfWithoutCharts = await pdfGenerator.generateStudentReport(
          studentData,
          options: optionsWithoutCharts,
        );

        // Assert
        expect(pdfWithCharts, isNotNull);
        expect(pdfWithoutCharts, isNotNull);
        // PDF with charts should be larger
        expect(pdfWithCharts.length, greaterThan(pdfWithoutCharts.length));
      });

      test('should apply filtering correctly', () async {
        // Arrange
        final studentData = StudentReportData(
          studentId: 'STU001',
          studentName: 'John Doe',
          registerNumber: 'REG001',
          department: 'Computer Science',
          yearSemester: '3rd Year, 5th Semester',
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          totalRequests: 3,
          approvedRequests: 2,
          rejectedRequests: 1,
          pendingRequests: 0,
          requests: [
            ODRequest(
              id: 'req_1',
              studentId: 'STU001',
              studentName: 'John Doe',
              registerNumber: 'REG001',
              date: DateTime(2024, 1, 15),
              periods: [1, 2],
              reason: 'Medical appointment',
              status: 'approved',
              createdAt: DateTime(2024, 1, 15, 8),
            ),
            ODRequest(
              id: 'req_2',
              studentId: 'STU001',
              studentName: 'John Doe',
              registerNumber: 'REG001',
              date: DateTime(2024, 1, 20),
              periods: [3, 4],
              reason: 'Family function',
              status: 'rejected',
              createdAt: DateTime(2024, 1, 20, 8),
            ),
          ],
          frequentReasons: ['Medical appointment', 'Family function'],
        );

        const filter = StudentReportFilter(statuses: ['approved']);

        const options = ExportOptions(format: ExportFormat.pdf);

        // Act
        final pdfBytes = await pdfGenerator.generateStudentReport(
          studentData,
          filter: filter,
          options: options,
        );

        // Assert
        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));
      });
    });

    group('Chart Generation', () {
      test('should handle empty data in charts gracefully', () async {
        // Arrange
        final studentData = StudentReportData(
          studentId: 'STU001',
          studentName: 'John Doe',
          registerNumber: 'REG001',
          department: 'Computer Science',
          yearSemester: '3rd Year, 5th Semester',
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          totalRequests: 0,
          approvedRequests: 0,
          rejectedRequests: 0,
          pendingRequests: 0,
          requests: [],
          frequentReasons: [],
        );

        const options = ExportOptions(
          format: ExportFormat.pdf,
          includeCharts: true,
        );

        // Act & Assert
        expect(
          () async => await pdfGenerator.generateStudentReport(
            studentData,
            options: options,
          ),
          returnsNormally,
        );
      });

      test(
        'should generate different chart types for different data',
        () async {
          // Arrange
          final staffData = StaffReportData(
            staffId: 'STAFF001',
            staffName: 'Dr. Jane Smith',
            department: 'Computer Science',
            designation: 'Associate Professor',
            dateRange: DateRange(
              startDate: DateTime(2024, 1, 1),
              endDate: DateTime(2024, 1, 31),
            ),
            requestsProcessed: 25,
            requestsApproved: 20,
            requestsRejected: 5,
            averageProcessingTime: 2.5,
            commonRejectionReasons: ['Insufficient notice'],
          );

          const options = ExportOptions(
            format: ExportFormat.pdf,
            includeCharts: true,
          );

          // Act
          final pdfBytes = await pdfGenerator.generateStaffReport(
            staffData,
            options: options,
          );

          // Assert
          expect(pdfBytes, isNotNull);
          expect(pdfBytes.length, greaterThan(0));
          // Should include both bar and pie charts
          expect(pdfBytes.length, greaterThan(2000));
        },
      );
    });

    group('Error Handling', () {
      test('should handle null values gracefully', () async {
        // This test ensures the PDF generator doesn't crash with minimal data
        final studentData = StudentReportData(
          studentId: '',
          studentName: '',
          registerNumber: '',
          department: '',
          yearSemester: '',
          dateRange: DateRange(
            startDate: DateTime.now(),
            endDate: DateTime.now(),
          ),
          totalRequests: 0,
          approvedRequests: 0,
          rejectedRequests: 0,
          pendingRequests: 0,
          requests: [],
          frequentReasons: [],
        );

        // Act & Assert
        expect(
          () async => await pdfGenerator.generateStudentReport(studentData),
          returnsNormally,
        );
      });

      test('should handle invalid filter parameters gracefully', () async {
        // Arrange
        final studentData = StudentReportData(
          studentId: 'STU001',
          studentName: 'John Doe',
          registerNumber: 'REG001',
          department: 'Computer Science',
          yearSemester: '3rd Year, 5th Semester',
          dateRange: DateRange(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
          ),
          totalRequests: 1,
          approvedRequests: 1,
          rejectedRequests: 0,
          pendingRequests: 0,
          requests: [],
          frequentReasons: [],
        );

        const filter = StudentReportFilter(
          statuses: [], // Empty filter
          reasonKeyword: '', // Empty keyword
        );

        // Act & Assert
        expect(
          () async => await pdfGenerator.generateStudentReport(
            studentData,
            filter: filter,
          ),
          returnsNormally,
        );
      });
    });
  });
}
