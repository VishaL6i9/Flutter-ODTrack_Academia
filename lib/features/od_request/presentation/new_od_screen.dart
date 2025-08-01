import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/features/staff_directory/data/staff_data.dart';
import 'package:odtrack_academia/features/staff_directory/presentation/staff_directory_screen.dart';
import 'package:odtrack_academia/features/timetable/data/timetable_data.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/staff_member.dart';
import 'package:odtrack_academia/providers/od_request_provider.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';

class NewOdScreen extends ConsumerStatefulWidget {
  const NewOdScreen({super.key});

  @override
  ConsumerState<NewOdScreen> createState() => _NewOdScreenState();
}

class _NewOdScreenState extends ConsumerState<NewOdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  DateTime? _selectedDate;
  int? _selectedPeriod;
  StaffMember? _designatedStaff;
  bool _isSubmitting = false;

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
    super.dispose();
  }

  void _updateDesignatedStaff() {
    if (_selectedDate == null || _selectedPeriod == null) {
      setState(() => _designatedStaff = null);
      return;
    }

    final day = TimetableData.days[_selectedDate!.weekday - 1];
    final user = ref.read(authProvider).user!;
    // This is a placeholder for getting the student's timetable.
    // In a real app, you'd look up the student's specific section.
    final studentTimetable = TimetableData.allTimetables.firstWhere(
      (t) => t.year == user.year,
      orElse: () => TimetableData.allTimetables.first,
    );

    final schedule = studentTimetable.schedule[day];
    if (schedule != null && schedule.length >= _selectedPeriod!) {
      final slot = schedule[_selectedPeriod! - 1];
      if (slot.staffId != null) {
        setState(() {
          _designatedStaff = StaffData.allStaff.firstWhere((s) => s.id == slot.staffId);
        });
      } else {
        setState(() => _designatedStaff = null);
      }
    } else {
      setState(() => _designatedStaff = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New OD Request'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSelection(),
              const SizedBox(height: 24),
              _buildPeriodSelection(),
              if (_designatedStaff != null) ...[
                const SizedBox(height: 24),
                _buildStaffInfoSection(),
              ],
              const SizedBox(height: 24),
              _buildReasonField(),
              const SizedBox(height: 24),
              _buildAttachmentSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Select date for OD',
                  style: TextStyle(color: _selectedDate != null ? null : Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Period', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
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
      ],
    );
  }

  Widget _buildStaffInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Designated Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
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
                TextButton(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => const StaffDirectoryScreen(), // Simplified navigation
                      ),
                    );
                  },
                  child: const Text('View Profile'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Reason for OD',
        hintText: 'Enter the reason for your OD request...',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a reason for your OD request';
        }
        if (value.trim().length < 10) {
          return 'Please provide a more detailed reason (at least 10 characters)';
        }
        return null;
      },
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attachment (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(MdiIcons.fileUploadOutline, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text('Tap to upload supporting document', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text('PDF, JPG, PNG (Max 2MB)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        child: _isSubmitting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Submit OD Request'),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDesignatedStaff();
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a period'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
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
          const SnackBar(content: Text('OD request submitted successfully!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
