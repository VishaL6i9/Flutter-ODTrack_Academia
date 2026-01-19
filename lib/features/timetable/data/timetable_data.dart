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
    // 1st Year Timetables
    const Timetable(
      year: '1st Year',
      section: 'Computer Science - Section A',
      schedule: {
        'Monday': [
          PeriodSlot(subject: 'Math', staffId: 'S006'),
          PeriodSlot(subject: 'Physics', staffId: 'S007'),
          PeriodSlot(subject: 'Eng', staffId: 'S008'),
          PeriodSlot(subject: 'Drawing', staffId: 'S009'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Tuesday': [
          PeriodSlot(subject: 'Physics', staffId: 'S007'),
          PeriodSlot(subject: 'Math', staffId: 'S006'),
          PeriodSlot(subject: 'Drawing', staffId: 'S009'),
          PeriodSlot(subject: 'Eng', staffId: 'S008'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Wednesday': [
          PeriodSlot(subject: 'Eng', staffId: 'S008'),
          PeriodSlot(subject: 'Drawing', staffId: 'S009'),
          PeriodSlot(subject: 'Math', staffId: 'S006'),
          PeriodSlot(subject: 'Physics', staffId: 'S007'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Thursday': [
          PeriodSlot(subject: 'Drawing', staffId: 'S009'),
          PeriodSlot(subject: 'Eng', staffId: 'S008'),
          PeriodSlot(subject: 'Physics', staffId: 'S007'),
          PeriodSlot(subject: 'Math', staffId: 'S006'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Friday': [
          PeriodSlot(subject: 'Math', staffId: 'S006'),
          PeriodSlot(subject: 'Physics', staffId: 'S007'),
          PeriodSlot(subject: 'Eng', staffId: 'S008'),
          PeriodSlot(subject: 'Lab', staffId: 'S010'),
          PeriodSlot(subject: 'LUNCH'),
        ],
      },
    ),
    const Timetable(
      year: '1st Year',
      section: 'Computer Science - Section B',
      schedule: {
        'Monday': [
          PeriodSlot(subject: 'Physics', staffId: 'S007'),
          PeriodSlot(subject: 'Math', staffId: 'S011'),
          PeriodSlot(subject: 'Drawing', staffId: 'S009'),
          PeriodSlot(subject: 'Eng', staffId: 'S012'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Tuesday': [
          PeriodSlot(subject: 'Math', staffId: 'S011'),
          PeriodSlot(subject: 'Physics', staffId: 'S007'),
          PeriodSlot(subject: 'Eng', staffId: 'S012'),
          PeriodSlot(subject: 'Drawing', staffId: 'S009'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Wednesday': [
          PeriodSlot(subject: 'Drawing', staffId: 'S009'),
          PeriodSlot(subject: 'Eng', staffId: 'S012'),
          PeriodSlot(subject: 'Physics', staffId: 'S007'),
          PeriodSlot(subject: 'Math', staffId: 'S011'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Thursday': [
          PeriodSlot(subject: 'Eng', staffId: 'S012'),
          PeriodSlot(subject: 'Drawing', staffId: 'S009'),
          PeriodSlot(subject: 'Math', staffId: 'S011'),
          PeriodSlot(subject: 'Physics', staffId: 'S007'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Friday': [
          PeriodSlot(subject: 'Physics', staffId: 'S007'),
          PeriodSlot(subject: 'Math', staffId: 'S011'),
          PeriodSlot(subject: 'Lab', staffId: 'S010'),
          PeriodSlot(subject: 'Eng', staffId: 'S012'),
          PeriodSlot(subject: 'LUNCH'),
        ],
      },
    ),
    
    // 2nd Year Timetables
    const Timetable(
      year: '2nd Year',
      section: 'Computer Science - Section A',
      schedule: {
        'Monday': [
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'Math', staffId: 'S013'),
          PeriodSlot(subject: 'OOP', staffId: 'S014'),
          PeriodSlot(subject: 'Discrete', staffId: 'S015'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Tuesday': [
          PeriodSlot(subject: 'OOP', staffId: 'S014'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'Discrete', staffId: 'S015'),
          PeriodSlot(subject: 'Math', staffId: 'S013'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Wednesday': [
          PeriodSlot(subject: 'Discrete', staffId: 'S015'),
          PeriodSlot(subject: 'OOP', staffId: 'S014'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'Lab', staffId: 'S016'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Thursday': [
          PeriodSlot(subject: 'Math', staffId: 'S013'),
          PeriodSlot(subject: 'Discrete', staffId: 'S015'),
          PeriodSlot(subject: 'OOP', staffId: 'S014'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Friday': [
          PeriodSlot(subject: 'Lab', staffId: 'S016'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'OOP', staffId: 'S014'),
          PeriodSlot(subject: 'Math', staffId: 'S013'),
          PeriodSlot(subject: 'LUNCH'),
        ],
      },
    ),
    const Timetable(
      year: '2nd Year',
      section: 'Information Technology - Section A',
      schedule: {
        'Monday': [
          PeriodSlot(subject: 'DSA', staffId: 'S017'),
          PeriodSlot(subject: 'Web', staffId: 'S018'),
          PeriodSlot(subject: 'OOP', staffId: 'S019'),
          PeriodSlot(subject: 'Math', staffId: 'S020'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Tuesday': [
          PeriodSlot(subject: 'Web', staffId: 'S018'),
          PeriodSlot(subject: 'DSA', staffId: 'S017'),
          PeriodSlot(subject: 'Math', staffId: 'S020'),
          PeriodSlot(subject: 'OOP', staffId: 'S019'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Wednesday': [
          PeriodSlot(subject: 'OOP', staffId: 'S019'),
          PeriodSlot(subject: 'Math', staffId: 'S020'),
          PeriodSlot(subject: 'DSA', staffId: 'S017'),
          PeriodSlot(subject: 'Web', staffId: 'S018'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Thursday': [
          PeriodSlot(subject: 'Math', staffId: 'S020'),
          PeriodSlot(subject: 'OOP', staffId: 'S019'),
          PeriodSlot(subject: 'Web', staffId: 'S018'),
          PeriodSlot(subject: 'DSA', staffId: 'S017'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Friday': [
          PeriodSlot(subject: 'Lab', staffId: 'S021'),
          PeriodSlot(subject: 'Web', staffId: 'S018'),
          PeriodSlot(subject: 'DSA', staffId: 'S017'),
          PeriodSlot(subject: 'OOP', staffId: 'S019'),
          PeriodSlot(subject: 'LUNCH'),
        ],
      },
    ),

    // 3rd Year Timetables
    const Timetable(
      year: '3rd Year',
      section: 'Computer Science - Section A',
      schedule: {
        'Monday': [
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'DBMS', staffId: 'S022'),
          PeriodSlot(subject: 'OS', staffId: 'S002'),
          PeriodSlot(subject: 'CN', staffId: 'S003'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Tuesday': [
          PeriodSlot(subject: 'DBMS', staffId: 'S022'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'CN', staffId: 'S003'),
          PeriodSlot(subject: 'OS', staffId: 'S002'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Wednesday': [
          PeriodSlot(subject: 'OS', staffId: 'S002'),
          PeriodSlot(subject: 'CN', staffId: 'S003'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'DBMS', staffId: 'S022'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Thursday': [
          PeriodSlot(subject: 'CN', staffId: 'S003'),
          PeriodSlot(subject: 'OS', staffId: 'S002'),
          PeriodSlot(subject: 'SE', staffId: 'S023'),
          PeriodSlot(subject: 'DSA', staffId: 'S001'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Friday': [
          PeriodSlot(subject: 'SE', staffId: 'S023'),
          PeriodSlot(subject: 'DBMS', staffId: 'S022'),
          PeriodSlot(subject: 'OS', staffId: 'S002'),
          PeriodSlot(subject: 'CN', staffId: 'S003'),
          PeriodSlot(subject: 'LUNCH'),
        ],
      },
    ),
    const Timetable(
      year: '3rd Year',
      section: 'Computer Science - Section B',
      schedule: {
        'Monday': [
          PeriodSlot(subject: 'DBMS', staffId: 'S024'),
          PeriodSlot(subject: 'DSA', staffId: 'S017'),
          PeriodSlot(subject: 'CN', staffId: 'S025'),
          PeriodSlot(subject: 'OS', staffId: 'S026'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Tuesday': [
          PeriodSlot(subject: 'DSA', staffId: 'S017'),
          PeriodSlot(subject: 'DBMS', staffId: 'S024'),
          PeriodSlot(subject: 'OS', staffId: 'S026'),
          PeriodSlot(subject: 'CN', staffId: 'S025'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Wednesday': [
          PeriodSlot(subject: 'CN', staffId: 'S025'),
          PeriodSlot(subject: 'OS', staffId: 'S026'),
          PeriodSlot(subject: 'DBMS', staffId: 'S024'),
          PeriodSlot(subject: 'DSA', staffId: 'S017'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Thursday': [
          PeriodSlot(subject: 'OS', staffId: 'S026'),
          PeriodSlot(subject: 'CN', staffId: 'S025'),
          PeriodSlot(subject: 'SE', staffId: 'S027'),
          PeriodSlot(subject: 'DBMS', staffId: 'S024'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Friday': [
          PeriodSlot(subject: 'SE', staffId: 'S027'),
          PeriodSlot(subject: 'DSA', staffId: 'S017'),
          PeriodSlot(subject: 'CN', staffId: 'S025'),
          PeriodSlot(subject: 'OS', staffId: 'S026'),
          PeriodSlot(subject: 'LUNCH'),
        ],
      },
    ),

    // 4th Year Timetables
    const Timetable(
      year: '4th Year',
      section: 'Computer Science - Section A',
      schedule: {
        'Monday': [
          PeriodSlot(subject: 'AI', staffId: 'S028'),
          PeriodSlot(subject: 'ML', staffId: 'S029'),
          PeriodSlot(subject: 'Cyber', staffId: 'S030'),
          PeriodSlot(subject: 'Project', staffId: 'S001'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Tuesday': [
          PeriodSlot(subject: 'ML', staffId: 'S029'),
          PeriodSlot(subject: 'AI', staffId: 'S028'),
          PeriodSlot(subject: 'Project', staffId: 'S001'),
          PeriodSlot(subject: 'Cyber', staffId: 'S030'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Wednesday': [
          PeriodSlot(subject: 'Cyber', staffId: 'S030'),
          PeriodSlot(subject: 'Project', staffId: 'S001'),
          PeriodSlot(subject: 'AI', staffId: 'S028'),
          PeriodSlot(subject: 'ML', staffId: 'S029'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Thursday': [
          PeriodSlot(subject: 'Project', staffId: 'S001'),
          PeriodSlot(subject: 'Cyber', staffId: 'S030'),
          PeriodSlot(subject: 'ML', staffId: 'S029'),
          PeriodSlot(subject: 'AI', staffId: 'S028'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Friday': [
          PeriodSlot(subject: 'AI', staffId: 'S028'),
          PeriodSlot(subject: 'ML', staffId: 'S029'),
          PeriodSlot(subject: 'Cyber', staffId: 'S030'),
          PeriodSlot(subject: 'Project', staffId: 'S001'),
          PeriodSlot(subject: 'LUNCH'),
        ],
      },
    ),
    const Timetable(
      year: '4th Year',
      section: 'Information Technology - Section A',
      schedule: {
        'Monday': [
          PeriodSlot(subject: 'AI', staffId: 'S031'),
          PeriodSlot(subject: 'ML', staffId: 'S032'),
          PeriodSlot(subject: 'Cloud', staffId: 'S004'),
          PeriodSlot(subject: 'DevOps', staffId: 'S005'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Tuesday': [
          PeriodSlot(subject: 'ML', staffId: 'S032'),
          PeriodSlot(subject: 'AI', staffId: 'S031'),
          PeriodSlot(subject: 'DevOps', staffId: 'S005'),
          PeriodSlot(subject: 'Cloud', staffId: 'S004'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Wednesday': [
          PeriodSlot(subject: 'Cloud', staffId: 'S004'),
          PeriodSlot(subject: 'DevOps', staffId: 'S005'),
          PeriodSlot(subject: 'AI', staffId: 'S031'),
          PeriodSlot(subject: 'ML', staffId: 'S032'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Thursday': [
          PeriodSlot(subject: 'DevOps', staffId: 'S005'),
          PeriodSlot(subject: 'Cloud', staffId: 'S004'),
          PeriodSlot(subject: 'Cyber', staffId: 'S033'),
          PeriodSlot(subject: 'AI', staffId: 'S031'),
          PeriodSlot(subject: 'LUNCH'),
        ],
        'Friday': [
          PeriodSlot(subject: 'Cyber', staffId: 'S033'),
          PeriodSlot(subject: 'ML', staffId: 'S032'),
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
