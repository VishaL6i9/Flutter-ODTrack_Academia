import 'package:flutter/material.dart';
import 'package:odtrack_academia/models/period_slot.dart';

class Timetable {
  final String year;
  final String section;
  final Map<String, List<PeriodSlot>> schedule;

  const Timetable({
    required this.year,
    required this.section,
    required this.schedule,
  });
}

class TimetableData {
  static final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  static final List<String> periods = [
    '9:00-10:00',
    '10:00-11:00',
    '11:15-12:15',
    '12:15-13:15',
    '14:15-15:15'
  ];

  static final List<Timetable> allTimetables = [
    const Timetable(
      year: '3rd Year',
      section: 'Computer Science - Section A',
      schedule: {
        'Monday': [
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'DBMS'),
          PeriodSlot(subject: 'OS', staffId: 'S002'),
          PeriodSlot(subject: 'CN', staffId: 'S003'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Tuesday': [
          PeriodSlot(subject: 'DBMS'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'CN', staffId: 'S003'),
          PeriodSlot(subject: 'OS', staffId: 'S002'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Wednesday': [
          PeriodSlot(subject: 'OS', staffId: 'S002'),
          PeriodSlot(subject: 'CN', staffId: 'S003'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'DBMS'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Thursday': [
          PeriodSlot(subject: 'CN', staffId: 'S003'),
          PeriodSlot(subject: 'OS', staffId: 'S002'),
          PeriodSlot(subject: 'SE'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Friday': [
          PeriodSlot(subject: 'SE'),
          PeriodSlot(subject: 'DBMS'),
          PeriodSlot(subject: 'OS', staffId: 'S002'),
          PeriodSlot(subject: 'CN', staffId: 'S003'),
          PeriodSlot(subject: 'LUNCH'),
        ],
      },
    ),
    const Timetable(
      year: '4th Year',
      section: 'Information Technology - Section A',
      schedule: {
        'Monday': [
          PeriodSlot(subject: 'AI'),
          PeriodSlot(subject: 'ML'),
          PeriodSlot(subject: 'Cloud', staffId: 'S004'),
          PeriodSlot(subject: 'DevOps', staffId: 'S005'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Tuesday': [
          PeriodSlot(subject: 'ML'),
          PeriodSlot(subject: 'AI'),
          PeriodSlot(subject: 'DevOps', staffId: 'S005'),
          PeriodSlot(subject: 'Cloud', staffId: 'S004'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Wednesday': [
          PeriodSlot(subject: 'Cloud', staffId: 'S004'),
          PeriodSlot(subject: 'DevOps', staffId: 'S005'),
          PeriodSlot(subject: 'AI'),
          PeriodSlot(subject: 'ML'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Thursday': [
          PeriodSlot(subject: 'DevOps', staffId: 'S005'),
          PeriodSlot(subject: 'Cloud', staffId: 'S004'),
          PeriodSlot(subject: 'Cyber'),
          PeriodSlot(subject: 'AI'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Friday': [
          PeriodSlot(subject: 'Cyber'),
          PeriodSlot(subject: 'ML'),
          PeriodSlot(subject: 'Cloud', staffId: 'S004'),
          PeriodSlot(subject: 'DevOps', staffId: 'S005'),
          PeriodSlot(subject: 'LUNCH'),
        ],
      },
    ),
  ];

  static Color getSubjectColor(String subject) {
    final Map<String, Color> colors = {
      'DSA': Colors.blue,
      'DBMS': Colors.green,
      'OS': Colors.orange,
      'CN': Colors.purple,
      'SE': Colors.teal,
      'Lab': Colors.red,
      'LUNCH': Colors.grey,
      'Free': Colors.grey.shade300,
      'Math': Colors.blue,
      'Physics': Colors.green,
      'Chem': Colors.orange,
      'Eng': Colors.purple,
      'Drawing': Colors.teal,
      'Bio': Colors.red,
      'AI': Colors.blue,
      'ML': Colors.green,
      'Cloud': Colors.orange,
      'DevOps': Colors.purple,
      'Cyber': Colors.teal,
      'Project': Colors.red,
    };
    
    return colors[subject] ?? Colors.grey;
  }
}
