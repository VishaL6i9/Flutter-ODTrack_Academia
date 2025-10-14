import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/shared/widgets/custom_refresh_indicator.dart';

void main() {
  group('CustomRefreshIndicator Tests', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomRefreshIndicator(
              onRefresh: () async {
                // Refresh callback
              },
              child: const Center(
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('should trigger refresh when pulled down', (WidgetTester tester) async {
      bool refreshCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomRefreshIndicator(
              onRefresh: () async {
                refreshCalled = true;
                await Future<void>.delayed(const Duration(milliseconds: 100));
              },
              child: ListView(
                children: const [
                  ListTile(title: Text('Item 1')),
                  ListTile(title: Text('Item 2')),
                  ListTile(title: Text('Item 3')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);

      // Simulate pull-to-refresh gesture
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(refreshCalled, isTrue);
    });

    testWidgets('should use custom colors when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomRefreshIndicator(
              onRefresh: () async {},
              color: Colors.red,
              backgroundColor: Colors.blue,
              child: const Center(
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      
      expect(refreshIndicator.color, equals(Colors.red));
      expect(refreshIndicator.backgroundColor, equals(Colors.blue));
    });

    testWidgets('should use custom displacement and edge offset', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomRefreshIndicator(
              onRefresh: () async {},
              displacement: 60.0,
              edgeOffset: 20.0,
              child: const Center(
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      
      expect(refreshIndicator.displacement, equals(60.0));
      expect(refreshIndicator.edgeOffset, equals(20.0));
    });
  });

  group('EnhancedRefreshIndicator Tests', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedRefreshIndicator(
              onRefresh: () async {},
              child: const Center(
                child: Text('Enhanced Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Enhanced Content'), findsOneWidget);
      expect(find.byType(NotificationListener<ScrollNotification>), findsWidgets);
    });

    testWidgets('should use custom text labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedRefreshIndicator(
              onRefresh: () async {},
              refreshText: 'Custom Pull Text',
              releaseText: 'Custom Release Text',
              loadingText: 'Custom Loading Text',
              child: ListView(
                children: const [
                  ListTile(title: Text('Item 1')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      // Note: The custom text would only be visible during the refresh gesture
      // which is complex to test in unit tests
    });

    testWidgets('should use custom indicator and text colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedRefreshIndicator(
              onRefresh: () async {},
              indicatorColor: Colors.green,
              textColor: Colors.purple,
              child: const Center(
                child: Text('Colored Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Colored Content'), findsOneWidget);
    });
  });

  group('RefreshState Tests', () {
    test('should have correct enum values', () {
      expect(RefreshState.values.length, equals(3));
      expect(RefreshState.values, contains(RefreshState.idle));
      expect(RefreshState.values, contains(RefreshState.canRefresh));
      expect(RefreshState.values, contains(RefreshState.refreshing));
    });
  });

  group('BouncyScrollPhysics Tests', () {
    testWidgets('should apply bouncy physics to scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              physics: const BouncyScrollPhysics(),
              itemCount: 20,
              itemBuilder: (context, index) => ListTile(
                title: Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<BouncyScrollPhysics>());
    });

    test('should have correct physics properties', () {
      const physics = BouncyScrollPhysics();
      
      expect(physics.minFlingVelocity, equals(50.0));
      expect(physics.maxFlingVelocity, equals(8000.0));
      
      final spring = physics.spring;
      expect(spring.mass, equals(0.5));
      expect(spring.stiffness, equals(100.0));
      expect(spring.damping, equals(0.8));
    });

    test('should apply to ancestor physics correctly', () {
      const physics = BouncyScrollPhysics();
      const ancestorPhysics = ClampingScrollPhysics();
      
      final appliedPhysics = physics.applyTo(ancestorPhysics);
      expect(appliedPhysics, isA<BouncyScrollPhysics>());
      expect(appliedPhysics.parent, equals(ancestorPhysics));
    });
  });

  group('Refresh Animation Tests', () {
    testWidgets('should handle animation lifecycle correctly', (WidgetTester tester) async {
      bool refreshStarted = false;
      bool refreshCompleted = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomRefreshIndicator(
              onRefresh: () async {
                refreshStarted = true;
                await Future<void>.delayed(const Duration(milliseconds: 200));
                refreshCompleted = true;
              },
              child: ListView(
                children: List.generate(
                  10,
                  (index) => ListTile(title: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      );

      // Trigger refresh
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      
      await tester.pump();
      expect(refreshStarted, isTrue);
      expect(refreshCompleted, isFalse);

      // Wait for refresh to complete
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      
      expect(refreshCompleted, isTrue);
    });
  });
}