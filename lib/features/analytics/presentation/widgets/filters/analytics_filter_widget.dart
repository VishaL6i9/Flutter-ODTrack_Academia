import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:intl/intl.dart';

/// Widget for filtering analytics data
class AnalyticsFilterWidget extends ConsumerStatefulWidget {
  final AnalyticsFilter initialFilter;
  final void Function(AnalyticsFilter) onFilterChanged;
  final List<String> availableDepartments;
  final List<String> availableYears;
  final List<String> availableStatuses;

  const AnalyticsFilterWidget({
    super.key,
    required this.initialFilter,
    required this.onFilterChanged,
    this.availableDepartments = const [],
    this.availableYears = const [],
    this.availableStatuses = const ['Pending', 'Approved', 'Rejected'],
  });

  @override
  ConsumerState<AnalyticsFilterWidget> createState() => _AnalyticsFilterWidgetState();
}

class _AnalyticsFilterWidgetState extends ConsumerState<AnalyticsFilterWidget> {
  late AnalyticsFilter _currentFilter;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear All'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => widget.onFilterChanged(_currentFilter),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFilterContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterContent() {
    return Column(
      children: [
        _buildDateRangeFilter(),
        const SizedBox(height: 16),
        _buildDepartmentFilter(),
        const SizedBox(height: 16),
        _buildYearFilter(),
        const SizedBox(height: 16),
        _buildStatusFilter(),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Start Date',
                date: _currentFilter.dateRange?.startDate,
                onDateSelected: (date) {
                  final endDate = _currentFilter.dateRange?.endDate ?? DateTime.now();
                  _updateDateRange(DateRange(startDate: date, endDate: endDate));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'End Date',
                date: _currentFilter.dateRange?.endDate,
                onDateSelected: (date) {
                  final startDate = _currentFilter.dateRange?.startDate ?? 
                      DateTime.now().subtract(const Duration(days: 30));
                  _updateDateRange(DateRange(startDate: startDate, endDate: date));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickDateButton('Last 7 days', () => _setQuickDateRange(7)),
            _buildQuickDateButton('Last 30 days', () => _setQuickDateRange(30)),
            _buildQuickDateButton('Last 90 days', () => _setQuickDateRange(90)),
            _buildQuickDateButton('This Year', _setCurrentYear),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required void Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () => _selectDate(context, date, onDateSelected),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? _dateFormat.format(date) : 'Select date',
          style: TextStyle(
            color: date != null 
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildDepartmentFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Department',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _currentFilter.department,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select department',
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Departments'),
            ),
            ...widget.availableDepartments.map((department) {
              return DropdownMenuItem<String>(
                value: department,
                child: Text(department),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _currentFilter = AnalyticsFilter(
                dateRange: _currentFilter.dateRange,
                department: value,
                year: _currentFilter.year,
                statuses: _currentFilter.statuses,
                staffId: _currentFilter.staffId,
                studentId: _currentFilter.studentId,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildYearFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Year',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _currentFilter.year,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select year',
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Years'),
            ),
            ...widget.availableYears.map((year) {
              return DropdownMenuItem<String>(
                value: year,
                child: Text(year),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _currentFilter = AnalyticsFilter(
                dateRange: _currentFilter.dateRange,
                department: _currentFilter.department,
                year: value,
                statuses: _currentFilter.statuses,
                staffId: _currentFilter.staffId,
                studentId: _currentFilter.studentId,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableStatuses.map((status) {
            final isSelected = _currentFilter.statuses?.contains(status) ?? false;
            return FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  List<String> newStatuses = List.from(_currentFilter.statuses ?? []);
                  if (selected) {
                    newStatuses.add(status);
                  } else {
                    newStatuses.remove(status);
                  }
                  
                  _currentFilter = AnalyticsFilter(
                    dateRange: _currentFilter.dateRange,
                    department: _currentFilter.department,
                    year: _currentFilter.year,
                    statuses: newStatuses.isEmpty ? null : newStatuses,
                    staffId: _currentFilter.staffId,
                    studentId: _currentFilter.studentId,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? initialDate,
    void Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  void _updateDateRange(DateRange dateRange) {
    setState(() {
      _currentFilter = AnalyticsFilter(
        dateRange: dateRange,
        department: _currentFilter.department,
        year: _currentFilter.year,
        statuses: _currentFilter.statuses,
        staffId: _currentFilter.staffId,
        studentId: _currentFilter.studentId,
      );
    });
  }

  void _setQuickDateRange(int days) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    _updateDateRange(DateRange(startDate: startDate, endDate: endDate));
  }

  void _setCurrentYear() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, 1, 1);
    final endDate = DateTime(now.year, 12, 31);
    _updateDateRange(DateRange(startDate: startDate, endDate: endDate));
  }

  void _clearFilters() {
    setState(() {
      _currentFilter = const AnalyticsFilter();
    });
  }
}