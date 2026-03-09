import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';

/// HTTP client for API communication
class ApiClient {
  final String baseUrl;
  final Duration timeout;
  String? _authToken;
  String? _refreshToken; // Track refresh token

  // Dependency injection callback for seamlessly notifying Provider of new token chains
  final Future<void> Function(String accessToken, String refreshToken)? onTokensRefreshed;
  
  // Track refresh state to prevent multiple simultaneous refresh calls
  bool _isRefreshing = false;
  
  ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.onTokensRefreshed,
  });

  /// Set authentication tokens
  void setAuthTokens(String accessToken, String refreshToken) {
    _authToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Clear authentication tokens
  void clearAuthTokens() {
    _authToken = null;
    _refreshToken = null;
  }

  /// Get common headers
  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    
    return _executeWithTokenRefresh((resolvedHeaders) async {
      if (headers != null) resolvedHeaders.addAll(headers);
      return await http.get(uri, headers: resolvedHeaders).timeout(timeout);
    });
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return _executeWithTokenRefresh((resolvedHeaders) async {
      if (headers != null) resolvedHeaders.addAll(headers);
      return await http.post(
        uri, 
        headers: resolvedHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout);
    });
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return _executeWithTokenRefresh((resolvedHeaders) async {
      if (headers != null) resolvedHeaders.addAll(headers);
      return await http.put(
        uri, 
        headers: resolvedHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout);
    });
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return _executeWithTokenRefresh((resolvedHeaders) async {
      if (headers != null) resolvedHeaders.addAll(headers);
      return await http.patch(
        uri, 
        headers: resolvedHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(timeout);
    });
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return _executeWithTokenRefresh((resolvedHeaders) async {
      if (headers != null) resolvedHeaders.addAll(headers);
      return await http.delete(uri, headers: resolvedHeaders).timeout(timeout);
    });
  }

  /// Multipart File Upload Form request
  Future<Map<String, dynamic>> upload(
    String endpoint, 
    File file, {
    String fileField = 'file',
    String? mediaType,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(_getHeaders(additionalHeaders: headers));

      // Remove content-type to let framework set boundary correctly for multipart
      request.headers.remove('Content-Type');

      final mimeTypeData = mediaType != null ? mediaType.split('/') : ['application', 'octet-stream'];
      var type = MediaType(mimeTypeData[0], mimeTypeData.length > 1 ? mimeTypeData[1] : 'octet-stream');

      request.files.add(
        await http.MultipartFile.fromPath(
          fileField,
          file.path,
          contentType: type,
        ),
      );

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> _executeWithTokenRefresh(
    Future<http.Response> Function(Map<String, String> headers) requestCall
  ) async {
    try {
      final response = await requestCall(_getHeaders());
      
      // If unauthorized and we have a refresh token, try refreshing
      if (response.statusCode == 401 && _refreshToken != null && !_isRefreshing) {
        _isRefreshing = true;
        
        try {
          final refreshUri = Uri.parse('$baseUrl/auth/refresh');
          final refreshResponse = await http.post(
            refreshUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': _refreshToken}),
          ).timeout(timeout);
          
          if (refreshResponse.statusCode == 200) {
            final data = jsonDecode(refreshResponse.body);
            final newAccessToken = data['access_token'] as String;
            final newRefreshToken = data['refresh_token'] as String;
            
            // Save the new tokens locally in memory
            setAuthTokens(newAccessToken, newRefreshToken);
            
            // Notify external providers (AuthProvider)
            if (onTokensRefreshed != null) {
              await onTokensRefreshed!(newAccessToken, newRefreshToken);
            }
            
            // Re-execute original request with new token
            final retryResponse = await requestCall(_getHeaders());
            return _handleResponse(retryResponse);
          } else {
            // Refresh token failed/expired
            clearAuthTokens();
            throw NetworkError.serverError(401, endpoint: 'Token Expired');
          }
        } finally {
          _isRefreshing = false;
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw NetworkError.serverError(
        response.statusCode,
        endpoint: response.request?.url.toString(),
      );
    }
  }

  /// Handle errors
  BaseError _handleError(dynamic error) {
    if (error is BaseError) {
      return error;
    } else if (error is http.ClientException) {
      return NetworkError(
        code: 'CONNECTION_FAILED',
        message: 'Connection failed: ${error.message}',
        userMessage: 'Unable to connect to server. Please check your internet connection.',
        isRetryable: true,
        severity: ErrorSeverity.high,
      );
    } else {
      return NetworkError(
        code: 'UNKNOWN_ERROR',
        message: 'Unknown error: ${error.toString()}',
        userMessage: 'An unexpected error occurred. Please try again.',
        isRetryable: true,
        severity: ErrorSeverity.medium,
      );
    }
  }
}
