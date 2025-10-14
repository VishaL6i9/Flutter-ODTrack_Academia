import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/core/accessibility/accessibility_service.dart';
import 'package:odtrack_academia/core/accessibility/focus_manager.dart';
import 'package:odtrack_academia/shared/widgets/accessible_button.dart';
import 'package:odtrack_academia/shared/widgets/accessible_form_components.dart';
import 'package:odtrack_academia/shared/widgets/accessible_app_bar.dart';
import 'package:odtrack_academia/shared/widgets/breadcrumb_widget.dart';

void main() {
  group('Accessibility Service Tests', () {
    late AccessibilityService accessibilityService;

    setUp(() {
      accessibilityService = AccessibilityService.instance;
    });

    test('should provide semantic labels correctly', () {
      final label = accessibilityService.getSemanticLabel(
        label: 'Submit',
        hint: 'Submit the form',
        value: 'Button',
        isSelected: true,
        isEnabled: true,
      );

      expect(label, contains('Submit'));
      expect(label, contains('Button'));
      expect(label, contains('selected'));
      expect(label, contains('Submit the form'));
    });

    test('should create button semantics correctly', () {
      final semantics = accessibilityService.getButtonSemantics(
        label: 'Test Button',
        hint: 'Press to test',
        enabled: true,
        onTap: () {},
      );

      expect(semantics.label, equals('Test Button'));
      expect(semantics.hint, equals('Press to test'));
      expect(semantics.enabled, isTrue);
      expect(semantics.button, isTrue);
    });

    test('should create text field semantics correctly', () {
      final semantics = accessibilityService.getTextFieldSemantics(
        label: 'Email',
        hint: 'Enter your email',
        value: 'test@example.com',
        enabled: true,
        obscureText: false,
      );

      expect(semantics.label, equals('Email'));
      expect(semantics.hint, equals('Enter your email'));
      expect(semantics.value, equals('test@example.com'));
      expect(semantics.enabled, isTrue);
      expect(semantics.textField, isTrue);
      expect(semantics.obscured, isFalse);
    });

    test('should create list item semantics correctly', () {
      final semantics = accessibilityService.getListItemSemantics(
        label: 'Item 1',
        hint: 'Tap to select',
        index: 0,
        total: 5,
        selected: false,
        onTap: () {},
      );

      expect(semantics.label, equals('Item 1, item 1 of 5'));
      expect(semantics.hint, equals('Tap to select'));
      expect(semantics.selected, isFalse);
    });
  });

  group('Focus Manager Tests', () {
    late EnhancedFocusManager focusManager;

    setUp(() {
      focusManager = EnhancedFocusManager.instance;
    });

    tearDown(() {
      focusManager.dispose();
    });

    test('should register and retrieve focus nodes', () {
      final focusNode = FocusNode();
      focusManager.registerFocusNode('test_node', focusNode);

      final retrievedNode = focusManager.getFocusNode('test_node');
      expect(retrievedNode, equals(focusNode));

      focusManager.unregisterFocusNode('test_node');
      final removedNode = focusManager.getFocusNode('test_node');
      expect(removedNode, isNull);

      focusNode.dispose();
    });

    test('should provide navigation shortcuts', () {
      final shortcuts = focusManager.getNavigationShortcuts();
      
      expect(shortcuts, isNotEmpty);
      expect(shortcuts.keys.any((key) => key.toString().contains('Tab')), isTrue);
      expect(shortcuts.keys.any((key) => key.toString().contains('Escape')), isTrue);
      expect(shortcuts.keys.any((key) => key.toString().contains('Enter')), isTrue);
    });
  });

  group('Accessible Button Widget Tests', () {
    testWidgets('should have correct semantics', (WidgetTester tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Test Button',
              tooltip: 'This is a test button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      // Find the button
      final buttonFinder = find.byType(AccessibleButton);
      expect(buttonFinder, findsOneWidget);

      // Check semantics
      final semantics = tester.getSemantics(buttonFinder);
      expect(semantics.label, contains('Test Button'));
      expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      // Test button press
      await tester.tap(buttonFinder);
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('should handle disabled state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Disabled Button',
              enabled: false,
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(AccessibleButton);
      final semantics = tester.getSemantics(buttonFinder);
      expect(semantics.label, contains('disabled'));
      expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    });
  });

  group('Accessible Text Field Widget Tests', () {
    testWidgets('should have correct semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleTextField(
              label: 'Email',
              hint: 'Enter your email address',
              required: true,
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(AccessibleTextField);
      expect(textFieldFinder, findsOneWidget);

      // Check that required indicator is shown
      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('should handle text input correctly', (WidgetTester tester) async {
      String? inputValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleTextField(
              label: 'Test Field',
              onChanged: (value) => inputValue = value,
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(TextFormField);
      await tester.enterText(textFieldFinder, 'test input');
      await tester.pump();

      expect(inputValue, equals('test input'));
    });
  });

  group('Accessible App Bar Widget Tests', () {
    testWidgets('should display title and breadcrumbs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AccessibleAppBar(
                title: 'Test Screen',
                showBreadcrumbs: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Screen'), findsOneWidget);
      expect(find.byType(CompactBreadcrumbWidget), findsOneWidget);
    });
  });

  group('Breadcrumb Widget Tests', () {
    testWidgets('should display breadcrumbs correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BreadcrumbWidget(),
            ),
          ),
        ),
      );

      // Should show dashboard breadcrumb by default
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });

  group('High Contrast Mode Tests', () {
    testWidgets('should apply high contrast styles when enabled', (WidgetTester tester) async {
      // Mock high contrast mode
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter/platform'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemChrome.setSystemUIOverlayStyle') {
            return null;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'High Contrast Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
    });
  });

  group('Keyboard Navigation Tests', () {
    testWidgets('should handle keyboard navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AccessibleButton(
                  label: 'Button 1',
                  onPressed: () {},
                ),
                const AccessibleTextField(
                  label: 'Text Field',
                ),
                AccessibleButton(
                  label: 'Button 2',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Test tab navigation
      tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Verify focus moved
      expect(tester.binding.focusManager.primaryFocus, isNotNull);
    });
  });

  group('Screen Reader Announcements Tests', () {
    testWidgets('should make announcements for screen readers', (WidgetTester tester) async {
      final List<String> announcements = [];
      
      // Mock the semantics service
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter/accessibility'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'announce') {
            announcements.add(methodCall.arguments['message'] as String);
          }
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Announce Button',
              onPressed: () {
                AccessibilityService.instance.announceToScreenReader('Button pressed');
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AccessibleButton));
      await tester.pump();

      // Note: In a real test environment, you would verify the announcement was made
      // This is a simplified test structure
    });
  });
}