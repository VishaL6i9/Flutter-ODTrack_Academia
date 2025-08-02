import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class User {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final String role; // 'student' or 'staff'
  
  @HiveField(4)
  final String? registerNumber; // For students
  
  @HiveField(5)
  final String? department; // For staff
  
  @HiveField(6)
  final String? year; // For students
  
  @HiveField(7)
  final String? section; // For students (e.g., "Computer Science - Section A")
  
  @HiveField(8)
  final String? phone;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.registerNumber,
    this.department,
    this.year,
    this.section,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserToJson(this);
  
  bool get isStudent => role == 'student';
  bool get isStaff => role == 'staff';
}