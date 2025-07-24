import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'staff_member.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class StaffMember {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final String department;
  
  @HiveField(4)
  final String subject;
  
  @HiveField(5)
  final List<String> years;
  
  @HiveField(6)
  final String? phone;
  
  @HiveField(7)
  final String? designation;

  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.subject,
    required this.years,
    this.phone,
    this.designation,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => _$StaffMemberFromJson(json);
  
  Map<String, dynamic> toJson() => _$StaffMemberToJson(this);
}