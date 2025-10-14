import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/shared/widgets/accessible_app_bar.dart';
import 'package:odtrack_academia/shared/widgets/accessible_button.dart';
import 'package:odtrack_academia/shared/widgets/accessible_form_components.dart';
import 'package:odtrack_academia/core/accessibility/accessibility_service.dart';

/// Demo screen showcasing accessibility features
class AccessibilityDemoScreen extends ConsumerStatefulWidget {
  const AccessibilityDemoScreen({super.key});

  @override
  ConsumerState<AccessibilityDemoScreen> createState() => _AccessibilityDemoScreenState();
}

class _AccessibilityDemoScreenState extends ConsumerState<AccessibilityDemoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedDepartment;
  bool _agreeToTerms = false;

  final List<String> _departments = [
    'Computer Science',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService.instance;

    return Scaffold(
      appBar: const AccessibleAppBar(
        title: 'Accessibility Demo',
        showBreadcrumbs: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accessibility status card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accessibility Status',
                        style: theme.textTheme.headlineSmall,
                        semanticsLabel: 'Accessibility Status Information',
                      ),
                      const SizedBox(height: 16),
                      _buildStatusItem(
                        'Screen Reader',
                        accessibilityService.isScreenReaderEnabled,
                        'Screen reader support is ${accessibilityService.isScreenReaderEnabled ? 'enabled' : 'disabled'}',
                      ),
                      _buildStatusItem(
                        'High Contrast',
                        accessibilityService.isHighContrastEnabled,
                        'High contrast mode is ${accessibilityService.isHighContrastEnabled ? 'enabled' : 'disabled'}',
                      ),
                      _buildStatusItem(
                        'Bold Text',
                        accessibilityService.isBoldTextEnabled,
                        'Bold text is ${accessibilityService.isBoldTextEnabled ? 'enabled' : 'disabled'}',
                      ),
                      _buildStatusItem(
                        'Reduce Motion',
                        accessibilityService.isReduceMotionEnabled,
                        'Reduce motion is ${accessibilityService.isReduceMotionEnabled ? 'enabled' : 'disabled'}',
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Form demonstration
              Text(
                'Accessible Form Demo',
                style: theme.textTheme.headlineSmall,
                semanticsLabel: 'Accessible Form Demonstration',
              ),
              const SizedBox(height: 16),
              
              AccessibleTextField(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: _nameController,
                required: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              AccessibleTextField(
                label: 'Email Address',
                hint: 'Enter your email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                required: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              AccessibleDropdownField<String>(
                label: 'Department',
                hint: 'Select your department',
                value: _selectedDepartment,
                required: true,
                items: _departments.map((dept) => DropdownMenuItem(
                  value: dept,
                  child: Text(dept),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a department';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              AccessibleCheckbox(
                label: 'I agree to the terms and conditions',
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Button demonstrations
              Text(
                'Accessible Buttons Demo',
                style: theme.textTheme.headlineSmall,
                semanticsLabel: 'Accessible Buttons Demonstration',
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  AccessibleButton.elevated(
                    label: 'Submit Form',
                    icon: const Icon(Icons.send),
                    tooltip: 'Submit the form data',
                    onPressed: _submitForm,
                  ),
                  
                  AccessibleButton.outlined(
                    label: 'Reset Form',
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset all form fields',
                    onPressed: _resetForm,
                  ),
                  
                  AccessibleButton.text(
                    label: 'Cancel',
                    tooltip: 'Cancel and go back',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Accessibility actions demo
              Text(
                'Accessibility Actions Demo',
                style: theme.textTheme.headlineSmall,
                semanticsLabel: 'Accessibility Actions Demonstration',
              ),
              const SizedBox(height: 16),
              
              AccessibleButton.outlined(
                label: 'Test Screen Reader Announcement',
                tooltip: 'Make an announcement to screen readers',
                onPressed: () {
                  accessibilityService.announceToScreenReader(
                    'This is a test announcement for screen readers'
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Announcement sent to screen reader'),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              AccessibleButton.outlined(
                label: 'Test Haptic Feedback',
                tooltip: 'Provide haptic feedback',
                onPressed: () {
                  accessibilityService.provideHapticFeedback();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Haptic feedback provided'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isEnabled, String semanticLabel) {
    return Semantics(
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isEnabled ? Icons.check_circle : Icons.cancel,
              color: isEnabled ? Colors.green : Colors.red,
              semanticLabel: isEnabled ? 'Enabled' : 'Disabled',
            ),
            const SizedBox(width: 8),
            Text(label),
            const Spacer(),
            Text(
              isEnabled ? 'Enabled' : 'Disabled',
              style: TextStyle(
                color: isEnabled ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the terms and conditions'),
          ),
        );
        return;
      }
      
      AccessibilityService.instance.announceToScreenReader('Form submitted successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form submitted successfully!'),
        ),
      );
    } else {
      AccessibilityService.instance.announceToScreenReader('Form has validation errors');
    }
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    setState(() {
      _selectedDepartment = null;
      _agreeToTerms = false;
    });
    
    AccessibilityService.instance.announceToScreenReader('Form has been reset');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form reset successfully!'),
      ),
    );
  }
}