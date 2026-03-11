import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/user.dart';
import 'package:odtrack_academia/services/calendar/calendar_sync_service.dart';
import 'package:odtrack_academia/services/api/od_api_service.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';

class ODRequestNotifier extends StateNotifier<List<ODRequest>> {
  final ODApiService _apiService;
  final CalendarSyncService? _calendarSyncService;
  
  ODRequestNotifier(this._apiService, {CalendarSyncService? calendarSyncService}) 
    : _calendarSyncService = calendarSyncService,
      super([]);

  Future<void> fetchRequests({DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final requests = await _apiService.getODRequests(dateFrom: dateFrom, dateTo: dateTo);
      state = requests;
      
      // Update local cache for offline mode and analytics
      try {
        if (!Hive.isBoxOpen('od_requests_box')) {
          await Hive.openBox<ODRequest>('od_requests_box');
        }
        final box = Hive.box<ODRequest>('od_requests_box');
        
        final Map<dynamic, ODRequest> requestMap = {
          for (var req in requests) req.id: req
        };
        await box.putAll(requestMap);
        
        // Populate basic student info in users_box for analytics department filtering
        if (!Hive.isBoxOpen('users_box')) {
          await Hive.openBox<User>('users_box');
        }
        final usersBox = Hive.box<User>('users_box');
        for (final req in requests) {
          if (!usersBox.containsKey(req.studentId)) {
            // Check if department info is embedded in studentName (e.g., "Vishal (CSE)")
            String? dept;
            if (req.studentName.contains('(') && req.studentName.endsWith(')')) {
              final startIndex = req.studentName.lastIndexOf('(') + 1;
              dept = req.studentName.substring(startIndex, req.studentName.length - 1);
            }
            usersBox.put(req.studentId, User(
              id: req.studentId,
              name: req.studentName,
              email: '${req.registerNumber}@example.com',
              role: 'student',
              registerNumber: req.registerNumber,
              department: dept ?? 'Unknown',
            ));
          }
        }
      } catch (e) {
        debugPrint('Failed to cache OD requests or users: $e');
      }
      
    } catch (e) {
      debugPrint('Error fetching OD requests, attempting to load from cache: $e');
      // If network fails, try to load from cache
      try {
        if (!Hive.isBoxOpen('od_requests_box')) {
          await Hive.openBox<ODRequest>('od_requests_box');
        }
        final box = Hive.box<ODRequest>('od_requests_box');
        
        var cachedRequests = box.values.toList();
        if (dateFrom != null) {
          cachedRequests = cachedRequests.where((r) => r.createdAt.isAfter(dateFrom) || r.createdAt.isAtSameMomentAs(dateFrom)).toList();
        }
        if (dateTo != null) {
          // Adjust dateTo logic for end of day if needed
          cachedRequests = cachedRequests.where((r) => r.createdAt.isBefore(dateTo.add(const Duration(days: 1)))).toList();
        }
        
        // Sort descending by created at as API does
        cachedRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        state = cachedRequests;
      } catch (cacheError) {
        debugPrint('Failed to load OD requests from cache: $cacheError');
      }
    }
  }

  Future<void> createRequest(ODRequest request) async {
    // Send full ISO string to ensure UTC consistency if possible, 
    // though backend currently expects date part for some logic.
    final newRequest = await _apiService.createODRequest({
      'date': request.date.toIso8601String(),
      'periods': request.periods,
      'reason': request.reason,
      'attachment_url': request.attachmentUrl,
      'register_number': request.registerNumber,
      'student_name': request.studentName,
      'staff_id': int.tryParse(request.staffId ?? ''),
    });
    
    state = [newRequest, ...state];
  
    // Sync with calendar if service is available
    if (_calendarSyncService != null) {
      try {
        await _calendarSyncService.handleODRequestCreation(newRequest);
      } catch (e) {
        // Log error but don't fail the request creation
        debugPrint('Calendar sync error during request creation: $e');
      }
    }
  }

  Future<void> editRequest(String id, Map<String, dynamic> updates) async {
    try {
      // Ensure staff_id is an integer if present
      if (updates.containsKey('staff_id') && updates['staff_id'] is String) {
        updates['staff_id'] = int.tryParse(updates['staff_id'] as String);
      }
      
      final updatedRequest = await _apiService.updateODRequest(id, updates);
      state = state.map((request) => request.id == id ? updatedRequest : request).toList();
      
      // Note: Calendar sync for edits could be added here if needed
    } catch (e) {
      debugPrint('Error editing OD request: $e');
      rethrow;
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
      final requestToDelete = state.firstWhere((request) => request.id == requestId);
      await _apiService.deleteODRequest(requestId);
      state = state.where((request) => request.id != requestId).toList();
      
      // Sync with calendar if service is available
      if (_calendarSyncService != null) {
        try {
          await _calendarSyncService.handleODRequestDeletion(requestToDelete);
        } catch (e) {
          // Log error but don't fail the deletion
          debugPrint('Calendar sync error during request deletion: $e');
        }
      }
    } catch (e) {
      debugPrint('Error deleting OD request: $e');
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

/// Provides pre-aggregated OD request counts by status from the backend.
/// Works correctly for both students (own requests) and staff (assigned requests).
/// This avoids the problem where odRequestProvider only holds pending items for staff.
final odStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final apiService = ref.watch(odApiServiceProvider);
  return apiService.getODStats();
});

/// Represents a filter for date ranges.
class DateRangeFilter {
  final DateTime? start;
  final DateTime? end;
  
  const DateRangeFilter({this.start, this.end});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRangeFilter && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

/// Provides archived OD requests based on an optional date range.
final odArchiveProvider = FutureProvider.family<List<ODRequest>, DateRangeFilter>((ref, filter) async {
  final apiService = ref.watch(odApiServiceProvider);
  return apiService.getArchivedODRequests(dateFrom: filter.start, dateTo: filter.end);
});
