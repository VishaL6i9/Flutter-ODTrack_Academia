import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/shared/widgets/enhanced_form_field.dart';
import 'package:odtrack_academia/utils/form_validators.dart';

void main() {
  group('EnhancedFormField', () {
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

    testWidgets('should display help text when no error', (WidgetTester tester) async {
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

    testWidgets('should validate on focus change when real-time validation is enabled', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedFormField(
              controller: controller,
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
              enableRealTimeValidation: true,
            ),
          ),
        ),
      );

      // Focus the field
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      // Unfocus the field (should trigger validation)
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('should show error icon when validation fails', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedFormField(
              controller: controller,
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
              enableRealTimeValidation: true,
              showErrorIcon: true,
            ),
          ),
        ),
      );

      // Focus and unfocus to trigger validation
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should show success icon when validation passes', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'valid input');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedFormField(
              controller: controller,
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
              enableRealTimeValidation: true,
              showSuccessIcon: true,
            ),
          ),
        ),
      );

      // Focus and unfocus to trigger validation
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
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

    testWidgets('should use custom validators', (WidgetTester tester) async {
      final controller = TextEditingController();
      final validators = [
        RequiredValidator(),
        MinLengthValidator(5),
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedFormField(
              controller: controller,
              validators: validators,
              enableRealTimeValidation: true,
            ),
          ),
        ),
      );

      // Test with empty value
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsOneWidget);

      // Test with short value
      controller.text = 'abc';
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      expect(find.text('This field must be at least 5 characters long'), findsOneWidget);
    });

    testWidgets('should disable real-time validation when specified', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedFormField(
              controller: controller,
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
              enableRealTimeValidation: false,
            ),
          ),
        ),
      );

      // Focus and unfocus
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      // Should not show error message
      expect(find.text('Required'), findsNothing);
    });
  });

  group('EnhancedPasswordField', () {
    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedPasswordField(),
          ),
        ),
      );

      // Initially should show visibility icon (password is obscured)
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Should now show visibility_off icon (password is visible)
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('should show password strength indicator', (WidgetTester tester) async {
      final controller = TextEditingController();
      
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

      // Enter a weak password
      controller.text = 'weak';
      await tester.pump();

      expect(find.text('Weak'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Enter a strong password
      controller.text = 'StrongPass123!';
      await tester.pump();

      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('should show password requirements for weak passwords', (WidgetTester tester) async {
      final controller = TextEditingController();
      
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

      // Enter a weak password
      controller.text = 'weak';
      await tester.pump();

      expect(find.textContaining('At least 8 characters'), findsOneWidget);
      expect(find.textContaining('One uppercase letter'), findsOneWidget);
    });

    testWidgets('should not show strength indicator when disabled', (WidgetTester tester) async {
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

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Weak'), findsNothing);
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

    testWidgets('should use custom validators', (WidgetTester tester) async {
      final controller = TextEditingController();
      final validators = [
        RequiredValidator(),
        PasswordValidator(requireStrong: true),
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedPasswordField(
              controller: controller,
              validators: validators,
              enableRealTimeValidation: true,
            ),
          ),
        ),
      );

      // Test with weak password
      controller.text = 'weak';
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      expect(find.textContaining('at least 8 characters'), findsOneWidget);
    });
  });
}