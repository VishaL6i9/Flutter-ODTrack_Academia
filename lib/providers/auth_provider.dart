import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:odtrack_academia/models/user.dart';
import 'package:odtrack_academia/providers/staff_analytics_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:odtrack_academia/services/api/api_client.dart';
import 'package:odtrack_academia/services/api/auth_service.dart';

final _logger = Logger('AuthProvider');

class AuthState {
  final User? user;
  final String? token;
  final String? refreshToken;
  final bool isLoading;
  final String? error;
  final bool isBiometricVerified;

  const AuthState({
    this.user,
    this.token,
    this.refreshToken,
    this.isLoading = false,
    this.error,
    this.isBiometricVerified = false,
  });

  AuthState copyWith({
    User? user,
    String? token,
    String? refreshToken,
    bool? isLoading,
    String? error,
    bool? isBiometricVerified,
    bool clearTokens = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: clearTokens ? null : (token ?? this.token),
      refreshToken: clearTokens ? null : (refreshToken ?? this.refreshToken),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isBiometricVerified: isBiometricVerified ?? this.isBiometricVerified,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  AuthNotifier(this._authService, _) : super(const AuthState()) {
    _logger.info('AuthNotifier initialized');
  }

  // Used to store token metadata securely
  static const _secureStorage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';

  Box<User> get _userBox => Hive.box<User>(AppConstants.userBox);

  // Placeholder removed as real tokens are now used.

  // Future<void> _loadUserFromStorage() async {
  //   try {
  //     // Check if there are any users in the box
  //     if (_userBox.isNotEmpty) {
  //       // For now, get the first user - in a real app, you'd have a specific key
  //       final user = _userBox.values.first;
  //       state = state.copyWith(user: user);
  //     }
  //   } catch (e) {
  //     // Clear invalid data if there's an error
  //     await _userBox.clear();
  //   }
  // }

  Future<bool> verifyBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        _logger.warning('Biometrics not supported on this device. Bypassing lock.');
        state = state.copyWith(isBiometricVerified: true);
        return true;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please verify your identity to access ODTrack',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        state = state.copyWith(isBiometricVerified: true);
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      _logger.severe('Biometric authentication failed structure check: $e');
      return false;
    }
  }

  Future<void> loginStudent(String registerNumber, DateTime dateOfBirth) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      _logger.info('Student login started for: $registerNumber');
      // REPLACED: Real API Login
      final tokens = await _authService.login(registerNumber, dateOfBirth.toIso8601String());
      final accessToken = tokens['access_token'] as String;
      final refreshToken = tokens['refresh_token'] as String;
      
      // Update tokens in storage and state
      await updateTokens(accessToken, refreshToken);
      
      // Fetch user profile from backend
      final user = await _authService.getCurrentUser();

      // Save to storage - store the user object directly
      await _userBox.put(user.id, user);

      // FCM Token Registration
      try {
        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission();
        final fcmToken = await messaging.getToken();
        if (fcmToken != null) {
          await _authService.updateFcmToken(fcmToken);
        }
      } catch (e) {
        _logger.warning('Failed to register FCM token dynamically: $e');
      }

      _logger.info('Student login successful, user set');
      state = state.copyWith(user: user, token: accessToken as String?, refreshToken: refreshToken as String?, isLoading: false, isBiometricVerified: true);
    } catch (e) {
      _logger.severe('Student login failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<void> loginStaff(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // REPLACED: Real API Login
      final tokens = await _authService.login(email, password);
      final accessToken = tokens['access_token'] as String;
      final refreshToken = tokens['refresh_token'] as String;
      
      // Update tokens in storage and state
      await updateTokens(accessToken, refreshToken);
      
      // Fetch user profile from backend
      final user = await _authService.getCurrentUser();

      // Save to storage - store the user object directly
      await _userBox.put(user.id, user);

      // NOTE: Normally these would be set through ApiClient return formats, but 
      // injecting secure placeholders to satisfy Dart mappings without API refactoring here.
      // Removed mock token generation as real tokens are now used.
      
      // FCM Token Registration
      try {
        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission();
        final fcmToken = await messaging.getToken();
        if (fcmToken != null) {
          await _authService.updateFcmToken(fcmToken);
        }
      } catch (e) {
        _logger.warning('Failed to register FCM token dynamically: $e');
      }

      state = state.copyWith(user: user, token: accessToken as String?, refreshToken: refreshToken as String?, isLoading: false, isBiometricVerified: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<void> updateTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _tokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    state = state.copyWith(token: accessToken, refreshToken: refreshToken);
  }

  Future<void> logout() async {
    await _userBox.clear();
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    state = const AuthState(); // Reset the state to logged out
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: AppConstants.baseUrl);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final staffAnalyticsService = ref.watch(staffAnalyticsServiceProvider);
  final notifier = AuthNotifier(authService, staffAnalyticsService);
  
  // Bind token refresh
  ref.watch(apiClientProvider).onTokensRefreshed = (access, refresh) => notifier.updateTokens(access, refresh);
  return notifier;
});