import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'staff_workload_models.g.dart';

/// Enumeration for different activity types
enum ActivityType {
  @JsonValue('teaching')
  teaching,
  @JsonValue('od_processing')
  odProcessing,
  @JsonValue('administrative')
  administrative,
  @JsonValue('meetings')
  meetings,
  @JsonValue('preparation')
  preparation,
  @JsonValue('evaluation')
  evaluation,
  @JsonValue('other')
  other,
}

/// Enumeration for academic grades
enum Grade {
  @JsonValue('grade1')
  grade1,
  @JsonValue('grade2')
  grade2,
  @JsonValue('grade3')
  grade3,
  @JsonValue('grade4')
  grade4,
  @JsonValue('grade5')
  grade5,
  @JsonValue('grade6')
  grade6,
  @JsonValue('grade7')
  grade7,
  @JsonValue('grade8')
  grade8,
  @JsonValue('grade9')
  grade9,
  @JsonValue('grade10')
  grade10,
  @JsonValue('grade11')
  grade11,
  @JsonValue('grade12')
  grade12,
  @JsonValue('post_graduate')
  postGraduate,
}

/// Enumeration for period types
enum PeriodType {
  @JsonValue('regular')
  regular,
  @JsonValue('extra')
  extra,
  @JsonValue('substitution')
  substitution,
  @JsonValue('remedial')
  remedial,
  @JsonValue('lab')
  lab,
  @JsonValue('practical')
  practical,
}

/// Enumeration for class types
enum ClassType {
  @JsonValue('regular')
  regular,
  @JsonValue('honors')
  honors,
  @JsonValue('remedial')
  remedial,
  @JsonValue('advanced')
  advanced,
  @JsonValue('special')
  special,
}

/// Enumeration for subject types
enum SubjectType {
  @JsonValue('theory')
  theory,
  @JsonValue('practical')
  practical,
  @JsonValue('lab')
  lab,
  @JsonValue('project')
  project,
  @JsonValue('seminar')
  seminar,
}

/// Enumeration for workload trend direction
enum WorkloadTrend {
  @JsonValue('increasing')
  increasing,
  @JsonValue('decreasing')
  decreasing,
  @JsonValue('stable')
  stable,
}

/// Time slot model representing a period in the timetable
@HiveType(typeId: 10)
@JsonSerializable()
class TimeSlot {
  @HiveField(0)
  final int periodNumber;
  
  @HiveField(1)
  final DateTime startTime;
  
  @HiveField(2)
  final DateTime endTime;
  
  @HiveField(3)
  final int durationMinutes;

  const TimeSlot({
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });

  Duration get duration => Duration(minutes: durationMinutes);

  factory TimeSlot.fromJson(Map<String, dynamic> json) =>
      _$TimeSlotFromJson(json);

  Map<String, dynamic> toJson() => _$TimeSlotToJson(this);
}

/// Period model representing a teaching period
@HiveType(typeId: 11)
@JsonSerializable()
class Period {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String subjectCode;
  
  @HiveField(2)
  final String className;
  
  @HiveField(3)
  @JsonKey(unknownEnumValue: Grade.grade1)
  final Grade grade;
  
  @HiveField(4)
  final TimeSlot timeSlot;
  
  @HiveField(5)
  @JsonKey(unknownEnumValue: PeriodType.regular)
  final PeriodType type;
  
  @HiveField(6)
  final int studentCount;
  
  @HiveField(7)
  final DateTime date;

  const Period({
    required this.id,
    required this.subjectCode,
    required this.className,
    required this.grade,
    required this.timeSlot,
    required this.type,
    required this.studentCount,
    required this.date,
  });

  factory Period.fromJson(Map<String, dynamic> json) =>
      _$PeriodFromJson(json);

  Map<String, dynamic> toJson() => _$PeriodToJson(this);
}

/// Subject allocation model
@HiveType(typeId: 12)
@JsonSerializable()
class SubjectAllocation {
  @HiveField(0)
  final String subjectCode;
  
  @HiveField(1)
  final String subjectName;
  
  @HiveField(2)
  final int periodsPerWeek;
  
  @HiveField(3)
  final int totalPeriods;
  
  @HiveField(4)
  final List<ClassAssignment> classAssignments;
  
  @HiveField(5)
  final double studentCount;
  
  @HiveField(6)
  @JsonKey(unknownEnumValue: SubjectType.theory)
  final SubjectType type;

  const SubjectAllocation({
    required this.subjectCode,
    required this.subjectName,
    required this.periodsPerWeek,
    required this.totalPeriods,
    required this.classAssignments,
    required this.studentCount,
    required this.type,
  });

  factory SubjectAllocation.fromJson(Map<String, dynamic> json) =>
      _$SubjectAllocationFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectAllocationToJson(this);
}

/// Class assignment model
@HiveType(typeId: 13)
@JsonSerializable()
class ClassAssignment {
  @HiveField(0)
  final String className;
  
  @HiveField(1)
  @JsonKey(unknownEnumValue: Grade.grade1)
  final Grade grade;
  
  @HiveField(2)
  final String section;
  
  @HiveField(3)
  final int studentCount;
  
  @HiveField(4)
  final int periodsAssigned;

  const ClassAssignment({
    required this.className,
    required this.grade,
    required this.section,
    required this.studentCount,
    required this.periodsAssigned,
  });

  factory ClassAssignment.fromJson(Map<String, dynamic> json) =>
      _$ClassAssignmentFromJson(json);

  Map<String, dynamic> toJson() => _$ClassAssignmentToJson(this);
}

/// Class allocation model
@HiveType(typeId: 14)
@JsonSerializable()
class ClassAllocation {
  @HiveField(0)
  final String className;
  
  @HiveField(1)
  @JsonKey(unknownEnumValue: Grade.grade1)
  final Grade grade;
  
  @HiveField(2)
  final String section;
  
  @HiveField(3)
  final int studentCount;
  
  @HiveField(4)
  final int periodsAssigned;
  
  @HiveField(5)
  final List<String> subjects;
  
  @HiveField(6)
  @JsonKey(unknownEnumValue: ClassType.regular)
  final ClassType type;

  const ClassAllocation({
    required this.className,
    required this.grade,
    required this.section,
    required this.studentCount,
    required this.periodsAssigned,
    required this.subjects,
    required this.type,
  });

  factory ClassAllocation.fromJson(Map<String, dynamic> json) =>
      _$ClassAllocationFromJson(json);

  Map<String, dynamic> toJson() => _$ClassAllocationToJson(this);
}

/// Workload alert model
@HiveType(typeId: 15)
@JsonSerializable()
class WorkloadAlert {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String message;
  
  @HiveField(2)
  final String severity; // 'low', 'medium', 'high'
  
  @HiveField(3)
  final DateTime timestamp;
  
  @HiveField(4)
  final bool isRead;

  const WorkloadAlert({
    required this.id,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
  });

  factory WorkloadAlert.fromJson(Map<String, dynamic> json) =>
      _$WorkloadAlertFromJson(json);

  Map<String, dynamic> toJson() => _$WorkloadAlertToJson(this);
}

/// Main workload analytics model
@HiveType(typeId: 16)
@JsonSerializable()
class WorkloadAnalytics {
  @HiveField(0)
  final String staffId;
  
  @HiveField(1)
  final String staffName;
  
  @HiveField(2)
  final String department;
  
  @HiveField(3)
  final DateTime periodStart;
  
  @HiveField(4)
  final DateTime periodEnd;
  
  @HiveField(5)
  final double totalWorkingHours;
  
  @HiveField(6)
  final double weeklyAverageHours;
  
  @HiveField(7)
  final Map<String, double> hoursByWeek;
  
  @HiveField(8)
  final Map<String, double> hoursByMonth;
  
  @HiveField(9)
  final Map<String, double> hoursByActivity;
  
  @HiveField(10)
  @JsonKey(unknownEnumValue: WorkloadTrend.stable)
  final WorkloadTrend trend;
  
  @HiveField(11)
  final List<WorkloadAlert> alerts;

  const WorkloadAnalytics({
    required this.staffId,
    required this.staffName,
    required this.department,
    required this.periodStart,
    required this.periodEnd,
    required this.totalWorkingHours,
    required this.weeklyAverageHours,
    required this.hoursByWeek,
    required this.hoursByMonth,
    required this.hoursByActivity,
    required this.trend,
    required this.alerts,
  });

  factory WorkloadAnalytics.fromJson(Map<String, dynamic> json) =>
      _$WorkloadAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$WorkloadAnalyticsToJson(this);
}

/// Staff workload data model for raw data storage
@HiveType(typeId: 17)
@JsonSerializable()
class StaffWorkloadData {
  @HiveField(0)
  final String staffId;
  
  @HiveField(1)
  final String semester;
  
  @HiveField(2)
  final Map<String, int> periodsPerSubject;
  
  @HiveField(3)
  final Map<String, List<String>> classesPerGrade;
  
  @HiveField(4)
  final Map<String, List<Period>> weeklySchedule; // DayOfWeek as String
  
  @HiveField(5)
  final double totalWorkingHours;
  
  @HiveField(6)
  final Map<String, double> activityBreakdown; // ActivityType as String

  const StaffWorkloadData({
    required this.staffId,
    required this.semester,
    required this.periodsPerSubject,
    required this.classesPerGrade,
    required this.weeklySchedule,
    required this.totalWorkingHours,
    required this.activityBreakdown,
  });

  factory StaffWorkloadData.fromJson(Map<String, dynamic> json) =>
      _$StaffWorkloadDataFromJson(json);

  Map<String, dynamic> toJson() => _$StaffWorkloadDataToJson(this);
}