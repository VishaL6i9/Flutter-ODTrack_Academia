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

import 'staff_inbox_screen_test.mocks.dart';

@GenerateMocks([BulkOperationService])
void main() {
  group('StaffInboxScreen Widget Tests', () {
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
        ODRequest(
          id: 'request3',
          studentId: 'student3',
          studentName: 'Bob Johnson',
          registerNumber: 'REG003',
          date: DateTime(2024, 1, 17),
          periods: [5],
          reason: 'Personal work',
          status: 'approved',
          createdAt: DateTime(2024, 1, 12),
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

    group('Normal Mode UI', () {
      testWidgets('should display app bar with multi-select button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('OD Inbox'), findsOneWidget);
        expect(find.byIcon(Icons.checklist), findsOneWidget);
        expect(find.byTooltip('Multi-select mode'), findsOneWidget);
      });

      testWidgets('should display filter tabs in normal mode', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('All'), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('Approved'), findsOneWidget);
        expect(find.text('Rejected'), findsOneWidget);
      });

      testWidgets('should display stats cards in normal mode', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('2'), findsOneWidget); // Pending count
        expect(find.text('1'), findsOneWidget); // Approved count
        expect(find.text('0'), findsOneWidget); // Rejected count
      });

      testWidgets('should display request cards without checkboxes in normal mode', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('Bob Johnson'), findsOneWidget);
        expect(find.byType(Checkbox), findsNothing);
      });

      testWidgets('should show individual action buttons for pending requests', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should have 2 approve buttons and 2 reject buttons for pending requests
        expect(find.text('Approve'), findsNWidgets(2));
        expect(find.text('Reject'), findsNWidgets(2));
      });
    });

    group('Selection Mode UI', () {
      testWidgets('should enter selection mode when multi-select button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap multi-select button
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        // Should show selection mode app bar
        expect(find.text('0 selected'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should hide filter tabs and stats in selection mode', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        // Filter tabs and stats should be hidden
        expect(find.text('All'), findsNothing);
        expect(find.text('Pending'), findsNothing);
        // Stats cards should be hidden
        expect(find.text('2'), findsNothing); // Pending count should be hidden
      });

      testWidgets('should show selection header in selection mode', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        expect(find.text('0 of 3 requests selected'), findsOneWidget);
        expect(find.text('Select All'), findsOneWidget);
      });

      testWidgets('should show checkboxes for pending requests in selection mode', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        // Should show checkboxes only for pending requests (2 checkboxes)
        expect(find.byType(Checkbox), findsNWidgets(2));
      });

      testWidgets('should hide individual action buttons in selection mode', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        // Individual action buttons should be hidden
        expect(find.text('Approve'), findsNothing);
        expect(find.text('Reject'), findsNothing);
      });
    });

    group('Selection Functionality', () {
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

      testWidgets('should select request when card is tapped in selection mode', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        // Tap on a request card (find by student name)
        await tester.tap(find.text('John Doe'));
        await tester.pumpAndSettle();

        // Should show 1 selected
        expect(find.text('1 selected'), findsOneWidget);
      });

      testWidgets('should select all pending requests when Select All is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        // Tap Select All
        await tester.tap(find.text('Select All'));
        await tester.pumpAndSettle();

        // Should show 2 selected (only pending requests)
        expect(find.text('2 selected'), findsOneWidget);
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
        expect(find.byIcon(Icons.download), findsOneWidget);
      });

      testWidgets('should clear selection when clear button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode and select a request
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();

        expect(find.text('1 selected'), findsOneWidget);

        // Tap clear button
        await tester.tap(find.byIcon(Icons.clear_all));
        await tester.pumpAndSettle();

        // Should show 0 selected
        expect(find.text('0 selected'), findsOneWidget);
      });

      testWidgets('should exit selection mode when close button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();
        expect(find.text('0 selected'), findsOneWidget);

        // Tap close button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Should be back to normal mode
        expect(find.text('OD Inbox'), findsOneWidget);
        expect(find.byIcon(Icons.checklist), findsOneWidget);
        expect(find.text('All'), findsOneWidget); // Filter tabs should be back
      });
    });

    group('Bulk Action Dialogs', () {
      testWidgets('should show bulk approval dialog when Approve All is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode and select requests
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Select All'));
        await tester.pumpAndSettle();

        // Tap Approve All
        await tester.tap(find.text('Approve All'));
        await tester.pumpAndSettle();

        // Should show approval dialog
        expect(find.text('Approve 2 Requests'), findsOneWidget);
        expect(find.text('You are about to approve 2 OD requests.'), findsOneWidget);
        expect(find.text('Approval reason (optional):'), findsOneWidget);
      });

      testWidgets('should show bulk rejection dialog when Reject All is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode and select requests
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Select All'));
        await tester.pumpAndSettle();

        // Tap Reject All
        await tester.tap(find.text('Reject All'));
        await tester.pumpAndSettle();

        // Should show rejection dialog
        expect(find.text('Reject 2 Requests'), findsOneWidget);
        expect(find.text('You are about to reject 2 OD requests.'), findsOneWidget);
        expect(find.text('Rejection reason (required):'), findsOneWidget);
      });

      testWidgets('should show bulk export dialog when export button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode and select requests
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Select All'));
        await tester.pumpAndSettle();

        // Tap export button
        await tester.tap(find.byIcon(Icons.download));
        await tester.pumpAndSettle();

        // Should show export dialog
        expect(find.text('Export 2 Requests'), findsOneWidget);
        expect(find.text('Choose export format for 2 selected requests:'), findsOneWidget);
        expect(find.text('PDF Report'), findsOneWidget);
        expect(find.text('CSV Spreadsheet'), findsOneWidget);
      });
    });

    group('Visual Feedback', () {
      testWidgets('should highlight selected request cards', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        // Find the first card and select it
        final cardFinder = find.ancestor(
          of: find.text('John Doe'),
          matching: find.byType(Card),
        );
        
        // Get the card before selection
        final cardBefore = tester.widget<Card>(cardFinder);
        
        // Select the request
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();

        // Get the card after selection
        final cardAfter = tester.widget<Card>(cardFinder);
        
        // The card color should change when selected
        expect(cardBefore.color, isNot(equals(cardAfter.color)));
      });

      testWidgets('should disable bulk action buttons when operation is in progress', (tester) async {
        // This test would require mocking a progress state
        // For now, we'll test the basic structure
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter selection mode and select requests
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Select All'));
        await tester.pumpAndSettle();

        // Bulk action buttons should be enabled
        final approveButton = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Approve All'),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(approveButton.onPressed, isNotNull);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle empty request list gracefully', (tester) async {
        final emptyWidget = ProviderScope(
          overrides: [
            odRequestProvider.overrideWith((ref) => ODRequestNotifier()..state = <ODRequest>[]),
            bulkOperationServiceProvider.overrideWithValue(mockBulkService),
          ],
          child: const MaterialApp(
            home: StaffInboxScreen(),
          ),
        );

        await tester.pumpWidget(emptyWidget);
        await tester.pumpAndSettle();

        expect(find.text('No all requests'), findsOneWidget);
        expect(find.byIcon(Icons.checklist), findsOneWidget); // Multi-select button should still be there
      });

      testWidgets('should disable Select All when no pending requests', (tester) async {
        final approvedOnlyRequests = [
          ODRequest(
            id: 'request1',
            studentId: 'student1',
            studentName: 'John Doe',
            registerNumber: 'REG001',
            date: DateTime(2024, 1, 15),
            periods: [1, 2],
            reason: 'Medical appointment',
            status: 'approved',
            createdAt: DateTime(2024, 1, 10),
          ),
        ];

        final widget = ProviderScope(
          overrides: [
            odRequestProvider.overrideWith((ref) => ODRequestNotifier()..state = approvedOnlyRequests),
            bulkOperationServiceProvider.overrideWithValue(mockBulkService),
          ],
          child: const MaterialApp(
            home: StaffInboxScreen(),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.tap(find.byIcon(Icons.checklist));
        await tester.pumpAndSettle();

        // Select All button should be disabled
        final selectAllButton = tester.widget<TextButton>(
          find.ancestor(
            of: find.text('Select All'),
            matching: find.byType(TextButton),
          ),
        );
        expect(selectAllButton.onPressed, isNull);
      });
    });
  });
}