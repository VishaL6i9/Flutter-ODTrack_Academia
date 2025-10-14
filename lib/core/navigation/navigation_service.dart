import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation breadcrumb item
class BreadcrumbItem {
  final String label;
  final String route;
  final IconData? icon;
  final Map<String, String>? queryParameters;

  const BreadcrumbItem({
    required this.label,
    required this.route,
    this.icon,
    this.queryParameters,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreadcrumbItem &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          route == other.route;

  @override
  int get hashCode => label.hashCode ^ route.hashCode;
}

/// Navigation context for preserving state
class NavigationContext {
  final String currentRoute;
  final Map<String, dynamic> state;
  final DateTime timestamp;
  final String? previousRoute;

  NavigationContext({
    required this.currentRoute,
    required this.state,
    required this.timestamp,
    this.previousRoute,
  });

  NavigationContext copyWith({
    String? currentRoute,
    Map<String, dynamic>? state,
    DateTime? timestamp,
    String? previousRoute,
  }) {
    return NavigationContext(
      currentRoute: currentRoute ?? this.currentRoute,
      state: state ?? this.state,
      timestamp: timestamp ?? this.timestamp,
      previousRoute: previousRoute ?? this.previousRoute,
    );
  }
}

/// Enhanced navigation service with breadcrumbs and context preservation
class NavigationService {
  static NavigationService? _instance;
  static NavigationService get instance => _instance ??= NavigationService._();
  
  NavigationService._();

  final List<BreadcrumbItem> _breadcrumbs = [];
  final Map<String, NavigationContext> _navigationHistory = {};
  final Map<String, Map<String, dynamic>> _routeState = {};
  
  /// Get current breadcrumbs
  List<BreadcrumbItem> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  /// Add breadcrumb item
  void addBreadcrumb(BreadcrumbItem item) {
    // Remove if already exists to avoid duplicates
    _breadcrumbs.removeWhere((crumb) => crumb.route == item.route);
    _breadcrumbs.add(item);
    
    // Keep breadcrumbs limited
    if (_breadcrumbs.length > 5) {
      _breadcrumbs.removeAt(0);
    }
  }

  /// Remove breadcrumb and all after it
  void removeBreadcrumbsAfter(String route) {
    final index = _breadcrumbs.indexWhere((crumb) => crumb.route == route);
    if (index != -1) {
      _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
    }
  }

  /// Clear all breadcrumbs
  void clearBreadcrumbs() {
    _breadcrumbs.clear();
  }

  /// Navigate to route with breadcrumb
  void navigateWithBreadcrumb(
    BuildContext context,
    BreadcrumbItem breadcrumb, {
    Map<String, dynamic>? state,
  }) {
    // Save current state
    final currentRoute = GoRouterState.of(context).matchedLocation;
    if (state != null) {
      saveRouteState(currentRoute, state);
    }

    // Add breadcrumb
    addBreadcrumb(breadcrumb);

    // Navigate
    if (breadcrumb.queryParameters != null) {
      context.go(breadcrumb.route, extra: breadcrumb.queryParameters);
    } else {
      context.go(breadcrumb.route);
    }
  }

  /// Navigate back using breadcrumbs
  void navigateBack(BuildContext context) {
    if (_breadcrumbs.length > 1) {
      // Remove current breadcrumb
      _breadcrumbs.removeLast();
      
      // Navigate to previous breadcrumb
      final previousBreadcrumb = _breadcrumbs.last;
      if (previousBreadcrumb.queryParameters != null) {
        context.go(previousBreadcrumb.route, extra: previousBreadcrumb.queryParameters);
      } else {
        context.go(previousBreadcrumb.route);
      }
    } else {
      // Fallback to regular back navigation
      context.pop();
    }
  }

  /// Save route state for context preservation
  void saveRouteState(String route, Map<String, dynamic> state) {
    _routeState[route] = Map.from(state);
    
    // Save to navigation history
    _navigationHistory[route] = NavigationContext(
      currentRoute: route,
      state: state,
      timestamp: DateTime.now(),
      previousRoute: _breadcrumbs.isNotEmpty ? _breadcrumbs.last.route : null,
    );
  }

  /// Get saved route state
  Map<String, dynamic>? getRouteState(String route) {
    return _routeState[route];
  }

  /// Get navigation context
  NavigationContext? getNavigationContext(String route) {
    return _navigationHistory[route];
  }

  /// Clear route state
  void clearRouteState(String route) {
    _routeState.remove(route);
    _navigationHistory.remove(route);
  }

  /// Clear all saved states
  void clearAllStates() {
    _routeState.clear();
    _navigationHistory.clear();
  }

  /// Get route hierarchy for current navigation
  List<String> getRouteHierarchy() {
    return _breadcrumbs.map((crumb) => crumb.route).toList();
  }

  /// Check if can navigate back
  bool get canNavigateBack => _breadcrumbs.length > 1;

  /// Get current route title
  String getCurrentRouteTitle() {
    if (_breadcrumbs.isNotEmpty) {
      return _breadcrumbs.last.label;
    }
    return 'ODTrack Academia';
  }

  /// Initialize breadcrumbs for a route
  void initializeBreadcrumbs(String route) {
    clearBreadcrumbs();
    
    // Add default breadcrumbs based on route
    switch (route) {
      case '/dashboard':
        addBreadcrumb(const BreadcrumbItem(
          label: 'Dashboard',
          route: '/dashboard',
          icon: Icons.dashboard,
        ));
        break;
      case '/new-od':
        addBreadcrumb(const BreadcrumbItem(
          label: 'Dashboard',
          route: '/dashboard',
          icon: Icons.dashboard,
        ));
        addBreadcrumb(const BreadcrumbItem(
          label: 'New OD Request',
          route: '/new-od',
          icon: Icons.add,
        ));
        break;
      case '/staff-inbox':
        addBreadcrumb(const BreadcrumbItem(
          label: 'Dashboard',
          route: '/dashboard',
          icon: Icons.dashboard,
        ));
        addBreadcrumb(const BreadcrumbItem(
          label: 'Staff Inbox',
          route: '/staff-inbox',
          icon: Icons.inbox,
        ));
        break;
      case '/staff-analytics':
        addBreadcrumb(const BreadcrumbItem(
          label: 'Dashboard',
          route: '/dashboard',
          icon: Icons.dashboard,
        ));
        addBreadcrumb(const BreadcrumbItem(
          label: 'Staff Analytics',
          route: '/staff-analytics',
          icon: Icons.analytics,
        ));
        break;
      case '/export':
        addBreadcrumb(const BreadcrumbItem(
          label: 'Dashboard',
          route: '/dashboard',
          icon: Icons.dashboard,
        ));
        addBreadcrumb(const BreadcrumbItem(
          label: 'Export',
          route: '/export',
          icon: Icons.download,
        ));
        break;
      case '/timetable':
        addBreadcrumb(const BreadcrumbItem(
          label: 'Dashboard',
          route: '/dashboard',
          icon: Icons.dashboard,
        ));
        addBreadcrumb(const BreadcrumbItem(
          label: 'Timetable',
          route: '/timetable',
          icon: Icons.schedule,
        ));
        break;
      case '/staff-directory':
        addBreadcrumb(const BreadcrumbItem(
          label: 'Dashboard',
          route: '/dashboard',
          icon: Icons.dashboard,
        ));
        addBreadcrumb(const BreadcrumbItem(
          label: 'Staff Directory',
          route: '/staff-directory',
          icon: Icons.people,
        ));
        break;
      default:
        addBreadcrumb(const BreadcrumbItem(
          label: 'Dashboard',
          route: '/dashboard',
          icon: Icons.dashboard,
        ));
    }
  }
}