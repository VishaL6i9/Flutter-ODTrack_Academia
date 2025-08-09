import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/od_request.dart';

class ODRequestNotifier extends StateNotifier<List<ODRequest>> {
  ODRequestNotifier() : super(_demoRequests);

  static final List<ODRequest> _demoRequests = [
    ODRequest(
      id: '1',
      studentId: 'student_123',
      studentName: 'Demo Student',
      registerNumber: '123456789',
      date: DateTime.now().add(const Duration(days: 1)),
      periods: [1, 2, 3],
      reason: 'Medical appointment',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ODRequest(
      id: '2',
      studentId: 'student_123',
      studentName: 'Demo Student',
      registerNumber: '123456789',
      date: DateTime.now().subtract(const Duration(days: 1)),
      periods: [4, 5],
      reason: 'Family function',
      status: 'approved',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      approvedAt: DateTime.now().subtract(const Duration(days: 1)),
      approvedBy: 'Dr. Smith',
    ),
    ODRequest(
      id: '3',
      studentId: 'student_123',
      studentName: 'Demo Student',
      registerNumber: '123456789',
      date: DateTime.now().subtract(const Duration(days: 3)),
      periods: [1, 2, 3, 4, 5, 6],
      reason: 'Personal work',
      status: 'rejected',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      rejectionReason: 'Insufficient documentation',
    ),
  ];

  Future<void> createRequest(ODRequest request) async {
    // Simulate API call
    await Future<void>.delayed(const Duration(seconds: 1));
    
    state = [request, ...state];
  }

  Future<void> updateRequestStatus(String requestId, String newStatus, {String? reason}) async {
    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 500));
    
    state = state.map((request) {
      if (request.id == requestId) {
        return ODRequest(
          id: request.id,
          studentId: request.studentId,
          studentName: request.studentName,
          registerNumber: request.registerNumber,
          date: request.date,
          periods: request.periods,
          reason: request.reason,
          status: newStatus,
          staffId: request.staffId,
          createdAt: request.createdAt,
          approvedAt: newStatus == 'approved' ? DateTime.now() : request.approvedAt,
          approvedBy: newStatus == 'approved' ? 'Demo Staff' : request.approvedBy,
          rejectionReason: newStatus == 'rejected' ? reason : request.rejectionReason,
        );
      }
      return request;
    }).toList();
  }

  List<ODRequest> getRequestsByStatus(String status) {
    return state.where((request) => request.status == status).toList();
  }
}

final odRequestProvider = StateNotifierProvider<ODRequestNotifier, List<ODRequest>>((ref) {
  return ODRequestNotifier();
});
