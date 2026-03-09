import 'package:flutter/material.dart';
import 'package:odtrack_academia/models/timetable.dart';
import 'package:odtrack_academia/models/period_slot.dart';

class TimetableData {
  static final Map<String, String> subjectCodeMap = {
    'DSA': 'Data Structures and Algorithms',
    'DBMS': 'Database Management Systems',
    'OS': 'Operating Systems',
    'CN': 'Computer Networks',
    'SE': 'Software Engineering',
    'AI': 'Artificial Intelligence',
    'ML': 'Machine Learning',
    'OOP': 'Object Oriented Programming',
    'Discrete': 'Discrete Mathematics',
    'Math': 'Mathematics',
    'Physics': 'Applied Physics',
    'Chem': 'Engineering Chemistry',
    'Eng': 'Professional English',
    'Drawing': 'Engineering Drawing',
    'Web': 'Web Development',
    'Cloud': 'Cloud Computing',
    'Cyber': 'Cyber Security',
    'Project': 'Final Year Project',
    'DevOps': 'Development Operations',
  };

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
      year: '2nd Year',
      section: 'A',
      schedule: {
        'Monday': [
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'Math'),
          PeriodSlot(subject: 'Free'),
          PeriodSlot(subject: 'Physics'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Tuesday': [
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'OS'),
          PeriodSlot(subject: 'Free'),
          PeriodSlot(subject: 'Lab'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Wednesday': [
          PeriodSlot(subject: 'Math'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'Free'),
          PeriodSlot(subject: 'SE'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Thursday': [
          PeriodSlot(subject: 'OS'),
          PeriodSlot(subject: 'DBMS', staffId: 'S002'),
          PeriodSlot(subject: 'Free'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Friday': [
          PeriodSlot(subject: 'Free'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'Math'),
          PeriodSlot(subject: 'SE'),
          PeriodSlot(subject: 'LUNCH'),
        ],
      },
    ),
    const Timetable(
      year: '3rd Year',
      section: 'A',
      schedule: {
        'Monday': [
          PeriodSlot(subject: 'CN', staffId: 'S003'),
          PeriodSlot(subject: 'DBMS', staffId: 'S002'),
          PeriodSlot(subject: 'Free'),
          PeriodSlot(subject: 'AI'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Tuesday': [
          PeriodSlot(subject: 'DBMS', staffId: 'S002'),
          PeriodSlot(subject: 'CN', staffId: 'S003'),
          PeriodSlot(subject: 'Free'),
          PeriodSlot(subject: 'ML'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Wednesday': [
          PeriodSlot(subject: 'AI'),
          PeriodSlot(subject: 'DBMS', staffId: 'S002'),
          PeriodSlot(subject: 'Free'),
          PeriodSlot(subject: 'Cyber'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Thursday': [
          PeriodSlot(subject: 'ML'),
          PeriodSlot(subject: 'Cyber'),
          PeriodSlot(subject: 'Free'),
          PeriodSlot(subject: 'CN', staffId: 'S003'),
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
      // Core CS subjects
      'DSA': Colors.blue,
      'DBMS': Colors.green,
      'OS': Colors.orange,
      'CN': Colors.purple,
      'SE': Colors.teal,
      'OOP': Colors.indigo,
      'Discrete': Colors.cyan,
      
      // Basic subjects
      'Math': Colors.blue.shade700,
      'Physics': Colors.green.shade700,
      'Chem': Colors.orange.shade700,
      'Eng': Colors.purple.shade700,
      'Drawing': Colors.teal.shade700,
      'Bio': Colors.red.shade700,
      
      // Advanced subjects
      'AI': Colors.deepPurple,
      'ML': Colors.lightGreen,
      'Cloud': Colors.lightBlue,
      'DevOps': Colors.deepOrange,
      'Cyber': Colors.red,
      'Project': Colors.brown,
      'Web': Colors.pink,
      
      // Special
      'Lab': Colors.amber,
      'LUNCH': Colors.grey,
      'Free': Colors.grey.shade300,
    };
    
    return colors[subject] ?? Colors.grey;
  }
}
