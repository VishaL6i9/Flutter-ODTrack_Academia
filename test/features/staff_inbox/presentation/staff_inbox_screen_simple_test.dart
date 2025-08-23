import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:odtrack_academia/features/staff_inbox/presentation/staff_inbox_screen.dart';
import 'package:odtrack_academia/providers/od_request_provider.dart';
import 'package:odtrack_academia/providers/bulk_operation_provider.dart';
import 'package:odtrack_academia/services/bulk_operations/bulk_operation_service.dart';
import 'package:odtrack_academia/models/od_request.dart';

import '../../../providers/bulk_operation_provider_test.mocks.dart';

@GenerateMocks([BulkOperationService])
void main() {
  group('StaffInboxScreen Simple Tests', () {
    late MockBulkOperationService mockBulkService;
    late List<ODRequest> mockRequests;

    setUp(() {
      mockBulkService = MockBulkOperationService();
      when(mockBulkService.initialize()).thenAnswer((_) async {});
      when(mockBulkService.progressStream).thenAnswer((_) => const Stream.empty());

      mockRequests = [
        ODRequest(
          id: 'request1',
          studentId: 'student1',
          studentName: 'John Doe',
          registerNumber: 'REG001',
          date: DateTime(2024, 1, 15),
          periods: [1, 2],
          reason: 'Medical appointment',
          status: 'pending',
          createdAt: DateTime(2024, 1, 10),
        ),
        ODRequest(
          id: 'request2',
          studentId: 'student2',
          studentName: 'Jane Smith',
          registerNumber: 'REG002',
          date: DateTime(2024, 1, 16),
          periods: [3, 4],
          reason: 'Family function',
          status: 'pending',
          createdAt: DateTime(2024, 1, 11),
        ),
      ];
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          odRequestProvider.overrideWith((ref) => ODRequestNotifier()..state = mockRequests),
          bulkOperationServiceProvider.overrideWithValue(mockBulkService),
        ],
        child: const MaterialApp(
          home: StaffInboxScreen(),
        ),
      );
    }

    testWidgets('should render staff inbox screen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Basic rendering test
      expect(find.text('OD Inbox'), findsOneWidget);
      expect(find.byType(StaffInboxScreen), findsOneWidget);
    });

    testWidgets('should show multi-select button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.checklist), findsOneWidget);
    });

    testWidgets('should enter selection mode when multi-select is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap multi-select button
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();

      // Should show selection mode app bar
      expect(find.text('0 selected'), findsOneWidget);
    });

    testWidgets('should show checkboxes in selection mode', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();

      // Should show checkboxes
      expect(find.byType(Checkbox), findsAtLeastNWidgets(1));
    });

    testWidgets('should select request when checkbox is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();

      // Tap first checkbox
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // Should show 1 selected
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('should show bulk action bar when requests are selected', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();

      // Select a request
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // Should show bulk action bar
      expect(find.text('Reject All'), findsOneWidget);
      expect(find.text('Approve All'), findsOneWidget);
    });
  });
}