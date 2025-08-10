import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/models/user.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadUserFromStorage();
  }

  final LazyBox<dynamic> _userBox = Hive.lazyBox(AppConstants.userBox);

  Future<void> _loadUserFromStorage() async {
    final userData = await _userBox.get(AppConstants.userDataKey);
    if (userData != null) {
      try {
        final user = User.fromJson(userData as Map<String, dynamic>);
        state = state.copyWith(user: user);
      } catch (e) {
        // Clear invalid data
        await _userBox.delete(AppConstants.userDataKey);
      }
    }
  }

  Future<void> loginStudent(String registerNumber, DateTime dateOfBirth) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Demo login - simulate API call
      await Future<void>.delayed(const Duration(seconds: 1));

      // Demo student data - assign section based on register number
      final sectionSuffix = (registerNumber.hashCode % 2 == 0) ? 'A' : 'B';
      final user = User(
        id: 'student_$registerNumber',
        name: 'Demo Student',
        email: '$registerNumber@student.edu',
        role: AppConstants.studentRole,
        registerNumber: registerNumber,
        year: '3rd Year',
        section: 'Computer Science - Section $sectionSuffix',
        department: 'Computer Science',
        phone: '+91 9876543210',
      );

      // Save to storage
      await _userBox.put(AppConstants.userDataKey, user.toJson());
      await _userBox.put(AppConstants.userRoleKey, user.role);

      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<void> loginStaff(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Demo login - simulate API call
      await Future<void>.delayed(const Duration(seconds: 1));

      // Demo staff data
      final user = User(
        id: 'staff_${email.split('@')[0]}',
        name: 'Demo Staff',
        email: email,
        role: AppConstants.staffRole,
        department: 'Computer Science',
        section: null, // Staff don't have sections
        phone: '+91 9876543210',
      );

      // Save to storage
      await _userBox.put(AppConstants.userDataKey, user.toJson());
      await _userBox.put(AppConstants.userRoleKey, user.role);

      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  Future<void> logout() async {
    await _userBox.clear();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
