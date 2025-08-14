import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/services/analytics/analytics_service.dart';
import 'package:odtrack_academia/services/export/export_service.dart';
import 'package:odtrack_academia/providers/analytics_provider.dart';
import 'package:odtrack_academia/providers/export_provider.dart';
import 'package:odtrack_academia/core/storage/enhanced_storage_manager.dart';

import 'analytics_workflow_test.mocks.dart';

@GenerateMocks([
  AnalyticsService,
  ExportService,
  EnhancedStorageManager,
])
void main() {
  group('Analytics Workflow Integration Tests', () {
    late MockAnalyticsService mockAnalyticsService;
    late MockExportService mockExportService;
    late MockEnhancedStorageManager mockStorageManager;
    late ProviderContainer container;

    setUp(() {
      mockAnalyticsService = MockAnalyticsService();
      mockExportService = MockExportService();
      mockStorageManager = MockEnhancedStorageManager();

      container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
          exportServiceProvider.overrideWithValue(mockExportService),
          enhancedStorageManagerProvider.overrideWithValue(mockStorageManager),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Analytics provider state management', () async {
      // Setup mock responses
      when(mockAnalyticsService.initialize()).thenAnswer((_) async {});
      when(mockAnalyticsService.getODRequestAnalytics(any))
          .thenAnswer((_) async => const AnalyticsData(
        totalRequests: 100,
        approvedRequests: 80,
        rejectedRequests: 15,
        pendingRequests: 5,
        approvalRate: 80.0,
        requestsByMonth: {},
        requestsByDepartment: {},
        topRejectionReasons: [],
        patterns: [],
      ));

      final notifier = container.read(analyticsProvider.notifier);

      // Test initialization
      await notifier.initialize();
      verify(mockAnalyticsService.initialize()).called(1);

      // Test loading analytics data
      final dateRange = DateRange(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      await notifier.loadODRequestAnalytics(dateRange);

      final state = container.read(analyticsProvider);
      expect(state.analyticsData, isNotNull);
      expect(state.analyticsData!.totalRequests, 100);
      expect(state.analyticsData!.approvalRate, 80.0);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('Export provider state management', () async {
      // Setup mock responses
      when(mockExportService.initialize()).thenAnswer((_) async {});
      when(mockExportService.getExportHistory()).thenAnswer((_) async => []);
      when(mockExportService.exportProgressStream)
          .thenAnswer((_) => const Stream.empty());

      final mockResult = ExportResult(
        id: 'export_123',
        fileName: 'test_report.pdf',
        filePath: '/path/to/test_report.pdf',
        format: ExportFormat.pdf,
        fileSize: 1024,
        createdAt: DateTime.now(),
        success: true,
      );

      when(mockExportService.exportAnalyticsReport(any, any))
          .thenAnswer((_) async => mockResult);

      final notifier = container.read(exportProvider.notifier);

      // Test export analytics
      const analyticsData = AnalyticsData(
        totalRequests: 50,
        approvedRequests: 40,
        rejectedRequests: 8,
        pendingRequests: 2,
        approvalRate: 80.0,
        requestsByMonth: {},
        requestsByDepartment: {},
        topRejectionReasons: [],
        patterns: [],
      );

      const options = ExportOptions(format: ExportFormat.pdf);
      final result = await notifier.exportAnalyticsReport(analyticsData, options);

      expect(result.success, true);
      expect(result.fileName, 'test_report.pdf');

      final state = container.read(exportProvider);
      expect(state.exportHistory, contains(result));
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });
  });
}