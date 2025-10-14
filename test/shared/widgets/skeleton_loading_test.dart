import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/shared/widgets/skeleton_loading.dart';

void main() {
  group('SkeletonLoading Widget Tests', () {
    testWidgets('should render basic skeleton loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoading(
              width: 100,
              height: 20,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoading), findsOneWidget);
    });

    testWidgets('should render skeleton avatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonAvatar(radius: 25),
          ),
        ),
      );

      expect(find.byType(SkeletonAvatar), findsOneWidget);
      
      final skeletonLoading = tester.widget<SkeletonLoading>(
        find.byType(SkeletonLoading),
      );
      expect(skeletonLoading.width, equals(50.0)); // radius * 2
      expect(skeletonLoading.height, equals(50.0)); // radius * 2
    });

    testWidgets('should render skeleton text with single line', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonText(
              width: 150,
              height: 16,
              lines: 1,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonText), findsOneWidget);
      expect(find.byType(SkeletonLoading), findsOneWidget);
    });

    testWidgets('should render skeleton text with multiple lines', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonText(
              width: 150,
              height: 16,
              lines: 3,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonText), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(SkeletonLoading), findsNWidgets(3));
    });

    testWidgets('should render skeleton button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonButton(
              width: 120,
              height: 40,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonButton), findsOneWidget);
      
      final skeletonLoading = tester.widget<SkeletonLoading>(
        find.byType(SkeletonLoading),
      );
      expect(skeletonLoading.width, equals(120.0));
      expect(skeletonLoading.height, equals(40.0));
    });

    testWidgets('should render skeleton card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(
              width: 200,
              height: 100,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });
  });
}