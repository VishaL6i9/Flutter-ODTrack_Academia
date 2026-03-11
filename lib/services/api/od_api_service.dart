import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/api/api_client.dart';

class ODApiService {
  final ApiClient _apiClient;

  ODApiService(this._apiClient);

  /// Fetch all OD requests (filtered by role in backend)
  Future<List<ODRequest>> getODRequests({DateTime? dateFrom, DateTime? dateTo}) async {
    final queryParams = <String, String>{};
    if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String();
    if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String();
    
    final queryString = queryParams.isNotEmpty 
        ? '?${Uri(queryParameters: queryParams).query}' 
        : '';
        
    final response = await _apiClient.get('/od-requests/$queryString');
    final List<dynamic> data = (response['requests'] as List? ?? []);
    return data.map((json) => ODRequest.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Fetch archived OD requests for staff (any status, typically past dates)
  Future<List<ODRequest>> getArchivedODRequests({DateTime? dateFrom, DateTime? dateTo}) async {
    final queryParams = <String, String>{};
    if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String();
    if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String();
    
    final queryString = queryParams.isNotEmpty 
        ? '?${Uri(queryParameters: queryParams).query}' 
        : '';
        
    final response = await _apiClient.get('/od-requests/archive$queryString');
    // Archive endpoint returns a direct list, not wrapped in mapping like GET /od-requests/
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => ODRequest.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Fetch OD request counts by status for the current user.
  /// Students get their own; staff get counts of requests assigned to them.
  Future<Map<String, int>> getODStats() async {
    final response = await _apiClient.get('/od-requests/stats');
    return {
      'pending': (response['pending'] as num?)?.toInt() ?? 0,
      'approved': (response['approved'] as num?)?.toInt() ?? 0,
      'rejected': (response['rejected'] as num?)?.toInt() ?? 0,
      'total': (response['total'] as num?)?.toInt() ?? 0,
    };
  }

  /// Create a new OD request
  Future<ODRequest> createODRequest(Map<String, dynamic> requestData) async {
    final response = await _apiClient.post('/od-requests/', body: requestData);
    return ODRequest.fromJson(response);
  }

  /// Update an existing OD request (for student edit)
  Future<ODRequest> updateODRequest(String id, Map<String, dynamic> requestData) async {
    final response = await _apiClient.put('/od-requests/$id/', body: requestData);
    return ODRequest.fromJson(response);
  }

  /// Update OD request status (for staff/admin)
  Future<ODRequest> updateODStatus(String id, String status, {String? reason}) async {
    final response = await _apiClient.put(
      '/od-requests/$id/status', 
      body: {
        'status': status,
        if (reason != null) 'rejection_reason': reason,
      },
    );
    return ODRequest.fromJson(response);
  }

  /// Get specific OD request details
  Future<ODRequest> getODRequestDetails(String id) async {
    final response = await _apiClient.get('/od-requests/$id');
    return ODRequest.fromJson(response);
  }

  /// Delete an OD request
  Future<void> deleteODRequest(String id) async {
    await _apiClient.delete('/od-requests/$id');
  }
}
