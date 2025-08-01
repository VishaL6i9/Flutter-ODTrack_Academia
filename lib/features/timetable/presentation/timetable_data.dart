import 'package:flutter/material.dart';

class Timetable {
  final String year;
  final String section;
  final Map<String, List<String>> schedule;

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
      year: '1st Year',
      section: 'General - Section A',
      schedule: {
        'Monday': ['Math', 'Physics', 'Chem', 'Eng', 'LUNCH', 'Drawing', 'Lab', 'Lab'],
        'Tuesday': ['Physics', 'Math', 'Eng', 'Chem', 'LUNCH', 'Drawing', 'Free', 'Free'],
        'Wednesday': ['Chem', 'Eng', 'Math', 'Physics', 'LUNCH', 'Lab', 'Lab', 'Lab'],
        'Thursday': ['Eng', 'Chem', 'Drawing', 'Math', 'LUNCH', 'Physics', 'Free', 'Free'],
        'Friday': ['Drawing', 'Physics', 'Chem', 'Eng', 'LUNCH', 'Math', 'Free', 'Free'],
      },
    ),
    const Timetable(
      year: '3rd Year',
      section: 'Computer Science - Section A',
      schedule: {
        'Monday': ['DSA', 'DBMS', 'OS', 'CN', 'LUNCH', 'SE', 'Lab', 'Lab'],
        'Tuesday': ['DBMS', 'DSA', 'CN', 'OS', 'LUNCH', 'SE', 'Free', 'Free'],
        'Wednesday': ['OS', 'CN', 'DSA', 'DBMS', 'LUNCH', 'Lab', 'Lab', 'Lab'],
        'Thursday': ['CN', 'OS', 'SE', 'DSA', 'LUNCH', 'DBMS', 'Free', 'Free'],
        'Friday': ['SE', 'DBMS', 'OS', 'CN', 'LUNCH', 'DSA', 'Free', 'Free'],
      },
    ),
    const Timetable(
      year: '2nd Year',
      section: 'Computer Science - Section B',
      schedule: {
        'Monday': ['Math', 'Physics', 'Chem', 'Eng', 'LUNCH', 'Bio', 'Lab', 'Lab'],
        'Tuesday': ['Physics', 'Math', 'Eng', 'Chem', 'LUNCH', 'Bio', 'Free', 'Free'],
        'Wednesday': ['Chem', 'Eng', 'Math', 'Physics', 'LUNCH', 'Lab', 'Lab', 'Lab'],
        'Thursday': ['Eng', 'Chem', 'Bio', 'Math', 'LUNCH', 'Physics', 'Free', 'Free'],
        'Friday': ['Bio', 'Physics', 'Chem', 'Eng', 'LUNCH', 'Math', 'Free', 'Free'],
      },
    ),
    const Timetable(
      year: '4th Year',
      section: 'Information Technology - Section A',
      schedule: {
        'Monday': ['AI', 'ML', 'Cloud', 'DevOps', 'LUNCH', 'Cyber', 'Project', 'Project'],
        'Tuesday': ['ML', 'AI', 'DevOps', 'Cloud', 'LUNCH', 'Cyber', 'Free', 'Free'],
        'Wednesday': ['Cloud', 'DevOps', 'AI', 'ML', 'LUNCH', 'Project', 'Project', 'Project'],
        'Thursday': ['DevOps', 'Cloud', 'Cyber', 'AI', 'LUNCH', 'ML', 'Free', 'Free'],
        'Friday': ['Cyber', 'ML', 'Cloud', 'DevOps', 'LUNCH', 'AI', 'Free', 'Free'],
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
