import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/calendar/calendar_sync_service.dart';

class ODRequestNotifier extends StateNotifier<List<ODRequest>> {
  final CalendarSyncService? _calendarSyncService;
  
  ODRequestNotifier({CalendarSyncService? calendarSyncService}) 
    : _calendarSyncService = calendarSyncService,
      super(_demoRequests);

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
    
    // Sync with calendar if service is available
    if (_calendarSyncService != null) {
      try {
        await _calendarSyncService!.handleODRequestCreation(request);
      } catch (e) {
        // Log error but don't fail the request creation
        print('Calendar sync error during request creation: $e');
      }
    }
  }

  Future<void> updateRequestStatus(String requestId, String newStatus, {String? reason}) async {
    // Find the old request for calendar sync
    final oldRequest = state.firstWhere((request) => request.id == requestId);
    
    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 500));
    
    ODRequest? updatedRequest;
    
    state = state.map((request) {
      if (request.id == requestId) {
        updatedRequest = ODRequest(
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
        return updatedRequest!;
      }
      return request;
    }).toList();
    
    // Sync with calendar if service is available and request was updated
    if (_calendarSyncService != null && updatedRequest != null) {
      try {
        await _calendarSyncService!.handleODRequestStatusChange(oldRequest, updatedRequest!);
      } catch (e) {
        // Log error but don't fail the status update
        print('Calendar sync error during status update: $e');
      }
    }
  }

  Future<void> deleteRequest(String requestId) async {
    // Find the request to delete for calendar sync
    final requestToDelete = state.firstWhere((request) => request.id == requestId);
    
    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 500));
    
    state = state.where((request) => request.id != requestId).toList();
    
    // Sync with calendar if service is available
    if (_calendarSyncService != null) {
      try {
        await _calendarSyncService!.handleODRequestDeletion(requestToDelete);
      } catch (e) {
        // Log error but don't fail the deletion
        print('Calendar sync error during request deletion: $e');
      }
    }
  }

  Future<void> syncAllRequestsWithCalendar() async {
    // Sync all requests with calendar
    if (_calendarSyncService != null) {
      try {
        await _calendarSyncService!.syncAllODRequests(state);
      } catch (e) {
        print('Calendar sync error during bulk sync: $e');
        rethrow;
      }
    }
  }

  List<ODRequest> getRequestsByStatus(String status) {
    return state.where((request) => request.status == status).toList();
  }
}

final odRequestProvider = StateNotifierProvider<ODRequestNotifier, List<ODRequest>>((ref) {
  final calendarSyncService = ref.watch(calendarSyncServiceProvider);
  return ODRequestNotifier(calendarSyncService: calendarSyncService);
});
