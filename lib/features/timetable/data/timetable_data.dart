import 'package:flutter/material.dart';
import 'package:odtrack_academia/models/period_slot.dart';
import 'package:odtrack_academia/models/timetable.dart';

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

  static final List<Timetable> allTimetables = [];

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
