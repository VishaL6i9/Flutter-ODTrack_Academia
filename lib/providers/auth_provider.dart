import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/features/staff_directory/data/staff_data.dart';
import 'package:odtrack_academia/models/user.dart';
import 'package:odtrack_academia/providers/staff_analytics_provider.dart';
import 'package:odtrack_academia/services/analytics/staff_analytics_service.dart';

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
  AuthNotifier(this._staffAnalyticsService) : super(const AuthState()) {
    _loadUserFromStorage();
  }

  Box<User> get _userBox => Hive.box<User>(AppConstants.userBox);
  final StaffAnalyticsService _staffAnalyticsService;

  Future<void> _loadUserFromStorage() async {
    try {
      // Check if there are any users in the box
      if (_userBox.isNotEmpty) {
        // For now, get the first user - in a real app, you'd have a specific key
        final user = _userBox.values.first;
        state = state.copyWith(user: user);
      }
    } catch (e) {
      // Clear invalid data if there's an error
      await _userBox.clear();
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

      // Save to storage - store the user object directly
      await _userBox.put(user.id, user);

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
      await _staffAnalyticsService.initialize();

      // Find staff by email
      final staffMember = await _staffAnalyticsService.findStaffByEmail(email);

      User user;
      if (staffMember != null) {
        // Use existing staff data
        user = User(
          id: staffMember.id,
          name: staffMember.name,
          email: staffMember.email,
          role: AppConstants.staffRole,
          department: staffMember.department,
          phone: staffMember.phone,
        );
      } else {
        // Fallback to the first staff member in the hardcoded list
        final fallbackStaff = StaffData.allStaff.first;
        user = User(
          id: fallbackStaff.id,
          name: fallbackStaff.name,
          email: email, // Keep the entered email
          role: AppConstants.staffRole,
          department: fallbackStaff.department,
          phone: fallbackStaff.phone,
        );
      }

      // Save to storage - store the user object directly
      await _userBox.put(user.id, user);

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
    state = const AuthState(); // Reset the state to logged out
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final staffAnalyticsService = ref.watch(staffAnalyticsServiceProvider);
  return AuthNotifier(staffAnalyticsService);
});