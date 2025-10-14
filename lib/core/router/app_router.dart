import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/core/navigation/navigation_service.dart';
import 'package:odtrack_academia/features/auth/presentation/login_screen.dart';
import 'package:odtrack_academia/features/dashboard/presentation/dashboard_screen.dart';
import 'package:odtrack_academia/features/od_request/presentation/enhanced_new_od_screen.dart';
import 'package:odtrack_academia/features/timetable/presentation/timetable_screen.dart';
import 'package:odtrack_academia/features/staff_directory/presentation/staff_directory_screen.dart';
import 'package:odtrack_academia/features/staff_inbox/presentation/staff_inbox_screen.dart';
import 'package:odtrack_academia/features/analytics/presentation/screens/staff_analytics_dashboard_screen.dart';
import 'package:odtrack_academia/features/export/presentation/export_screen.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';
import 'package:odtrack_academia/shared/widgets/page_transitions.dart';

/// Build transition widget based on transition type
Widget _buildTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
  PageTransitionType type,
  Curve curve,
) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: curve,
  );

  switch (type) {
    case PageTransitionType.slideFromRight:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );

    case PageTransitionType.slideFromLeft:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );

    case PageTransitionType.slideFromBottom:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );

    case PageTransitionType.slideFromTop:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );

    case PageTransitionType.fade:
      return FadeTransition(
        opacity: animation,
        child: child,
      );

    case PageTransitionType.scale:
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );

    case PageTransitionType.rotation:
      return RotationTransition(
        turns: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );

    case PageTransitionType.slideAndFade:
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );

    case PageTransitionType.scaleAndRotate:
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(curvedAnimation),
        child: RotationTransition(
          turns: Tween<double>(
            begin: -0.1,
            end: 0.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      );

    case PageTransitionType.elasticIn:
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        )),
        child: child,
      );

    case PageTransitionType.bounceIn:
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.bounceOut,
        )),
        child: child,
      );
  }
}

/// Helper function to build pages with custom transitions
Page<T> _buildPageWithTransition<T>(
  BuildContext context,
  GoRouterState state,
  Widget child,
  PageTransitionType transitionType,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionType: transitionType,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _buildTransition(
        context,
        animation,
        secondaryAnimation,
        child,
        transitionType,
        Curves.easeInOut,
      );
    },
  );
}

/// Custom transition page for GoRouter
class CustomTransitionPage<T> extends Page<T> {
  final Widget child;
  final PageTransitionType transitionType;
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) transitionsBuilder;

  const CustomTransitionPage({
    required this.child,
    required this.transitionType,
    required this.transitionsBuilder,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: transitionsBuilder,
    );
  }
}

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
      
      // Initialize breadcrumbs for the current route
      if (isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NavigationService.instance.initializeBreadcrumbs(state.matchedLocation);
        });
      }
      
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: AppConstants.loginRoute,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const LoginScreen(),
          PageTransitionType.fade,
        ),
      ),
      GoRoute(
        path: AppConstants.dashboardRoute,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const DashboardScreen(),
          PageTransitionType.slideFromRight,
        ),
      ),
      GoRoute(
        path: AppConstants.newOdRoute,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const EnhancedNewOdScreen(),
          PageTransitionType.slideFromBottom,
        ),
      ),
      GoRoute(
        path: AppConstants.timetableRoute,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const TimetableScreen(),
          PageTransitionType.slideFromRight,
        ),
      ),
      GoRoute(
        path: AppConstants.staffDirectoryRoute,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const StaffDirectoryScreen(),
          PageTransitionType.slideFromRight,
        ),
      ),
      GoRoute(
        path: AppConstants.staffInboxRoute,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const StaffInboxScreen(),
          PageTransitionType.slideFromRight,
        ),
      ),
      GoRoute(
        path: AppConstants.staffAnalyticsRoute,
        pageBuilder: (context, state) {
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
          
          return _buildPageWithTransition(
            context,
            state,
            StaffAnalyticsDashboardScreen(staffId: staffId),
            PageTransitionType.slideFromRight,
          );
        },
      ),
      GoRoute(
        path: AppConstants.exportRoute,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const ExportScreen(),
          PageTransitionType.slideFromRight,
        ),
      ),
    ],
  );
});
