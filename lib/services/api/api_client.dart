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

  ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
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
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
      
      final response = await http
          .get(uri, headers: _getHeaders(additionalHeaders: headers))
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await http
          .post(
            uri,
            headers: _getHeaders(additionalHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await http
          .put(
            uri,
            headers: _getHeaders(additionalHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await http
          .delete(uri, headers: _getHeaders(additionalHeaders: headers))
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
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
