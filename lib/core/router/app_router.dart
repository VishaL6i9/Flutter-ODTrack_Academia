import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/features/auth/presentation/login_screen.dart';
import 'package:odtrack_academia/features/dashboard/presentation/dashboard_screen.dart';
import 'package:odtrack_academia/features/od_request/presentation/new_od_screen.dart';
import 'package:odtrack_academia/features/timetable/presentation/timetable_screen.dart';
import 'package:odtrack_academia/features/staff_directory/presentation/staff_directory_screen.dart';
import 'package:odtrack_academia/features/staff_inbox/presentation/staff_inbox_screen.dart';
import 'package:odtrack_academia/features/analytics/presentation/screens/staff_analytics_dashboard_screen.dart';
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
      GoRoute(
        path: AppConstants.staffAnalyticsRoute,
        builder: (context, state) {
          String? staffId = state.uri.queryParameters['staffId'];

          // If staffId is not provided in query, try to get from logged-in user
          if (staffId == null || staffId.isEmpty) {
            staffId = authState.user?.id;
          }

          // If still no staffId, try to get the first available staff member
          if (staffId == null || staffId.isEmpty) {
            // This is an async call, but builder is sync. We need to handle this.
            // For now, we'll use a placeholder and let the screen handle the async fetch.
            // The dashboard screen already has logic to fetch the first staff ID if its own staffId is null/invalid.
            // So, we can just pass null here and let the screen's _initializeAnalytics handle the fallback.
            // This avoids making the router builder async.
          }
          return StaffAnalyticsDashboardScreen(staffId: staffId);
        },
      ),
    ],
  );
});
