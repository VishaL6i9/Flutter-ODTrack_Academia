import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/services/api/api_client.dart';

class ODApiService {
  final ApiClient _apiClient;

  ODApiService(this._apiClient);

  /// Fetch all OD requests (filtered by role in backend)
  Future<List<ODRequest>> getODRequests() async {
    final response = await _apiClient.get('/od-requests/');
    final List<dynamic> data = (response['requests'] as List? ?? []);
    return data.map((json) => ODRequest.fromJson(json as Map<String, dynamic>)).toList();
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
