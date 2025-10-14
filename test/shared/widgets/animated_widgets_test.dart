import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/shared/widgets/animated_widgets.dart';

void main() {
  group('AnimatedWidgets Tests', () {
    testWidgets('EnhancedAnimatedContainer should animate child widget', (WidgetTester tester) async {
      bool animationCompleted = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedAnimatedContainer(
              duration: const Duration(milliseconds: 100),
              onAnimationComplete: () {
                animationCompleted = true;
              },
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      // Wait for animation to complete
      await tester.pumpAndSettle();
      expect(animationCompleted, isTrue);
    });

    testWidgets('AnimatedListItem should render with staggered animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 2,
              delay: Duration(milliseconds: 50),
              child: Text('List Item'),
            ),
          ),
        ),
      );

      expect(find.text('List Item'), findsOneWidget);
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      // Animation should start after delay * index
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
    });

    testWidgets('AnimatedPageTransition should render child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedPageTransition(
              transitionType: PageTransitionType.fade,
              duration: Duration(milliseconds: 100),
              child: Text('Page Content'),
            ),
          ),
        ),
      );

      expect(find.text('Page Content'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('AnimatedButton should respond to tap gestures', (WidgetTester tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedButton(
              onPressed: () {
                buttonPressed = true;
              },
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);
      expect(find.byType(ScaleTransition), findsWidgets);

      // Test tap down
      await tester.press(find.byType(AnimatedButton));
      await tester.pump();

      // Test tap up
      await tester.pumpAndSettle();
      expect(buttonPressed, isTrue);
    });

    testWidgets('AnimatedCounter should animate number changes', (WidgetTester tester) async {
      int currentValue = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AnimatedCounter(
                      value: currentValue,
                      duration: const Duration(milliseconds: 100),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentValue = 10;
                        });
                      },
                      child: const Text('Increment'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initial value should be 0
      expect(find.text('0'), findsOneWidget);

      // Tap button to change value
      await tester.tap(find.text('Increment'));
      await tester.pump();

      // Animation should be in progress
      await tester.pump(const Duration(milliseconds: 50));
      
      // Final value should be reached after animation completes
      await tester.pumpAndSettle();
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('AnimatedCounter should handle zero values correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 0,
              textStyle: TextStyle(fontSize: 20),
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      
      final textWidget = tester.widget<Text>(find.text('0'));
      expect(textWidget.style?.fontSize, equals(20));
    });
  });

  group('Animation Controller Tests', () {
    testWidgets('should properly dispose animation controllers', (WidgetTester tester) async {
      // Test that widgets properly dispose their animation controllers
      // This is important to prevent memory leaks
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedAnimatedContainer(
              child: Text('Test'),
            ),
          ),
        ),
      );

      // Remove the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Different Content'),
          ),
        ),
      );

      // Should not throw any errors about disposed controllers
      await tester.pumpAndSettle();
      expect(find.text('Different Content'), findsOneWidget);
    });

    testWidgets('should handle rapid state changes gracefully', (WidgetTester tester) async {
      int counter = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AnimatedCounter(
                      value: counter,
                      duration: const Duration(milliseconds: 200),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          counter++;
                        });
                      },
                      child: const Text('Increment'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Rapidly change values
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Increment'));
        await tester.pump(const Duration(milliseconds: 10));
      }

      // Should handle rapid changes without errors
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
    });
  });
}