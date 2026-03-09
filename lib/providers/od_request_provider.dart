import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/calendar/calendar_sync_service.dart';
import 'package:odtrack_academia/services/api/od_api_service.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';

class ODRequestNotifier extends StateNotifier<List<ODRequest>> {
  final ODApiService _apiService;
  final CalendarSyncService? _calendarSyncService;
  
  ODRequestNotifier(this._apiService, {CalendarSyncService? calendarSyncService}) 
    : _calendarSyncService = calendarSyncService,
      super([]);

  Future<void> fetchRequests() async {
    try {
      final requests = await _apiService.getODRequests();
      state = requests;
    } catch (e) {
      debugPrint('Error fetching OD requests: $e');
    }
  }

  Future<void> createRequest(ODRequest request) async {
    // REPLACED: Real API Call
    try {
      final newRequest = await _apiService.createODRequest({
        'date': request.date.toIso8601String().split('T')[0],
        'periods': request.periods,
        'reason': request.reason,
        'staff_id': request.staffId,
        'attachment_url': request.attachmentUrl,
        'student_id': request.studentId,
        'register_number': request.registerNumber,
        'student_name': request.studentName,
      });
      
      state = [newRequest, ...state];
    
    // Sync with calendar if service is available
    if (_calendarSyncService != null) {
      try {
        await _calendarSyncService.handleODRequestCreation(request);
      } catch (e) {
        // Log error but don't fail the request creation
        debugPrint('Calendar sync error during request creation: $e');
      }
    }
  }

  Future<void> updateRequestStatus(String requestId, String newStatus, {String? reason}) async {
    // Find the old request for calendar sync
    final oldRequest = state.firstWhere((request) => request.id == requestId);
    
    // REPLACED: Real API Call
    try {
      final updatedRequest = await _apiService.updateODStatus(requestId, newStatus, reason: reason);
    
      state = state.map((request) => request.id == requestId ? updatedRequest : request).toList();
      
      // Sync with calendar if service is available and request was updated
      if (_calendarSyncService != null) {
        try {
          await _calendarSyncService.handleODRequestStatusChange(oldRequest, updatedRequest);
        } catch (e) {
          debugPrint('Calendar sync error: $e');
        }
      }
    } catch (e) {
      debugPrint('Error updating OD status: $e');
    }
  }

  Future<void> deleteRequest(String requestId) async {
    try {
      await _apiService.deleteODRequest(requestId);
      state = state.where((request) => request.id != requestId).toList();
    } catch (e) {
      debugPrint('Error deleting OD request: $e');
    }
    
    // Sync with calendar if service is available
    if (_calendarSyncService != null) {
      try {
        await _calendarSyncService.handleODRequestDeletion(requestToDelete);
      } catch (e) {
        // Log error but don't fail the deletion
        debugPrint('Calendar sync error during request deletion: $e');
      }
    }
  }

  Future<void> syncAllRequestsWithCalendar() async {
    // Sync all requests with calendar
    if (_calendarSyncService != null) {
      try {
        await _calendarSyncService.syncAllODRequests(state);
      } catch (e) {
        debugPrint('Calendar sync error during bulk sync: $e');
        rethrow;
      }
    }
  }

  List<ODRequest> getRequestsByStatus(String status) {
    return state.where((request) => request.status == status).toList();
  }
}

final odApiServiceProvider = Provider<ODApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ODApiService(apiClient);
});

final odRequestProvider = StateNotifierProvider<ODRequestNotifier, List<ODRequest>>((ref) {
  final apiService = ref.watch(odApiServiceProvider);
  final calendarSyncService = ref.watch(calendarSyncServiceProvider);
  final notifier = ODRequestNotifier(apiService, calendarSyncService: calendarSyncService);
  
  // Initial fetch
  notifier.fetchRequests();
  
  return notifier;
});
