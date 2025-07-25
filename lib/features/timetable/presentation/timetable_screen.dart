import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  static const List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  static const List<String> _periods = [
    '9:00-9:50',
    '9:50-10:40',
    '11:00-11:50',
    '11:50-12:40',
    '1:30-2:20',
    '2:20-3:10',
    '3:30-4:20',
    '4:20-5:10',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTimetableGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(MdiIcons.timetable, size: 32, color: Colors.blue),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class Schedule',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '3rd Year Computer Science - Section A',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableGrid(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Header row with periods
            Row(
              children: [
                const SizedBox(width: 80, child: Text('')), // Empty cell for day column
                ..._periods.map((period) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      period,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )),
              ],
            ),
            const Divider(),
            // Timetable rows
            ..._days.map((day) => _buildDayRow(day)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(String day) {
    final subjects = _getDemoSubjects(day);
    
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  day.substring(0, 3),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ...subjects.map((subject) => Expanded(
              child: Container(
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getSubjectColor(subject).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getSubjectColor(subject).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  subject,
                  style: TextStyle(
                    fontSize: 10,
                    color: _getSubjectColor(subject),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )),
          ],
        ),
        if (day != _days.last) const Divider(height: 1),
      ],
    );
  }

  List<String> _getDemoSubjects(String day) {
    final Map<String, List<String>> schedule = {
      'Monday': ['DSA', 'DBMS', 'OS', 'CN', 'LUNCH', 'SE', 'Lab', 'Lab'],
      'Tuesday': ['DBMS', 'DSA', 'CN', 'OS', 'LUNCH', 'SE', 'Free', 'Free'],
      'Wednesday': ['OS', 'CN', 'DSA', 'DBMS', 'LUNCH', 'Lab', 'Lab', 'Lab'],
      'Thursday': ['CN', 'OS', 'SE', 'DSA', 'LUNCH', 'DBMS', 'Free', 'Free'],
      'Friday': ['SE', 'DBMS', 'OS', 'CN', 'LUNCH', 'DSA', 'Free', 'Free'],
    };
    
    return schedule[day] ?? List.filled(8, 'Free');
  }

  Color _getSubjectColor(String subject) {
    final Map<String, Color> colors = {
      'DSA': Colors.blue,
      'DBMS': Colors.green,
      'OS': Colors.orange,
      'CN': Colors.purple,
      'SE': Colors.teal,
      'Lab': Colors.red,
      'LUNCH': Colors.grey,
      'Free': Colors.grey.shade300,
    };
    
    return colors[subject] ?? Colors.grey;
  }
}