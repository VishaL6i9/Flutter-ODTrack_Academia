import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';
import 'package:odtrack_academia/features/staff_directory/data/staff_data.dart';
import 'package:odtrack_academia/features/staff_directory/presentation/staff_directory_screen.dart';
import 'package:odtrack_academia/features/timetable/data/timetable_data.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/staff_member.dart';
import 'package:odtrack_academia/providers/od_request_provider.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';
import 'package:odtrack_academia/shared/widgets/enhanced_form.dart';
import 'package:odtrack_academia/shared/widgets/enhanced_form_field.dart';
import 'package:odtrack_academia/shared/widgets/enhanced_error_dialog.dart';
import 'package:odtrack_academia/utils/form_validators.dart';

/// Enhanced version of the OD request screen with improved validation and error handling
class EnhancedNewOdScreen extends ConsumerStatefulWidget {
  const EnhancedNewOdScreen({super.key});

  @override
  ConsumerState<EnhancedNewOdScreen> createState() => _EnhancedNewOdScreenState();
}

class _EnhancedNewOdScreenState extends ConsumerState<EnhancedNewOdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _selectedDate;
  int? _selectedPeriod;
  StaffMember? _designatedStaff;
  bool _isSubmitting = false;
  BaseError? _formError;
  final List<String> _validationErrors = [];

  final List<String> _periods = [
    '1st Period (9:00 - 10:00)',
    '2nd Period (10:00 - 11:00)',
    '3rd Period (11:15 - 12:15 PM)',
    '4th Period (12:15 PM - 1:15 PM)',
    '5th Period (2:15 PM - 3:15 PM)',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _updateDesignatedStaff() {
    if (_selectedDate == null || _selectedPeriod == null) {
      setState(() => _designatedStaff = null);
      return;
    }

    // Validate weekday
    final weekdayError = FormValidators.weekday(_selectedDate, fieldName: 'Selected date');
    if (weekdayError != null) {
      setState(() => _designatedStaff = null);
      _showWeekendError();
      return;
    }

    final day = TimetableData.days[_selectedDate!.weekday - 1];
    final user = ref.read(authProvider).user!;
    
    // Find the student's exact timetable by matching both year and section
    final studentTimetable = TimetableData.allTimetables.firstWhere(
      (t) => t.year == user.year && t.section == user.section,
      orElse: () => TimetableData.allTimetables.firstWhere(
        (t) => t.year == user.year,
        orElse: () => TimetableData.allTimetables.first,
      ),
    );

    final schedule = studentTimetable.schedule[day];
    if (schedule != null && schedule.length >= _selectedPeriod!) {
      final slot = schedule[_selectedPeriod! - 1];
      if (slot.staffId != null) {
        try {
          final staff = StaffData.allStaff.firstWhere((s) => s.id == slot.staffId);
          setState(() {
            _designatedStaff = staff;
          });
          
          _showStaffFoundSuccess(staff, slot.subject);
        } catch (e) {
          setState(() => _designatedStaff = null);
          _showNoStaffWarning(slot.subject);
        }
      } else {
        setState(() => _designatedStaff = null);
        _showNoStaffWarning(slot.subject);
      }
    } else {
      setState(() => _designatedStaff = null);
      _showNoStaffWarning('Free');
    }
  }

  void _showStaffFoundSuccess(StaffMember staff, String subject) {
    final day = TimetableData.days[_selectedDate!.weekday - 1];
    final periodTime = TimetableData.periods[_selectedPeriod! - 1];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(MdiIcons.accountTie, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Staff Found: ${staff.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$day, $periodTime - $subject'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNoStaffWarning(String subject) {
    final error = ValidationError(
      code: 'NO_STAFF_ASSIGNED',
      message: 'No staff assigned for selected period',
      userMessage: subject == 'Free' 
          ? 'This is a free period. You may still submit the request.'
          : 'No staff is assigned for this subject. Please verify your selection.',
      field: 'period',
      severity: subject == 'Free' ? ErrorSeverity.low : ErrorSeverity.medium,
    );
    
    ErrorSnackBar.show(context, error);
  }

  void _showWeekendError() {
    final error = ValidationError(
      code: 'WEEKEND_SELECTED',
      message: 'Weekend date selected',
      userMessage: 'Classes are not scheduled on weekends. Please select a weekday.',
      field: 'date',
      severity: ErrorSeverity.medium,
    );
    
    ErrorSnackBar.show(context, error);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _getNextWeekday(DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (DateTime date) {
        // Only allow weekdays (Monday = 1, Friday = 5)
        return date.weekday >= 1 && date.weekday <= 5;
      },
      helpText: 'Select OD Date',
      errorFormatText: 'Invalid date format',
      errorInvalidText: 'Date is out of range',
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
        _updateDesignatedStaff();
      });
    }
  }

  DateTime _getNextWeekday(DateTime date) {
    DateTime nextDay = date.add(const Duration(days: 1));
    while (nextDay.weekday > 5) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    return nextDay;
  }

  void _validateForm() {
    _validationErrors.clear();
    
    // Validate date selection
    if (_selectedDate == null) {
      _validationErrors.add('Please select a date for your OD request');
    } else {
      final futureDateError = FormValidators.futureDate(_selectedDate, fieldName: 'OD date');
      if (futureDateError != null) {
        _validationErrors.add(futureDateError);
      }
      
      final weekdayError = FormValidators.weekday(_selectedDate, fieldName: 'OD date');
      if (weekdayError != null) {
        _validationErrors.add(weekdayError);
      }
    }
    
    // Validate period selection
    if (_selectedPeriod == null) {
      _validationErrors.add('Please select a period for your OD request');
    }
    
    // Validate reason
    final reasonError = FormValidators.odReason(_reasonController.text);
    if (reasonError != null) {
      _validationErrors.add(reasonError);
    }
    
    setState(() {});
  }

  Future<void> _submitRequest() async {
    // Clear previous errors
    setState(() {
      _formError = null;
      _isSubmitting = true;
    });

    try {
      // Validate form
      _validateForm();
      
      if (!_formKey.currentState!.validate() || _validationErrors.isNotEmpty) {
        setState(() => _isSubmitting = false);
        return;
      }

      final user = ref.read(authProvider).user!;
      final request = ODRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: user.id,
        studentName: user.name,
        registerNumber: user.registerNumber!,
        date: _selectedDate!,
        periods: [_selectedPeriod!],
        reason: _reasonController.text.trim(),
        status: 'pending',
        staffId: _designatedStaff?.id,
        createdAt: DateTime.now(),
      );

      await ref.read(odRequestProvider.notifier).createRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OD request submitted successfully!',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _formError = BaseError(
          category: ErrorCategory.unknown,
          code: 'SUBMISSION_FAILED',
          message: 'Failed to submit OD request: ${e.toString()}',
          userMessage: 'Unable to submit your request. Please check your connection and try again.',
          isRetryable: true,
          severity: ErrorSeverity.high,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New OD Request'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: EnhancedForm(
        formKey: _formKey,
        onSubmit: _submitRequest,
        isSubmitting: _isSubmitting,
        error: _formError,
        onRetry: _submitRequest,
        submitButtonText: 'Submit OD Request',
        submitButtonIcon: Icons.send,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Validation errors summary
            if (_validationErrors.isNotEmpty)
              FormValidationSummary(
                errors: _validationErrors,
                onDismiss: () => setState(() => _validationErrors.clear()),
              ),
            
            // Date selection section
            FormSection(
              title: 'Request Details',
              child: Column(
                children: [
                  FormFieldWrapper(
                    label: 'OD Date',
                    required: true,
                    child: EnhancedFormField(
                      controller: _dateController,
                      hint: 'Select date for OD',
                      prefixIcon: Icons.calendar_today,
                      readOnly: true,
                      onTap: _selectDate,
                      validators: [
                        RequiredValidator(fieldName: 'OD date'),
                      ],
                      helpText: 'Select a weekday within the next 30 days',
                    ),
                  ),
                  
                  FormFieldWrapper(
                    label: 'Period',
                    required: true,
                    child: _buildPeriodSelection(),
                  ),
                ],
              ),
            ),
            
            // Staff information section
            if (_designatedStaff != null)
              FormSection(
                title: 'Designated Staff',
                child: _buildStaffInfoCard(),
              ),
            
            // Reason section
            FormSection(
              title: 'Reason for OD',
              child: FormFieldWrapper(
                label: 'Detailed Reason',
                required: true,
                child: EnhancedFormField(
                  controller: _reasonController,
                  hint: 'Enter the reason for your OD request...',
                  prefixIcon: Icons.description,
                  maxLines: 4,
                  maxLength: 500,
                  validators: [ODReasonValidator()],
                  helpText: 'Provide a genuine and detailed reason (minimum 10 characters)',
                ),
              ),
            ),
            
            // Attachment section (placeholder)
            FormSection(
              title: 'Supporting Document (Optional)',
              showDivider: false,
              child: _buildAttachmentSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: List.generate(_periods.length, (index) {
            final periodIndex = index + 1;
            return ChoiceChip(
              label: Text(_periods[index]),
              selected: _selectedPeriod == periodIndex,
              onSelected: (isSelected) {
                setState(() {
                  _selectedPeriod = isSelected ? periodIndex : null;
                  _updateDesignatedStaff();
                });
              },
            );
          }),
        ),
        
        if (_selectedPeriod == null) ...[
          const SizedBox(height: 8),
          Text(
            'Please select a period for your OD request',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStaffInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.0,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                _designatedStaff!.name.split(' ').map((n) => n[0]).take(2).join(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _designatedStaff!.name,
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  if (_designatedStaff!.designation != null)
                    Text(
                      _designatedStaff!.designation!,
                      style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => StaffDirectoryScreen(
                      preFilterStaffId: _designatedStaff!.id,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person, size: 16),
              label: const Text('View Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return InkWell(
      onTap: () {
        // TODO: Implement file picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File upload feature coming soon'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              MdiIcons.fileUploadOutline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to upload supporting document',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, JPG, PNG (Max 2MB)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}