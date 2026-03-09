import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'package:odtrack_academia/models/period_slot.dart';

part 'timetable.g.dart';

@HiveType(typeId: 4)
@JsonSerializable()
class Timetable {
  @HiveField(0)
  final String year;

  @HiveField(1)
  final String section;

  @HiveField(2)
  final Map<String, List<PeriodSlot>> schedule;

  const Timetable({
    required this.year,
    required this.section,
    required this.schedule,
  });

  factory Timetable.fromJson(Map<String, dynamic> json) => _$TimetableFromJson(json);

  Map<String, dynamic> toJson() => _$TimetableToJson(this);
}
