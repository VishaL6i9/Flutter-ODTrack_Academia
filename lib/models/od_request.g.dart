// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'od_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ODRequestAdapter extends TypeAdapter<ODRequest> {
  @override
  final int typeId = 1;

  @override
  ODRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ODRequest(
      id: fields[0] as String,
      studentId: fields[1] as String,
      studentName: fields[2] as String,
      registerNumber: fields[3] as String,
      date: fields[4] as DateTime,
      periods: (fields[5] as List).cast<int>(),
      reason: fields[6] as String,
      status: fields[7] as String,
      attachmentUrl: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      approvedAt: fields[10] as DateTime?,
      approvedBy: fields[11] as String?,
      rejectionReason: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ODRequest obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.studentName)
      ..writeByte(3)
      ..write(obj.registerNumber)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.periods)
      ..writeByte(6)
      ..write(obj.reason)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.attachmentUrl)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.approvedAt)
      ..writeByte(11)
      ..write(obj.approvedBy)
      ..writeByte(12)
      ..write(obj.rejectionReason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ODRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ODRequest _$ODRequestFromJson(Map<String, dynamic> json) => ODRequest(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      registerNumber: json['registerNumber'] as String,
      date: DateTime.parse(json['date'] as String),
      periods: (json['periods'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      reason: json['reason'] as String,
      status: json['status'] as String,
      attachmentUrl: json['attachmentUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
      approvedBy: json['approvedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$ODRequestToJson(ODRequest instance) => <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'registerNumber': instance.registerNumber,
      'date': instance.date.toIso8601String(),
      'periods': instance.periods,
      'reason': instance.reason,
      'status': instance.status,
      'attachmentUrl': instance.attachmentUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'approvedAt': instance.approvedAt?.toIso8601String(),
      'approvedBy': instance.approvedBy,
      'rejectionReason': instance.rejectionReason,
    };
