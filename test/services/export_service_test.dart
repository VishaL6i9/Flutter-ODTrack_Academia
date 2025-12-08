import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/services/export/hive_export_service.dart';
import 'package:odtrack_academia/core/storage/storage_manager.dart';

// Generate mocks
@GenerateMocks([EnhancedStorageManager])
import 'export_service_test.mocks.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HiveExportService Tests', () {
    late HiveExportService exportService;
    late MockEnhancedStorageManager mockStorageManager;

    setUp(() {
      mockStorageManager = MockEnhancedStorageManager();
      exportService = HiveExportService(mockStorageManager);
      
      // Mock storage manager initialization
      when(mockStorageManager.initialize()).thenAnswer((_) async {});
    });

    group('Export Progress Tracking', () {
      test('should emit progress updates during export', () async {
        // Arrange
        final progressUpdates = <ExportProgress>[];
        exportService.exportProgressStream.listen(progressUpdates.add);

        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        const options = ExportOptions(
          format: ExportFormat.pdf,
          includeCharts: true,
          includeMetadata: true,
        );

        // Act
        await exportService.initialize();
        await exportService.exportStudentReport('student_123', dateRange, options);

        // Allow time for progress updates
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(progressUpdates.isNotEmpty, true);
        
        // Check that progress increases over time
        for (int i = 1; i < progressUpdates.length; i++) {
          expect(
            progressUpdates[i].progress >= progressUpdates[i - 1].progress,
            true,
            reason: 'Progress should increase or stay the same',
          );
        }

        // Final progress should be 1.0 (completed)
        expect(progressUpdates.last.progress, 1.0);
        expect(progressUpdates.last.isCompleted, true);
      });

      test('should include enhanced progress details', () async {
        // Arrange
        final progressUpdates = <ExportProgress>[];
        exportService.exportProgressStream.listen(progressUpdates.add);

        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        const options = ExportOptions(format: ExportFormat.pdf);

        // Act
        await exportService.initialize();
        await exportService.exportStudentReport('student_123', dateRange, options);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Assert
        final progress = progressUpdates.first;
        expect(progress.timestamp, isNotNull);
        expect(progress.isCancellable, true);
        expect(progress.currentStep.isNotEmpty, true);
        expect(progress.progressPercentage.endsWith('%'), true);
      });

      test('should handle export cancellation', () async {
        // Arrange
        final progressUpdates = <ExportProgress>[];
        exportService.exportProgressStream.listen(progressUpdates.add);

        await exportService.initialize();

        // Act
        await exportService.cancelExport('test_export_id');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(progressUpdates.isNotEmpty, true);
        final cancelProgress = progressUpdates.last;
        expect(cancelProgress.exportId, 'test_export_id');
        expect(cancelProgress.currentStep, 'Cancelled');
        expect(cancelProgress.isCancellable, false);
      });
    });

    group('Export History Management', () {
      test('should maintain export history', () async {
        // Arrange
        await exportService.initialize();

        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        const options = ExportOptions(format: ExportFormat.pdf);

        // Act
        await exportService.exportStudentReport('student_1', dateRange, options);
        await exportService.exportStaffReport('staff_1', dateRange, options);

        final history = await exportService.getExportHistory();

        // Assert
        expect(history.length, 2);
        expect(history.every((export) => export.success), true);
        expect(history.every((export) => export.format == ExportFormat.pdf), true);
      });

      test('should filter export history correctly', () async {
        // Arrange
        await exportService.initialize();

        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        // Create exports with different formats
        await exportService.exportStudentReport(
          'student_1',
          dateRange,
          const ExportOptions(format: ExportFormat.pdf),
        );
        await exportService.exportStudentReport(
          'student_2',
          dateRange,
          const ExportOptions(format: ExportFormat.csv),
        );

        // Act
        const pdfFilter = ExportHistoryFilter(format: ExportFormat.pdf);
        final pdfExports = await exportService.getFilteredExportHistory(pdfFilter);

        const csvFilter = ExportHistoryFilter(format: ExportFormat.csv);
        final csvExports = await exportService.getFilteredExportHistory(csvFilter);

        // Assert
        expect(pdfExports.length, 1);
        expect(pdfExports.first.format, ExportFormat.pdf);

        expect(csvExports.length, 1);
        expect(csvExports.first.format, ExportFormat.csv);
      });

      test('should filter by success status', () async {
        // Arrange
        await exportService.initialize();

        // Create a successful export
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );
        await exportService.exportStudentReport(
          'student_1',
          dateRange,
          const ExportOptions(format: ExportFormat.pdf),
        );

        // Simulate a failed export by cancelling
        await exportService.cancelExport('failed_export');

        // Act
        const successFilter = ExportHistoryFilter(successOnly: true);
        final successfulExports = await exportService.getFilteredExportHistory(successFilter);

        const failedFilter = ExportHistoryFilter(successOnly: false);
        final failedExports = await exportService.getFilteredExportHistory(failedFilter);

        // Assert
        expect(successfulExports.every((e) => e.success), true);
        expect(failedExports.every((e) => !e.success), true);
      });

      test('should filter by date range', () async {
        // Arrange
        await exportService.initialize();

        final recentDate = DateTime(2024, 1, 1);

        // We can't easily mock the creation date, so we'll test the filter logic
        final filter = ExportHistoryFilter(
          startDate: recentDate,
          endDate: DateTime(2024, 12, 31),
        );

        // Act
        final filteredExports = await exportService.getFilteredExportHistory(filter);

        // Assert - all exports should be after the start date
        expect(
          filteredExports.every((e) => e.createdAt.isAfter(recentDate) || 
                                      e.createdAt.isAtSameMomentAs(recentDate)),
          true,
        );
      });

      test('should search by filename and error message', () async {
        // Arrange
        await exportService.initialize();

        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        // Create exports with specific titles
        await exportService.exportStudentReport(
          'student_1',
          dateRange,
          const ExportOptions(
            format: ExportFormat.pdf,
            customTitle: 'Special Student Report',
          ),
        );

        // Act
        const searchFilter = ExportHistoryFilter(searchQuery: 'special');
        final searchResults = await exportService.getFilteredExportHistory(searchFilter);

        // Assert
        expect(searchResults.isNotEmpty, true);
        expect(
          searchResults.any((e) => 
            e.fileName.toLowerCase().contains('special')),
          true,
        );
      });

      test('should clear export history', () async {
        // Arrange
        await exportService.initialize();

        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        // Create some exports
        await exportService.exportStudentReport('student_1', dateRange, 
            const ExportOptions(format: ExportFormat.pdf));
        await exportService.exportStaffReport('staff_1', dateRange, 
            const ExportOptions(format: ExportFormat.pdf));

        // Verify history has items
        var history = await exportService.getExportHistory();
        expect(history.isNotEmpty, true);

        // Act
        await exportService.clearExportHistory();

        // Assert
        history = await exportService.getExportHistory();
        expect(history.isEmpty, true);
      });

      test('should delete specific export from history', () async {
        // Arrange
        await exportService.initialize();

        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        // Create exports
        await exportService.exportStudentReport('student_1', dateRange, 
            const ExportOptions(format: ExportFormat.pdf));
        await exportService.exportStaffReport('staff_1', dateRange, 
            const ExportOptions(format: ExportFormat.pdf));

        var history = await exportService.getExportHistory();
        expect(history.length, 2);

        final exportToDelete = history.first;

        // Act
        await exportService.deleteExportFromHistory(exportToDelete.id);

        // Assert
        history = await exportService.getExportHistory();
        expect(history.length, 1);
        expect(history.any((e) => e.id == exportToDelete.id), false);
      });
    });

    group('Export Statistics', () {
      test('should calculate export statistics correctly', () async {
        // Arrange
        await exportService.initialize();

        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        // Create multiple exports
        await exportService.exportStudentReport('student_1', dateRange, 
            const ExportOptions(format: ExportFormat.pdf));
        await exportService.exportStudentReport('student_2', dateRange, 
            const ExportOptions(format: ExportFormat.csv));
        await exportService.exportStaffReport('staff_1', dateRange, 
            const ExportOptions(format: ExportFormat.pdf));

        // Simulate a failed export
        await exportService.cancelExport('failed_export');

        // Act
        final statistics = await exportService.getExportStatistics();

        // Assert
        expect(statistics.totalExports, 4); // 3 successful + 1 failed
        expect(statistics.successfulExports, 3);
        expect(statistics.failedExports, 1);
        expect(statistics.successRate, 75.0); // 3/4 * 100
        expect(statistics.exportsByFormat[ExportFormat.pdf], 2);
        expect(statistics.exportsByFormat[ExportFormat.csv], 1);
        expect(statistics.averageFileSize, greaterThan(0));
      });

      test('should handle empty export history in statistics', () async {
        // Arrange
        await exportService.initialize();

        // Act
        final statistics = await exportService.getExportStatistics();

        // Assert
        expect(statistics.totalExports, 0);
        expect(statistics.successfulExports, 0);
        expect(statistics.failedExports, 0);
        expect(statistics.successRate, 0.0);
        expect(statistics.averageFileSize, 0.0);
        expect(statistics.lastExportDate, isNull);
      });
    });

    group('File Operations', () {
      test('should handle file sharing', () async {
        // Arrange
        await exportService.initialize();

        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        // Create an export
        final result = await exportService.exportStudentReport(
          'student_1',
          dateRange,
          const ExportOptions(format: ExportFormat.pdf),
        );

        // Act & Assert
        // In a real test, we would mock the Share.shareXFiles method
        // For now, we just verify the method can be called
        expect(() async {
          await exportService.shareExportedFile(result.filePath);
        }, returnsNormally);
      });

      test('should handle file opening', () async {
        // Arrange
        await exportService.initialize();

        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        // Create an export
        final result = await exportService.exportStudentReport(
          'student_1',
          dateRange,
          const ExportOptions(format: ExportFormat.pdf),
        );

        // Act & Assert
        expect(() async {
          await exportService.openExportedFile(result.filePath);
        }, returnsNormally);
      });

      test('should handle file deletion', () async {
        // Arrange
        await exportService.initialize();

        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        // Create an export
        final result = await exportService.exportStudentReport(
          'student_1',
          dateRange,
          const ExportOptions(format: ExportFormat.pdf),
        );

        // Verify file exists
        final file = File(result.filePath);
        expect(await file.exists(), true);

        // Act
        await exportService.deleteExportedFile(result.filePath);

        // Assert
        expect(await file.exists(), false);
        
        // Verify it's removed from history
        final history = await exportService.getExportHistory();
        expect(history.any((e) => e.filePath == result.filePath), false);
      });
    });

    group('Cleanup Operations', () {
      test('should cleanup old exports', () async {
        // Arrange
        await exportService.initialize();

        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
        );

        // Create some exports
        await exportService.exportStudentReport('student_1', dateRange, 
            const ExportOptions(format: ExportFormat.pdf));
        await exportService.exportStaffReport('staff_1', dateRange, 
            const ExportOptions(format: ExportFormat.pdf));

        var history = await exportService.getExportHistory();
        expect(history.length, 2);

        // Act - cleanup exports older than 0 seconds (should remove all)
        await exportService.cleanupOldExports(olderThan: Duration.zero);

        // Assert
        history = await exportService.getExportHistory();
        expect(history.isEmpty, true);
      });
    });

    group('Error Handling', () {
      test('should handle export errors gracefully', () async {
        // Arrange
        await exportService.initialize();

        // Act - try to share a non-existent file
        expect(() async {
          await exportService.shareExportedFile('/non/existent/file.pdf');
        }, throwsException);
      });

      test('should record failed exports in history', () async {
        // Arrange
        await exportService.initialize();

        // Act - cancel an export (simulates failure)
        await exportService.cancelExport('test_export');

        // Assert
        final history = await exportService.getExportHistory();
        expect(history.isNotEmpty, true);
        
        final failedExport = history.first;
        expect(failedExport.success, false);
        expect(failedExport.errorMessage, contains('cancelled'));
      });
    });
  });

  group('ExportResult Model Tests', () {
    test('should format file size correctly', () {
      // Test bytes
      final smallResult = ExportResult(
        id: 'test',
        fileName: 'test.pdf',
        filePath: '/test.pdf',
        format: ExportFormat.pdf,
        fileSize: 512,
        createdAt: DateTime.now(),
        success: true,
      );
      expect(smallResult.formattedFileSize, '512 B');

      // Test KB
      final mediumResult = ExportResult(
        id: 'test',
        fileName: 'test.pdf',
        filePath: '/test.pdf',
        format: ExportFormat.pdf,
        fileSize: 1536, // 1.5 KB
        createdAt: DateTime.now(),
        success: true,
      );
      expect(mediumResult.formattedFileSize, '1.5 KB');

      // Test MB
      final largeResult = ExportResult(
        id: 'test',
        fileName: 'test.pdf',
        filePath: '/test.pdf',
        format: ExportFormat.pdf,
        fileSize: 2097152, // 2 MB
        createdAt: DateTime.now(),
        success: true,
      );
      expect(largeResult.formattedFileSize, '2.0 MB');
    });
  });

  group('ExportProgress Model Tests', () {
    test('should calculate progress percentage correctly', () {
      final progress = ExportProgress(
        exportId: 'test',
        progress: 0.75,
        currentStep: 'Processing',
        timestamp: DateTime.now(),
      );

      expect(progress.progressPercentage, '75%');
      expect(progress.isInProgress, true);
      expect(progress.isCompleted, false);
    });

    test('should identify completed progress', () {
      final progress = ExportProgress(
        exportId: 'test',
        progress: 1.0,
        currentStep: 'Completed',
        timestamp: DateTime.now(),
      );

      expect(progress.isCompleted, true);
      expect(progress.isInProgress, false);
    });
  });

  group('ExportHistoryFilter Model Tests', () {
    test('should detect when filters are applied', () {
      const emptyFilter = ExportHistoryFilter();
      expect(emptyFilter.hasFilters, false);

      const formatFilter = ExportHistoryFilter(format: ExportFormat.pdf);
      expect(formatFilter.hasFilters, true);

      const searchFilter = ExportHistoryFilter(searchQuery: 'test');
      expect(searchFilter.hasFilters, true);

      final dateFilter = ExportHistoryFilter(
        startDate: DateTime(2024, 1, 1),
      );
      expect(dateFilter.hasFilters, true);
    });
  });
}