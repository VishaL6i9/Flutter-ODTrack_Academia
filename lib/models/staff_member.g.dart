// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_member.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StaffMemberAdapter extends TypeAdapter<StaffMember> {
  @override
  final int typeId = 2;

  @override
  StaffMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StaffMember(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      department: fields[3] as String,
      subject: fields[4] as String,
      years: (fields[5] as List).cast<String>(),
      phone: fields[6] as String?,
      designation: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StaffMember obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.department)
      ..writeByte(4)
      ..write(obj.subject)
      ..writeByte(5)
      ..write(obj.years)
      ..writeByte(6)
      ..write(obj.phone)
      ..writeByte(7)
      ..write(obj.designation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffMember _$StaffMemberFromJson(Map<String, dynamic> json) => StaffMember(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      department: json['department'] as String,
      subject: json['subject'] as String,
      years: (json['years'] as List<dynamic>).map((e) => e as String).toList(),
      phone: json['phone'] as String?,
      designation: json['designation'] as String?,
    );

Map<String, dynamic> _$StaffMemberToJson(StaffMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'department': instance.department,
      'subject': instance.subject,
      'years': instance.years,
      'phone': instance.phone,
      'designation': instance.designation,
    };
