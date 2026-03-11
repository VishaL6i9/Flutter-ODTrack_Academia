import 'package:odtrack_academia/models/user.dart';
import 'package:odtrack_academia/services/api/api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  /// Login and return tokens
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Backend OAuth2 login expects form data (username/password)
    // But since our ApiClient handles JSON by default, we'll check how to send form data
    // OAuth2PasswordRequestForm in FastAPI usually expects application/x-www-form-urlencoded
    
    final response = await _apiClient.post(
      '/auth/login',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );
    
    return response;
  }

  /// Get current user profile
  Future<User> getCurrentUser() async {
    final response = await _apiClient.get('/users/me');
    return User.fromJson(response);
  }

  /// Update FCM token
  Future<void> updateFcmToken(String token) async {
    await _apiClient.patch('/users/me/fcm-token', body: {'fcm_token': token});
  }

  /// Update tokens in ApiClient
  void updateTokens(String accessToken, String refreshToken) {
    _apiClient.setAuthTokens(accessToken, refreshToken);
  }
}
