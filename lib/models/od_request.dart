import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'od_request.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class ODRequest {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String studentId;
  
  @HiveField(2)
  final String studentName;
  
  @HiveField(3)
  final String registerNumber;
  
  @HiveField(4)
  final DateTime date;
  
  @HiveField(5)
  final List<int> periods;
  
  @HiveField(6)
  final String reason;
  
  @HiveField(7)
  final String status; // 'pending', 'approved', 'rejected'
  
  @HiveField(8)
  final String? attachmentUrl;
  
  @HiveField(9)
  final DateTime createdAt;
  
  @HiveField(10)
  final DateTime? approvedAt;
  
  @HiveField(11)
  final String? approvedBy;
  
  @HiveField(12)
  final String? rejectionReason;

  @HiveField(13)
  final String? staffId;

  const ODRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.registerNumber,
    required this.date,
    required this.periods,
    required this.reason,
    required this.status,
    this.attachmentUrl,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
    this.staffId,
  });

  factory ODRequest.fromJson(Map<String, dynamic> json) => _$ODRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$ODRequestToJson(this);
  
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
