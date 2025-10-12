import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/main.dart' as app;
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/providers/export_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Export Workflow Integration Tests', () {
    late WidgetTester tester;
    late ProviderContainer container;

    setUpAll(() async {
      // Initialize the app
      app.main();
    });

    setUp(() async {
      container = ProviderContainer();
    });

    tearDown(() async {
      container.dispose();
    });

    testWidgets('Complete student report export workflow', (WidgetTester widgetTester) async {
      tester = widgetTester;
      
      // Build the app
      await tester.pumpWidget(
        ProviderScope(
          overrides: const [],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () async {
                      // Test student report export
                      final exportNotifier = ref.read(exportProvider.notifier);
                      
                      final dateRange = DateRange(
                        startDate: DateTime(2024, 1, 1),
                        endDate: DateTime(2024, 12, 31),
                      );
                      
                      const options = ExportOptions(
                        format: ExportFormat.pdf,
                        includeCharts: true,
                        includeMetadata: true,
                        customTitle: 'Test Student Report',
                      );
                      
                      await exportNotifier.exportStudentReport(
                        'student_123',
                        dateRange,
                        options,
                      );
                    },
                    child: const Text('Export Student Report'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the export button
      final exportButton = find.text('Export Student Report');
      expect(exportButton, findsOneWidget);
      
      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      // Verify export was initiated
      final exportState = container.read(exportProvider);
      expect(exportState.exportHistory.isNotEmpty, true);
      
      // Verify the export result
      final latestExport = exportState.exportHistory.first;
      expect(latestExport.success, true);
      expect(latestExport.format, ExportFormat.pdf);
      expect(latestExport.fileName.contains('test_student_report'), true);
      
      // Verify file was created
      final file = File(latestExport.filePath);
      expect(await file.exists(), true);
      expect(latestExport.fileSize, greaterThan(0));
    });

    testWidgets('Complete staff analytics export workflow', (WidgetTester widgetTester) async {
      tester = widgetTester;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: const [],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () async {
                      final exportNotifier = ref.read(exportProvider.notifier);
                      
                      final dateRange = DateRange(
                        startDate: DateTime(2024, 1, 1),
                        endDate: DateTime(2024, 12, 31),
                      );
                      
                      const options = ExportOptions(
                        format: ExportFormat.pdf,
                        includeCharts: true,
                        includeMetadata: true,
                        customTitle: 'Test Staff Analytics Report',
                      );
                      
                      await exportNotifier.exportStaffReport(
                        'staff_456',
                        dateRange,
                        options,
                      );
                    },
                    child: const Text('Export Staff Report'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Export Staff Report'));
      await tester.pumpAndSettle();

      final exportState = container.read(exportProvider);
      expect(exportState.exportHistory.isNotEmpty, true);
      
      final latestExport = exportState.exportHistory.first;
      expect(latestExport.success, true);
      expect(latestExport.format, ExportFormat.pdf);
      
      final file = File(latestExport.filePath);
      expect(await file.exists(), true);
    });

    testWidgets('Complete analytics report export workflow', (WidgetTester widgetTester) async {
      tester = widgetTester;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: const [],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () async {
                      final exportNotifier = ref.read(exportProvider.notifier);
                      
                      // Create mock analytics data
                      const analyticsData = AnalyticsData(
                        totalRequests: 100,
                        approvedRequests: 80,
                        rejectedRequests: 15,
                        pendingRequests: 5,
                        approvalRate: 80.0,
                        requestsByMonth: {'Jan': 20, 'Feb': 25, 'Mar': 30},
                        requestsByDepartment: {'CS': 50, 'IT': 30, 'ECE': 20},
                        topRejectionReasons: [
                          RejectionReason(
                            reason: 'Insufficient notice',
                            count: 10,
                            percentage: 66.7,
                          ),
                        ],
                        patterns: [
                          RequestPattern(
                            pattern: 'High requests on Fridays',
                            description: 'Students tend to request more ODs on Fridays',
                            confidence: 0.85,
                          ),
                        ],
                      );
                      
                      const options = ExportOptions(
                        format: ExportFormat.pdf,
                        includeCharts: true,
                        includeMetadata: true,
                        customTitle: 'Test Analytics Report',
                      );
                      
                      await exportNotifier.exportAnalyticsReport(
                        analyticsData,
                        options,
                      );
                    },
                    child: const Text('Export Analytics Report'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Export Analytics Report'));
      await tester.pumpAndSettle();

      final exportState = container.read(exportProvider);
      expect(exportState.exportHistory.isNotEmpty, true);
      
      final latestExport = exportState.exportHistory.first;
      expect(latestExport.success, true);
      expect(latestExport.format, ExportFormat.pdf);
      
      final file = File(latestExport.filePath);
      expect(await file.exists(), true);
    });

    testWidgets('Complete bulk requests export workflow', (WidgetTester widgetTester) async {
      tester = widgetTester;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: const [],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () async {
                      final exportNotifier = ref.read(exportProvider.notifier);
                      
                      // Create mock OD requests
                      final requests = [
                        ODRequest(
                          id: 'req_1',
                          studentId: 'student_1',
                          studentName: 'John Doe',
                          registerNumber: 'REG001',
                          date: DateTime(2024, 3, 15),
                          periods: [1, 2],
                          reason: 'Medical appointment',
                          status: 'approved',
                          createdAt: DateTime(2024, 3, 15, 8, 0),
                          staffId: 'staff_1',
                        ),
                        ODRequest(
                          id: 'req_2',
                          studentId: 'student_2',
                          studentName: 'Jane Smith',
                          registerNumber: 'REG002',
                          date: DateTime(2024, 3, 16),
                          periods: [3, 4, 5],
                          reason: 'Family function',
                          status: 'pending',
                          createdAt: DateTime(2024, 3, 16, 9, 0),
                          staffId: 'staff_1',
                        ),
                      ];
                      
                      const options = ExportOptions(
                        format: ExportFormat.pdf,
                        includeCharts: false,
                        includeMetadata: true,
                        customTitle: 'Test Bulk Export',
                      );
                      
                      await exportNotifier.exportBulkRequests(requests, options);
                    },
                    child: const Text('Export Bulk Requests'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Export Bulk Requests'));
      await tester.pumpAndSettle();

      final exportState = container.read(exportProvider);
      expect(exportState.exportHistory.isNotEmpty, true);
      
      final latestExport = exportState.exportHistory.first;
      expect(latestExport.success, true);
      expect(latestExport.format, ExportFormat.pdf);
      
      final file = File(latestExport.filePath);
      expect(await file.exists(), true);
    });

    testWidgets('Export progress tracking workflow', (WidgetTester widgetTester) async {
      tester = widgetTester;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: const [],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final activeExports = ref.watch(activeExportsProvider);
                  final hasActiveExports = ref.watch(hasActiveExportsProvider);
                  
                  return Column(
                    children: [
                      Text('Active Exports: ${activeExports.length}'),
                      Text('Has Active: $hasActiveExports'),
                      ElevatedButton(
                        onPressed: () async {
                          final exportNotifier = ref.read(exportProvider.notifier);
                          
                          final dateRange = DateRange(
                            startDate: DateTime(2024, 1, 1),
                            endDate: DateTime(2024, 12, 31),
                          );
                          
                          const options = ExportOptions(
                            format: ExportFormat.pdf,
                            includeCharts: true,
                            includeMetadata: true,
                          );
                          
                          // Start export (this should show progress)
                          await exportNotifier.exportStudentReport(
                            'student_progress_test',
                            dateRange,
                            options,
                          );
                        },
                        child: const Text('Start Export'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no active exports
      expect(find.text('Active Exports: 0'), findsOneWidget);
      expect(find.text('Has Active: false'), findsOneWidget);

      // Start export
      await tester.tap(find.text('Start Export'));
      await tester.pump(); // Don't settle, we want to catch progress

      // Export should complete quickly in test
      await tester.pumpAndSettle();

      // Verify export completed
      final exportState = container.read(exportProvider);
      expect(exportState.exportHistory.isNotEmpty, true);
      expect(exportState.activeExports.isEmpty, true);
    });

    testWidgets('Export history and statistics workflow', (WidgetTester widgetTester) async {
      tester = widgetTester;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: const [],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          // Load statistics
                          await ref.read(exportProvider.notifier).loadExportStatistics();
                        },
                        child: const Text('Load Statistics'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Apply filter
                          const filter = ExportHistoryFilter(
                            format: ExportFormat.pdf,
                            successOnly: true,
                          );
                          await ref.read(exportProvider.notifier).applyHistoryFilter(filter);
                        },
                        child: const Text('Apply Filter'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Clear history
                          await ref.read(exportProvider.notifier).clearExportHistory();
                        },
                        child: const Text('Clear History'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test loading statistics
      await tester.tap(find.text('Load Statistics'));
      await tester.pumpAndSettle();

      final exportState = container.read(exportProvider);
      expect(exportState.statistics, isNotNull);

      // Test applying filter
      await tester.tap(find.text('Apply Filter'));
      await tester.pumpAndSettle();

      final filteredState = container.read(exportProvider);
      expect(filteredState.currentFilter.format, ExportFormat.pdf);
      expect(filteredState.currentFilter.successOnly, true);

      // Test clearing history
      await tester.tap(find.text('Clear History'));
      await tester.pumpAndSettle();

      final clearedState = container.read(exportProvider);
      expect(clearedState.exportHistory.isEmpty, true);
    });

    testWidgets('Export sharing integration workflow', (WidgetTester widgetTester) async {
      tester = widgetTester;
      
      // First create an export
      await tester.pumpWidget(
        ProviderScope(
          overrides: const [],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton(
                    onPressed: () async {
                      final exportNotifier = ref.read(exportProvider.notifier);
                      
                      final dateRange = DateRange(
                        startDate: DateTime(2024, 1, 1),
                        endDate: DateTime(2024, 12, 31),
                      );
                      
                      const options = ExportOptions(
                        format: ExportFormat.pdf,
                        includeCharts: true,
                        includeMetadata: true,
                        customTitle: 'Test Share Export',
                      );
                      
                      await exportNotifier.exportStudentReport(
                        'student_share_test',
                        dateRange,
                        options,
                      );
                    },
                    child: const Text('Create Export for Sharing'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Create export
      await tester.tap(find.text('Create Export for Sharing'));
      await tester.pumpAndSettle();

      // Verify export was created
      final exportState = container.read(exportProvider);
      expect(exportState.exportHistory.isNotEmpty, true);
      
      final export = exportState.exportHistory.first;
      expect(export.success, true);
      
      // Test sharing (this would normally open the share dialog)
      // In integration test, we just verify the method can be called
      expect(() async {
        await container.read(exportProvider.notifier).shareExportedFile(export.filePath);
      }, returnsNormally);
      
      // Test opening file
      expect(() async {
        await container.read(exportProvider.notifier).openExportedFile(export.filePath);
      }, returnsNormally);
    });

    testWidgets('Export error handling workflow', (WidgetTester widgetTester) async {
      tester = widgetTester;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: const [],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final error = ref.watch(exportErrorProvider);
                  
                  return Column(
                    children: [
                      if (error != null) Text('Error: $error'),
                      ElevatedButton(
                        onPressed: () async {
                          // Try to share a non-existent file to trigger error
                          await ref.read(exportProvider.notifier)
                              .shareExportedFile('/non/existent/file.pdf');
                        },
                        child: const Text('Trigger Error'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(exportProvider.notifier).clearError();
                        },
                        child: const Text('Clear Error'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no error
      expect(find.textContaining('Error:'), findsNothing);

      // Trigger error
      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      // Should show error
      expect(find.textContaining('Error:'), findsOneWidget);

      // Clear error
      await tester.tap(find.text('Clear Error'));
      await tester.pumpAndSettle();

      // Error should be cleared
      expect(find.textContaining('Error:'), findsNothing);
    });
  });
}