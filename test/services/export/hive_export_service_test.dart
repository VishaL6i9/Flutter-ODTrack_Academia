import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:odtrack_academia/services/export/hive_export_service.dart';

import 'package:odtrack_academia/core/storage/enhanced_storage_manager.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/analytics_models.dart';

// Generate mocks
@GenerateMocks([EnhancedStorageManager])
import 'hive_export_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider methods
  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (
        MethodCall methodCall,
      ) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '/mock/documents/directory';
        }
        return null;
      });

  // Mock share_plus methods
  const MethodChannel shareChannel = MethodChannel(
    'dev.fluttercommunity.plus/share',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(shareChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'shareXFiles') {
          return 'success';
        }
        return null;
      });
  group('HiveExportService', () {
    late HiveExportService exportService;
    late MockEnhancedStorageManager mockStorageManager;

    setUp(() {
      mockStorageManager = MockEnhancedStorageManager();
      exportService = HiveExportService(mockStorageManager);

      // Setup default mock behavior
      when(mockStorageManager.initialize()).thenAnswer((_) async {});
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        // Act
        await exportService.initialize();

        // Assert
        verify(mockStorageManager.initialize()).called(1);
      });

      test('should provide export progress stream', () {
        // Act
        final stream = exportService.exportProgressStream;

        // Assert
        expect(stream, isNotNull);
        expect(stream, isA<Stream<ExportProgress>>());
      });
    });

    group('Student Report Export', () {
      test('should export student report successfully', () async {
        // Arrange
        await exportService.initialize();
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        const options = ExportOptions(
          format: ExportFormat.pdf,
          includeCharts: true,
          includeMetadata: true,
        );

        // Act
        final result = await exportService.exportStudentReport(
          'STU001',
          dateRange,
          options,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.success, isTrue);
        expect(result.format, equals(ExportFormat.pdf));
        expect(result.fileName, contains('student_report'));
        expect(result.filePath, isNotEmpty);
        expect(result.fileSize, greaterThan(0));
      });

      test('should handle export errors gracefully', () async {
        // Arrange
        await exportService.initialize();
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        const options = ExportOptions(format: ExportFormat.pdf);

        // Mock storage manager to throw an error
        when(
          mockStorageManager.initialize(),
        ).thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => exportService.exportStudentReport('STU001', dateRange, options),
          throwsException,
        );
      });

      test('should track export progress', () async {
        // Arrange
        await exportService.initialize();
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        const options = ExportOptions(format: ExportFormat.pdf);

        final progressEvents = <ExportProgress>[];
        exportService.exportProgressStream.listen(progressEvents.add);

        // Act
        await exportService.exportStudentReport('STU001', dateRange, options);

        // Wait for stream events
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(progressEvents, isNotEmpty);
        expect(progressEvents.any((p) => p.progress == 1.0), isTrue);
        expect(
          progressEvents.any((p) => p.currentStep.contains('completed')),
          isTrue,
        );
      });
    });

    group('Staff Report Export', () {
      test('should export staff report successfully', () async {
        // Arrange
        await exportService.initialize();
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        const options = ExportOptions(
          format: ExportFormat.pdf,
          includeMetadata: true,
        );

        // Act
        final result = await exportService.exportStaffReport(
          'STAFF001',
          dateRange,
          options,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.success, isTrue);
        expect(result.format, equals(ExportFormat.pdf));
        expect(result.fileName, contains('staff_report'));
        expect(result.filePath, isNotEmpty);
        expect(result.fileSize, greaterThan(0));
      });

      test('should include staff-specific data in report', () async {
        // Arrange
        await exportService.initialize();
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        const options = ExportOptions(format: ExportFormat.pdf);

        // Act
        final result = await exportService.exportStaffReport(
          'STAFF001',
          dateRange,
          options,
        );

        // Assert
        expect(result.success, isTrue);
        expect(
          result.fileSize,
          greaterThan(1000),
        ); // Should contain substantial content
      });
    });

    group('Analytics Report Export', () {
      test('should export analytics report successfully', () async {
        // Arrange
        await exportService.initialize();
        const analyticsData = AnalyticsData(
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
        );
        const options = ExportOptions(
          format: ExportFormat.pdf,
          includeCharts: true,
        );

        // Act
        final result = await exportService.exportAnalyticsReport(
          analyticsData,
          options,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.success, isTrue);
        expect(result.format, equals(ExportFormat.pdf));
        expect(result.fileName, contains('analytics_report'));
        expect(result.filePath, isNotEmpty);
        expect(result.fileSize, greaterThan(0));
      });

      test('should handle empty analytics data', () async {
        // Arrange
        await exportService.initialize();
        const analyticsData = AnalyticsData(
          totalRequests: 0,
          approvedRequests: 0,
          rejectedRequests: 0,
          pendingRequests: 0,
          approvalRate: 0.0,
          requestsByMonth: {},
          requestsByDepartment: {},
          topRejectionReasons: [],
          patterns: [],
        );
        const options = ExportOptions(format: ExportFormat.pdf);

        // Act
        final result = await exportService.exportAnalyticsReport(
          analyticsData,
          options,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.fileSize, greaterThan(0));
      });
    });

    group('Bulk Requests Export', () {
      test('should export bulk requests successfully', () async {
        // Arrange
        await exportService.initialize();
        final requests = [
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
        ];
        const options = ExportOptions(
          format: ExportFormat.pdf,
          customTitle: 'Bulk Export Test',
        );

        // Act
        final result = await exportService.exportBulkRequests(
          requests,
          options,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.success, isTrue);
        expect(result.format, equals(ExportFormat.pdf));
        expect(result.fileName, contains('bulk'));
        expect(result.filePath, isNotEmpty);
        expect(result.fileSize, greaterThan(0));
      });

      test('should handle empty requests list', () async {
        // Arrange
        await exportService.initialize();
        const options = ExportOptions(format: ExportFormat.pdf);

        // Act
        final result = await exportService.exportBulkRequests([], options);

        // Assert
        expect(result.success, isTrue);
        expect(result.fileSize, greaterThan(0));
      });
    });

    group('CSV Export', () {
      test('should export CSV format successfully', () async {
        // Arrange
        await exportService.initialize();
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        const options = ExportOptions(
          format: ExportFormat.csv,
          includeMetadata: true,
        );

        // Act
        final result = await exportService.exportStudentReport(
          'STU001',
          dateRange,
          options,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.success, isTrue);
        expect(result.format, equals(ExportFormat.csv));
        expect(result.fileName, endsWith('.csv'));
        expect(result.fileSize, greaterThan(0));
      });
    });

    group('Export History Management', () {
      test('should maintain export history', () async {
        // Arrange
        await exportService.initialize();
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        const options = ExportOptions(format: ExportFormat.pdf);

        // Act
        await exportService.exportStudentReport('STU001', dateRange, options);
        final history = await exportService.getExportHistory();

        // Assert
        expect(history, isNotEmpty);
        expect(history.first.success, isTrue);
      });

      test('should include failed exports in history', () async {
        // Arrange
        await exportService.initialize();
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        const options = ExportOptions(
          format: ExportFormat.excel,
        ); // Unsupported format

        // Act & Assert
        expect(
          () => exportService.exportStudentReport('STU001', dateRange, options),
          throwsA(isA<UnimplementedError>()),
        );

        final history = await exportService.getExportHistory();
        expect(history, isNotEmpty);
        expect(history.first.success, isFalse);
        expect(history.first.errorMessage, isNotNull);
      });
    });

    group('File Operations', () {
      test('should share exported file', () async {
        // Arrange
        await exportService.initialize();
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        const options = ExportOptions(format: ExportFormat.pdf);

        final result = await exportService.exportStudentReport(
          'STU001',
          dateRange,
          options,
        );

        // Act & Assert
        // Note: In a real test environment, we would mock the Share.shareXFiles method
        // For now, we just verify the method doesn't throw
        expect(
          () => exportService.shareExportedFile(result.filePath),
          returnsNormally,
        );
      });

      test('should handle file not found error when sharing', () async {
        // Act & Assert
        expect(
          () => exportService.shareExportedFile('/non/existent/file.pdf'),
          throwsException,
        );
      });

      test('should delete exported file', () async {
        // Arrange
        await exportService.initialize();
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );
        const options = ExportOptions(format: ExportFormat.pdf);

        final result = await exportService.exportStudentReport(
          'STU001',
          dateRange,
          options,
        );

        // Act
        await exportService.deleteExportedFile(result.filePath);

        // Assert
        final history = await exportService.getExportHistory();
        expect(history.any((h) => h.filePath == result.filePath), isFalse);
      });
    });

    group('Export Cancellation', () {
      test('should cancel export operation', () async {
        // Arrange
        await exportService.initialize();
        const exportId = 'test_export_123';

        // Act & Assert
        expect(() => exportService.cancelExport(exportId), returnsNormally);
      });
    });

    group('Custom Export Options', () {
      test('should respect custom title in export options', () async {
        // Arrange
        await exportService.initialize();
        const analyticsData = AnalyticsData(
          totalRequests: 10,
          approvedRequests: 8,
          rejectedRequests: 2,
          pendingRequests: 0,
          approvalRate: 80.0,
          requestsByMonth: {},
          requestsByDepartment: {},
          topRejectionReasons: [],
          patterns: [],
        );
        const options = ExportOptions(
          format: ExportFormat.pdf,
          customTitle: 'Custom Analytics Report Title',
        );

        // Act
        final result = await exportService.exportAnalyticsReport(
          analyticsData,
          options,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.fileName, contains('custom_analytics_report_title'));
      });

      test('should handle metadata inclusion option', () async {
        // Arrange
        await exportService.initialize();
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        const optionsWithMetadata = ExportOptions(
          format: ExportFormat.csv,
          includeMetadata: true,
        );

        const optionsWithoutMetadata = ExportOptions(
          format: ExportFormat.csv,
          includeMetadata: false,
        );

        // Act
        final resultWithMetadata = await exportService.exportStudentReport(
          'STU001',
          dateRange,
          optionsWithMetadata,
        );

        final resultWithoutMetadata = await exportService.exportStudentReport(
          'STU001',
          dateRange,
          optionsWithoutMetadata,
        );

        // Assert
        expect(resultWithMetadata.success, isTrue);
        expect(resultWithoutMetadata.success, isTrue);
        // File with metadata should be larger
        expect(
          resultWithMetadata.fileSize,
          greaterThan(resultWithoutMetadata.fileSize),
        );
      });
    });
  });
}
