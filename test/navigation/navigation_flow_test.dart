import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odtrack_academia/core/navigation/navigation_service.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';

void main() {
  group('Navigation Service Tests', () {
    late NavigationService navigationService;

    setUp(() {
      navigationService = NavigationService.instance;
      navigationService.clearBreadcrumbs();
      navigationService.clearAllStates();
    });

    test('should add breadcrumbs correctly', () {
      const breadcrumb1 = BreadcrumbItem(
        label: 'Dashboard',
        route: '/dashboard',
        icon: Icons.dashboard,
      );
      const breadcrumb2 = BreadcrumbItem(
        label: 'Staff Inbox',
        route: '/staff-inbox',
        icon: Icons.inbox,
      );

      navigationService.addBreadcrumb(breadcrumb1);
      navigationService.addBreadcrumb(breadcrumb2);

      expect(navigationService.breadcrumbs.length, equals(2));
      expect(navigationService.breadcrumbs.first.label, equals('Dashboard'));
      expect(navigationService.breadcrumbs.last.label, equals('Staff Inbox'));
    });

    test('should remove duplicate breadcrumbs', () {
      const breadcrumb = BreadcrumbItem(
        label: 'Dashboard',
        route: '/dashboard',
        icon: Icons.dashboard,
      );

      navigationService.addBreadcrumb(breadcrumb);
      navigationService.addBreadcrumb(breadcrumb);

      expect(navigationService.breadcrumbs.length, equals(1));
    });

    test('should limit breadcrumb count', () {
      for (int i = 0; i < 10; i++) {
        navigationService.addBreadcrumb(BreadcrumbItem(
          label: 'Item $i',
          route: '/item$i',
        ));
      }

      expect(navigationService.breadcrumbs.length, lessThanOrEqualTo(5));
    });

    test('should remove breadcrumbs after specified route', () {
      const breadcrumb1 = BreadcrumbItem(label: 'Dashboard', route: '/dashboard');
      const breadcrumb2 = BreadcrumbItem(label: 'Inbox', route: '/inbox');
      const breadcrumb3 = BreadcrumbItem(label: 'Details', route: '/details');

      navigationService.addBreadcrumb(breadcrumb1);
      navigationService.addBreadcrumb(breadcrumb2);
      navigationService.addBreadcrumb(breadcrumb3);

      navigationService.removeBreadcrumbsAfter('/inbox');

      expect(navigationService.breadcrumbs.length, equals(2));
      expect(navigationService.breadcrumbs.last.route, equals('/inbox'));
    });

    test('should save and retrieve route state', () {
      const route = '/test-route';
      final state = {'key': 'value', 'number': 42};

      navigationService.saveRouteState(route, state);
      final retrievedState = navigationService.getRouteState(route);

      expect(retrievedState, equals(state));
    });

    test('should get navigation context', () {
      const route = '/test-route';
      final state = {'test': 'data'};

      navigationService.saveRouteState(route, state);
      final context = navigationService.getNavigationContext(route);

      expect(context, isNotNull);
      expect(context!.currentRoute, equals(route));
      expect(context.state, equals(state));
      expect(context.timestamp, isA<DateTime>());
    });

    test('should initialize breadcrumbs for different routes', () {
      navigationService.initializeBreadcrumbs('/staff-inbox');
      
      expect(navigationService.breadcrumbs.length, equals(2));
      expect(navigationService.breadcrumbs.first.label, equals('Dashboard'));
      expect(navigationService.breadcrumbs.last.label, equals('Staff Inbox'));
    });

    test('should check if can navigate back', () {
      expect(navigationService.canNavigateBack, isFalse);

      navigationService.addBreadcrumb(const BreadcrumbItem(
        label: 'Dashboard',
        route: '/dashboard',
      ));
      expect(navigationService.canNavigateBack, isFalse);

      navigationService.addBreadcrumb(const BreadcrumbItem(
        label: 'Inbox',
        route: '/inbox',
      ));
      expect(navigationService.canNavigateBack, isTrue);
    });

    test('should get current route title', () {
      expect(navigationService.getCurrentRouteTitle(), equals('ODTrack Academia'));

      navigationService.addBreadcrumb(const BreadcrumbItem(
        label: 'Dashboard',
        route: '/dashboard',
      ));
      expect(navigationService.getCurrentRouteTitle(), equals('Dashboard'));
    });

    test('should get route hierarchy', () {
      navigationService.addBreadcrumb(const BreadcrumbItem(
        label: 'Dashboard',
        route: '/dashboard',
      ));
      navigationService.addBreadcrumb(const BreadcrumbItem(
        label: 'Inbox',
        route: '/inbox',
      ));

      final hierarchy = navigationService.getRouteHierarchy();
      expect(hierarchy, equals(['/dashboard', '/inbox']));
    });
  });

  group('Navigation Flow Integration Tests', () {
    testWidgets('should navigate with breadcrumbs', (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Home'),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => Scaffold(
              body: Column(
                children: [
                  const Text('Dashboard'),
                  ElevatedButton(
                    onPressed: () {
                      NavigationService.instance.navigateWithBreadcrumb(
                        context,
                        const BreadcrumbItem(
                          label: 'Staff Inbox',
                          route: '/staff-inbox',
                        ),
                      );
                    },
                    child: const Text('Go to Inbox'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/staff-inbox',
            builder: (context, state) => const Scaffold(
              body: Text('Staff Inbox'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Navigate to dashboard
      router.go('/dashboard');
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);

      // Navigate to inbox using breadcrumb navigation
      await tester.tap(find.text('Go to Inbox'));
      await tester.pumpAndSettle();

      expect(find.text('Staff Inbox'), findsOneWidget);

      // Check breadcrumbs were added
      final navigationService = NavigationService.instance;
      expect(navigationService.breadcrumbs.length, greaterThan(0));
    });

    testWidgets('should preserve navigation context', (WidgetTester tester) async {
      final navigationService = NavigationService.instance;
      
      // Save some state
      navigationService.saveRouteState('/test', {'scrollPosition': 100});
      
      // Retrieve state
      final state = navigationService.getRouteState('/test');
      expect(state?['scrollPosition'], equals(100));
    });
  });

  group('Breadcrumb Item Tests', () {
    test('should create breadcrumb item correctly', () {
      const breadcrumb = BreadcrumbItem(
        label: 'Test Page',
        route: '/test',
        icon: Icons.science,
        queryParameters: {'param': 'value'},
      );

      expect(breadcrumb.label, equals('Test Page'));
      expect(breadcrumb.route, equals('/test'));
      expect(breadcrumb.icon, equals(Icons.science));
      expect(breadcrumb.queryParameters, equals({'param': 'value'}));
    });

    test('should compare breadcrumb items correctly', () {
      const breadcrumb1 = BreadcrumbItem(
        label: 'Test',
        route: '/test',
      );
      const breadcrumb2 = BreadcrumbItem(
        label: 'Test',
        route: '/test',
      );
      const breadcrumb3 = BreadcrumbItem(
        label: 'Different',
        route: '/different',
      );

      expect(breadcrumb1, equals(breadcrumb2));
      expect(breadcrumb1, isNot(equals(breadcrumb3)));
    });
  });

  group('Navigation Context Tests', () {
    test('should create navigation context correctly', () {
      final timestamp = DateTime.now();
      final context = NavigationContext(
        currentRoute: '/test',
        state: {'key': 'value'},
        timestamp: timestamp,
        previousRoute: '/previous',
      );

      expect(context.currentRoute, equals('/test'));
      expect(context.state, equals({'key': 'value'}));
      expect(context.timestamp, equals(timestamp));
      expect(context.previousRoute, equals('/previous'));
    });

    test('should copy navigation context with changes', () {
      final originalContext = NavigationContext(
        currentRoute: '/original',
        state: {'original': 'data'},
        timestamp: DateTime.now(),
      );

      final copiedContext = originalContext.copyWith(
        currentRoute: '/new',
        state: {'new': 'data'},
      );

      expect(copiedContext.currentRoute, equals('/new'));
      expect(copiedContext.state, equals({'new': 'data'}));
      expect(copiedContext.timestamp, equals(originalContext.timestamp));
    });
  });

  group('Route Initialization Tests', () {
    test('should initialize breadcrumbs for dashboard route', () {
      final navigationService = NavigationService.instance;
      navigationService.initializeBreadcrumbs(AppConstants.dashboardRoute);

      expect(navigationService.breadcrumbs.length, equals(1));
      expect(navigationService.breadcrumbs.first.label, equals('Dashboard'));
      expect(navigationService.breadcrumbs.first.route, equals(AppConstants.dashboardRoute));
    });

    test('should initialize breadcrumbs for new OD route', () {
      final navigationService = NavigationService.instance;
      navigationService.initializeBreadcrumbs(AppConstants.newOdRoute);

      expect(navigationService.breadcrumbs.length, equals(2));
      expect(navigationService.breadcrumbs.first.label, equals('Dashboard'));
      expect(navigationService.breadcrumbs.last.label, equals('New OD Request'));
    });

    test('should initialize breadcrumbs for staff inbox route', () {
      final navigationService = NavigationService.instance;
      navigationService.initializeBreadcrumbs(AppConstants.staffInboxRoute);

      expect(navigationService.breadcrumbs.length, equals(2));
      expect(navigationService.breadcrumbs.first.label, equals('Dashboard'));
      expect(navigationService.breadcrumbs.last.label, equals('Staff Inbox'));
    });

    test('should initialize breadcrumbs for unknown route', () {
      final navigationService = NavigationService.instance;
      navigationService.initializeBreadcrumbs('/unknown-route');

      expect(navigationService.breadcrumbs.length, equals(1));
      expect(navigationService.breadcrumbs.first.label, equals('Dashboard'));
    });
  });
}