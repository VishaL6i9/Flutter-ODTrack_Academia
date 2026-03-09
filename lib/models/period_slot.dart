import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'period_slot.g.dart';

@HiveType(typeId: 5)
@JsonSerializable()
class PeriodSlot {
  @HiveField(0)
  final String subject;

  @HiveField(1)
  final String? staffId;

  @HiveField(2)
  final String? type;

  const PeriodSlot({
    required this.subject,
    this.staffId,
    this.type,
  });

  factory PeriodSlot.fromJson(Map<String, dynamic> json) => _$PeriodSlotFromJson(json);

  Map<String, dynamic> toJson() => _$PeriodSlotToJson(this);
}
