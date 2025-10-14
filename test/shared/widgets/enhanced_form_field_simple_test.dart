import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/shared/widgets/enhanced_form_field.dart';
import 'package:odtrack_academia/utils/form_validators.dart';

void main() {
  group('EnhancedFormField Basic Tests', () {
    testWidgets('should display label and hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedFormField(
              label: 'Test Label',
              hint: 'Test Hint',
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('Test Hint'), findsOneWidget);
    });

    testWidgets('should display prefix icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedFormField(
              prefixIcon: Icons.email,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('should display help text when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedFormField(
              helpText: 'This is help text',
            ),
          ),
        ),
      );

      expect(find.text('This is help text'), findsOneWidget);
    });

    testWidgets('should call onChanged callback', (WidgetTester tester) async {
      String? changedValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedFormField(
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test input');
      expect(changedValue, equals('test input'));
    });

    testWidgets('should accept enabled parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedFormField(
              enabled: false,
            ),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should accept readOnly parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedFormField(
              readOnly: true,
            ),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });

  group('EnhancedPasswordField Basic Tests', () {
    testWidgets('should show visibility toggle button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedPasswordField(),
          ),
        ),
      );

      // Should show visibility icon initially
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should toggle visibility icon on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedPasswordField(),
          ),
        ),
      );

      // Initially should show visibility icon
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap the visibility toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Should now show visibility_off icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('should call onChanged callback', (WidgetTester tester) async {
      String? changedValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedPasswordField(
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'password123');
      expect(changedValue, equals('password123'));
    });

    testWidgets('should show progress indicator when strength indicator is enabled', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'password');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedPasswordField(
              controller: controller,
              showStrengthIndicator: true,
            ),
          ),
        ),
      );

      // Should show progress indicator for non-empty password
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should not show progress indicator when strength indicator is disabled', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'password');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedPasswordField(
              controller: controller,
              showStrengthIndicator: false,
            ),
          ),
        ),
      );

      // Should not show progress indicator
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  group('Form Validator Classes', () {
    test('RequiredValidator should work correctly', () {
      final validator = RequiredValidator(fieldName: 'Email');
      
      expect(validator.validate(null), contains('Email is required'));
      expect(validator.validate(''), contains('Email is required'));
      expect(validator.validate('   '), contains('Email is required'));
      expect(validator.validate('value'), isNull);
    });

    test('EmailValidator should work correctly', () {
      final validator = EmailValidator();
      
      expect(validator.validate(null), isNull);
      expect(validator.validate(''), isNull);
      expect(validator.validate('invalid'), isNotNull);
      expect(validator.validate('user@example.com'), isNull);
    });

    test('MinLengthValidator should work correctly', () {
      final validator = MinLengthValidator(5, fieldName: 'Password');
      
      expect(validator.validate(null), isNull);
      expect(validator.validate(''), isNull);
      expect(validator.validate('abc'), contains('Password must be at least 5 characters'));
      expect(validator.validate('abcdef'), isNull);
    });

    test('CompositeValidator should work correctly', () {
      final validator = CompositeValidator([
        RequiredValidator(),
        MinLengthValidator(5),
      ]);
      
      expect(validator.validate(null), contains('required'));
      expect(validator.validate(''), contains('required'));
      expect(validator.validate('abc'), contains('at least 5 characters'));
      expect(validator.validate('abcdef'), isNull);
    });
  });
}