import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/features/auth/presentation/login_screen.dart';
import 'package:odtrack_academia/features/dashboard/presentation/dashboard_screen.dart';
import 'package:odtrack_academia/features/od_request/presentation/new_od_screen.dart';
import 'package:odtrack_academia/features/timetable/presentation/timetable_screen.dart';
import 'package:odtrack_academia/features/staff_directory/presentation/staff_directory_screen.dart';
import 'package:odtrack_academia/features/staff_inbox/presentation/staff_inbox_screen.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: authState.isAuthenticated 
        ? AppConstants.dashboardRoute 
        : AppConstants.loginRoute,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == AppConstants.loginRoute;
      
      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !isLoginRoute) {
        return AppConstants.loginRoute;
      }
      
      // If authenticated and on login page, redirect to dashboard
      if (isAuthenticated && isLoginRoute) {
        return AppConstants.dashboardRoute;
      }
      
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.dashboardRoute,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.newOdRoute,
        builder: (context, state) => const NewOdScreen(),
      ),
      GoRoute(
        path: AppConstants.timetableRoute,
        builder: (context, state) => const TimetableScreen(),
      ),
      GoRoute(
        path: AppConstants.staffDirectoryRoute,
        builder: (context, state) => const StaffDirectoryScreen(),
      ),
      GoRoute(
        path: AppConstants.staffInboxRoute,
        builder: (context, state) => const StaffInboxScreen(),
      ),
    ],
  );
});
