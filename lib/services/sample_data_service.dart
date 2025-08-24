import 'dart:math';
import 'package:hive/hive.dart';
import 'package:odtrack_academia/models/staff_member.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/user.dart';
import 'package:odtrack_academia/features/staff_directory/data/staff_data.dart';
import 'package:odtrack_academia/features/timetable/data/timetable_data.dart' as t_data;
import 'package:odtrack_academia/core/constants/app_constants.dart';

/// Service to populate sample data for analytics dashboard
class SampleDataService {
  static const String _staffMembersBoxName = 'staff_members';
  static const String _workloadDataBoxName = 'staff_workload_data';
  static const String _odRequestsBoxName = 'od_requests';
  static String get _usersBoxName => AppConstants.userBox;

  final Random _random = Random();

  /// Initialize and populate sample data
  Future<void> initializeSampleData() async {
    await clearSampleData(); // Clear existing data to ensure fresh population
    await _populateStaffMembers();
    await _populateWorkloadData();
    await _populateODRequests();
    // await _populateUsers();
  }

  /// Populate sample staff members
  Future<void> _populateStaffMembers() async {
    Box<StaffMember> box;
    if (Hive.isBoxOpen(_staffMembersBoxName)) {
      box = Hive.box<StaffMember>(_staffMembersBoxName);
    } else {
      box = await Hive.openBox<StaffMember>(_staffMembersBoxName);
    }
    
    if (box.isNotEmpty) return; // Data already exists

    final sampleStaff = StaffData.allStaff;

    for (final staff in sampleStaff) {
      await box.put(staff.id, staff);
    }
  }

  /// Populate sample workload data
  Future<void> _populateWorkloadData() async {
    Box<StaffWorkloadData> box;
    if (Hive.isBoxOpen(_workloadDataBoxName)) {
      box = Hive.box<StaffWorkloadData>(_workloadDataBoxName);
    } else {
      box = await Hive.openBox<StaffWorkloadData>(_workloadDataBoxName);
    }
    
    if (box.isNotEmpty) return; // Data already exists

    final staffIds = StaffData.allStaff.map((s) => s.id).toList();
    final semesters = ['current', 'previous', 'previous-2'];

    for (final staffId in staffIds) {
      for (final semester in semesters) {
        final periodsPerSubject = <String, int>{};
        final classesPerGrade = <String, List<String>>{};
        final weeklySchedule = <String, List<Period>>{};
        
        // Build schedule from timetable data
        for (final timetable in t_data.TimetableData.allTimetables) {
          for (final day in timetable.schedule.keys) {
            final periods = timetable.schedule[day]!;
            for (int i = 0; i < periods.length; i++) {
              final periodSlot = periods[i];
              if (periodSlot.staffId == staffId) {
                final subject = periodSlot.subject;
                final grade = _parseGradeFromYear(timetable.year);
                final className = timetable.section;

                // Update periods per subject
                periodsPerSubject[subject] = (periodsPerSubject[subject] ?? 0) + 1;

                // Update classes per grade
                if (!classesPerGrade.containsKey(grade.toString().split('.').last)) {
                  classesPerGrade[grade.toString().split('.').last] = [];
                }
                if (!classesPerGrade[grade.toString().split('.').last]!.contains(className)) {
                  classesPerGrade[grade.toString().split('.').last]!.add(className);
                }

                // Add to weekly schedule
                if (!weeklySchedule.containsKey(day)) {
                  weeklySchedule[day] = [];
                }
                weeklySchedule[day]!.add(Period(
                  id: 'period_${staffId}_${day}_$i',
                  subjectCode: subject,
                  className: className,
                  grade: grade,
                  timeSlot: TimeSlot(
                    periodNumber: i + 1,
                    startTime: DateTime.now().add(Duration(hours: 9 + i)),
                    endTime: DateTime.now().add(Duration(hours: 10 + i)),
                    durationMinutes: 60,
                  ),
                  type: PeriodType.regular,
                  studentCount: 25 + _random.nextInt(20), // 25-44 students
                  date: DateTime.now(),
                ));
              }
            }
          }
        }

        // Calculate total working hours and activity breakdown
        final totalPeriods = periodsPerSubject.values.fold<int>(0, (sum, periods) => sum + periods);
        final totalWorkingHours = totalPeriods * 1.0 + // Teaching hours
                                 totalPeriods * 0.5 + // Preparation
                                 totalPeriods * 0.3 + // Evaluation
                                 5.0 + // Administrative
                                 2.0 + // OD Processing
                                 3.0;  // Meetings

        final activityBreakdown = <String, double>{};
        activityBreakdown['teaching'] = totalPeriods * 1.0;
        activityBreakdown['preparation'] = totalPeriods * 0.5;
        activityBreakdown['evaluation'] = totalPeriods * 0.3;
        activityBreakdown['administrative'] = 5.0;
        activityBreakdown['od_processing'] = 2.0;
        activityBreakdown['meetings'] = 3.0;
        activityBreakdown['other'] = 1.0 + _random.nextDouble() * 2.0;

        final workloadData = StaffWorkloadData(
          staffId: staffId,
          semester: semester,
          periodsPerSubject: periodsPerSubject,
          classesPerGrade: classesPerGrade,
          weeklySchedule: weeklySchedule,
          totalWorkingHours: totalWorkingHours,
          activityBreakdown: activityBreakdown,
        );

        await box.put('${staffId}_$semester', workloadData);
      }
    }
  }

  /// Populate sample OD requests
  Future<void> _populateODRequests() async {
    Box<ODRequest> box;
    if (Hive.isBoxOpen(_odRequestsBoxName)) {
      box = Hive.box<ODRequest>(_odRequestsBoxName);
    } else {
      box = await Hive.openBox<ODRequest>(_odRequestsBoxName);
    }
    
    if (box.isNotEmpty) return; // Data already exists

    final staffIds = StaffData.allStaff.map((s) => s.id).toList();
    final statuses = ['pending', 'approved', 'rejected'];
    final reasons = [
      'Medical appointment',
      'Family function',
      'Personal work',
      'Interview',
      'Emergency',
      'Travel',
      'Conference',
      'Workshop',
    ];

    // Generate 50-100 OD requests over the last 6 months
    final requestCount = 50 + _random.nextInt(51);
    
    for (int i = 0; i < requestCount; i++) {
      final staffId = staffIds[_random.nextInt(staffIds.length)];
      final status = statuses[_random.nextInt(statuses.length)];
      final reason = reasons[_random.nextInt(reasons.length)];
      final createdAt = DateTime.now().subtract(Duration(days: _random.nextInt(180)));
      final date = createdAt.add(Duration(days: _random.nextInt(30)));
      
      final request = ODRequest(
        id: 'od_${i.toString().padLeft(3, '0')}',
        studentId: 'student_${i.toString().padLeft(3, '0')}',
        studentName: _generateStudentName(),
        registerNumber: '20CS${(100 + i).toString()}',
        date: date,
        periods: _generateRandomPeriods(),
        reason: reason,
        status: status,
        attachmentUrl: _random.nextBool() ? 'https://example.com/attachment_$i.pdf' : null,
        createdAt: createdAt,
        approvedAt: status != 'pending' ? createdAt.add(Duration(hours: 1 + _random.nextInt(48))) : null,
        approvedBy: status != 'pending' ? staffId : null,
        rejectionReason: status == 'rejected' ? 'Insufficient documentation' : null,
        staffId: staffId,
      );

      await box.put(request.id, request);
    }
  }

  /// Populate sample users
  // Future<void> _populateUsers() async {
  //   // Check if the box is already open, if not open it
  //   Box<User> box;
  //   if (Hive.isBoxOpen(_usersBoxName)) {
  //     box = Hive.box<User>(_usersBoxName);
  //   } else {
  //     box = await Hive.openBox<User>(_usersBoxName);
  //   }
  //
  //   if (box.isNotEmpty) return; // Data already exists
  //
  //   // Add staff users from StaffData
  //   final staffUsers = StaffData.allStaff.map((staff) => User(
  //     id: staff.id,
  //     name: staff.name,
  //     email: staff.email,
  //     role: 'staff',
  //     department: staff.department,
  //   )).toList();
  //
  //   for (final user in staffUsers) {
  //     await box.put(user.id, user);
  //   }
  //
  //   // Add some student users for testing
  //   for (int i = 0; i < 20; i++) {
  //     final user = User(
  //       id: 'student_${i.toString().padLeft(3, '0')}',
  //       name: _generateStudentName(),
  //       email: 'student${i.toString().padLeft(3, '0')}@college.edu',
  //       role: 'student',
  //       registerNumber: '20CS${(100 + i).toString()}',
  //       department: 'Computer Science',
  //       year: '${1 + _random.nextInt(4)}',
  //       section: String.fromCharCode(65 + _random.nextInt(3)), // A, B, C
  //     );
  //     await box.put(user.id, user);
  //   }
  // }

  /// Helper methods
  Grade _parseGradeFromYear(String year) {
    switch (year) {
      case '1st Year': return Grade.grade1;
      case '2nd Year': return Grade.grade2;
      case '3rd Year': return Grade.grade3;
      case '4th Year': return Grade.grade4;
      default: return Grade.grade1;
    }
  }

  String _generateStudentName() {
    final firstNames = ['Aarav', 'Vivaan', 'Aditya', 'Vihaan', 'Arjun', 'Sai', 'Reyansh', 'Ayaan', 'Krishna', 'Ishaan',
                       'Ananya', 'Diya', 'Priya', 'Kavya', 'Aanya', 'Ira', 'Pihu', 'Riya', 'Anvi', 'Tara'];
    final lastNames = ['Sharma', 'Patel', 'Kumar', 'Singh', 'Reddy', 'Gupta', 'Agarwal', 'Jain', 'Mehta', 'Shah'];
    
    final firstName = firstNames[_random.nextInt(firstNames.length)];
    final lastName = lastNames[_random.nextInt(lastNames.length)];
    
    return '$firstName $lastName';
  }

  List<int> _generateRandomPeriods() {
    final periodCount = 1 + _random.nextInt(4); // 1-4 periods
    final periods = <int>[];
    
    for (int i = 0; i < periodCount; i++) {
      int period;
      do {
        period = 1 + _random.nextInt(8); // Periods 1-8
      } while (periods.contains(period));
      periods.add(period);
    }
    
    periods.sort();
    return periods;
  }

  /// Clear all sample data (useful for testing)
  Future<void> clearSampleData() async {
    final boxConfigs = [
      {'name': _staffMembersBoxName, 'type': 'StaffMember'},
      {'name': _workloadDataBoxName, 'type': 'StaffWorkloadData'},
      {'name': _odRequestsBoxName, 'type': 'ODRequest'},
      {'name': _usersBoxName, 'type': 'User'},
    ];

    for (final config in boxConfigs) {
      try {
        final boxName = config['name']!;
        final boxType = config['type']!;
        
        Box<dynamic> box;
        if (Hive.isBoxOpen(boxName)) {
          switch (boxType) {
            case 'StaffMember':
              box = Hive.box<StaffMember>(boxName);
              break;
            case 'StaffWorkloadData':
              box = Hive.box<StaffWorkloadData>(boxName);
              break;
            case 'ODRequest':
              box = Hive.box<ODRequest>(boxName);
              break;
            case 'User':
              box = Hive.box<User>(boxName);
              break;
            default:
              box = Hive.box(boxName);
          }
        } else {
          switch (boxType) {
            case 'StaffMember':
              box = await Hive.openBox<StaffMember>(boxName);
              break;
            case 'StaffWorkloadData':
              box = await Hive.openBox<StaffWorkloadData>(boxName);
              break;
            case 'ODRequest':
              box = await Hive.openBox<ODRequest>(boxName);
              break;
            case 'User':
              box = await Hive.openBox<User>(boxName);
              break;
            default:
              box = await Hive.openBox(boxName);
          }
        }
        await box.clear();
      } catch (e) {
        // Box might not exist, ignore
      }
    }
  }

  /// Check if sample data exists
  Future<bool> hasSampleData() async {
    try {
      Box<StaffMember> box;
      if (Hive.isBoxOpen(_staffMembersBoxName)) {
        box = Hive.box<StaffMember>(_staffMembersBoxName);
      } else {
        box = await Hive.openBox<StaffMember>(_staffMembersBoxName);
      }
      return box.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
