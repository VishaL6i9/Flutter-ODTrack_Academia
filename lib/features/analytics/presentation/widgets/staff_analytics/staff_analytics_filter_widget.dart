import 'package:flutter/material.dart';
import 'package:odtrack_academia/core/theme/app_theme.dart';
import 'package:odtrack_academia/models/analytics_models.dart';

/// Widget for filtering staff analytics data
class StaffAnalyticsFilterWidget extends StatefulWidget {
  final DateRange currentDateRange;
  final String currentSemester;
  final void Function(DateRange) onDateRangeChanged;
  final void Function(String) onSemesterChanged;

  const StaffAnalyticsFilterWidget({
    super.key,
    required this.currentDateRange,
    required this.currentSemester,
    required this.onDateRangeChanged,
    required this.onSemesterChanged,
  });

  @override
  State<StaffAnalyticsFilterWidget> createState() => _StaffAnalyticsFilterWidgetState();
}

class _StaffAnalyticsFilterWidgetState extends State<StaffAnalyticsFilterWidget> {
  late DateRange _selectedDateRange;
  late String _selectedSemester;
  
  final List<String> _availableSemesters = [
    'current',
    'previous',
    'previous-2',
    'spring-2024',
    'fall-2023',
    'spring-2023',
    'fall-2022',
  ];

  final List<DateRangePreset> _dateRangePresets = [
    DateRangePreset(
      name: 'Last 30 Days',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    ),
    DateRangePreset(
      name: 'Last 3 Months',
      startDate: DateTime.now().subtract(const Duration(days: 90)),
      endDate: DateTime.now(),
    ),
    DateRangePreset(
      name: 'Last 6 Months',
      startDate: DateTime.now().subtract(const Duration(days: 180)),
      endDate: DateTime.now(),
    ),
    DateRangePreset(
      name: 'Last Year',
      startDate: DateTime.now().subtract(const Duration(days: 365)),
      endDate: DateTime.now(),
    ),
    DateRangePreset(
      name: 'Current Academic Year',
      startDate: DateTime(DateTime.now().year, 8, 1), // August 1st
      endDate: DateTime(DateTime.now().year + 1, 7, 31), // July 31st
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateRange = widget.currentDateRange;
    _selectedSemester = widget.currentSemester;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Filter Analytics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Date Range Section
            _buildDateRangeSection(),
            const SizedBox(height: 24),
            
            // Semester Selection Section
            _buildSemesterSection(),
            const SizedBox(height: 32),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Date Range Presets
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _dateRangePresets.map((preset) {
            final isSelected = _isDateRangePresetSelected(preset);
            return FilterChip(
              label: Text(preset.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDateRange = DateRange(
                      startDate: preset.startDate,
                      endDate: preset.endDate,
                    );
                  });
                }
              },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryColor,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        
        // Custom Date Range
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Custom Date Range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      'Start Date',
                      _selectedDateRange.startDate,
                      (DateTime date) {
                        setState(() {
                          _selectedDateRange = DateRange(
                            startDate: date,
                            endDate: _selectedDateRange.endDate,
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      'End Date',
                      _selectedDateRange.endDate,
                      (DateTime date) {
                        setState(() {
                          _selectedDateRange = DateRange(
                            startDate: _selectedDateRange.startDate,
                            endDate: date,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, void Function(DateTime) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (selectedDate != null) {
              onChanged(selectedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Semester',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSemester,
              isExpanded: true,
              items: _availableSemesters.map((semester) {
                return DropdownMenuItem<String>(
                  value: semester,
                  child: Text(_getSemesterDisplayName(semester)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSemester = value;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the semester for teaching analytics and comparative analysis',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedDateRange = DateRange(
                  startDate: DateTime.now().subtract(const Duration(days: 180)),
                  endDate: DateTime.now(),
                );
                _selectedSemester = 'current';
              });
            },
            child: const Text('Reset'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              widget.onDateRangeChanged(_selectedDateRange);
              widget.onSemesterChanged(_selectedSemester);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply Filters'),
          ),
        ),
      ],
    );
  }

  bool _isDateRangePresetSelected(DateRangePreset preset) {
    return _selectedDateRange.startDate.isAtSameMomentAs(preset.startDate) &&
           _selectedDateRange.endDate.isAtSameMomentAs(preset.endDate);
  }

  String _getSemesterDisplayName(String semester) {
    switch (semester) {
      case 'current':
        return 'Current Semester';
      case 'previous':
        return 'Previous Semester';
      case 'previous-2':
        return '2 Semesters Ago';
      case 'spring-2024':
        return 'Spring 2024';
      case 'fall-2023':
        return 'Fall 2023';
      case 'spring-2023':
        return 'Spring 2023';
      case 'fall-2022':
        return 'Fall 2022';
      default:
        return semester.toUpperCase();
    }
  }
}

/// Class for date range presets
class DateRangePreset {
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  const DateRangePreset({
    required this.name,
    required this.startDate,
    required this.endDate,
  });
}
