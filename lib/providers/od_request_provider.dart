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

  List<ODRequest> getRequestsByStatus(String status) {
    return state.where((request) => request.status == status).toList();
  }
}

final odRequestProvider = StateNotifierProvider<ODRequestNotifier, List<ODRequest>>((ref) {
  return ODRequestNotifier();
});