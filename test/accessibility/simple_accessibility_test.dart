import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/core/accessibility/accessibility_service.dart';
import 'package:odtrack_academia/core/accessibility/focus_manager.dart';
import 'package:odtrack_academia/core/navigation/navigation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Accessibility Service Unit Tests', () {
    late AccessibilityService accessibilityService;

    setUp(() {
      accessibilityService = AccessibilityService.instance;
    });

    test('should provide semantic labels correctly', () {
      final label = accessibilityService.getSemanticLabel(
        label: 'Submit',
        hint: 'Submit the form',
        value: 'Button',
        isSelected: true,
        isEnabled: true,
      );

      expect(label, contains('Submit'));
      expect(label, contains('Button'));
      expect(label, contains('selected'));
      expect(label, contains('Submit the form'));
    });

    test('should create button semantics correctly', () {
      final semantics = accessibilityService.getButtonSemantics(
        label: 'Test Button',
        hint: 'Press to test',
        enabled: true,
        onTap: () {},
      );

      expect(semantics.label, equals('Test Button'));
      expect(semantics.hint, equals('Press to test'));
      expect(semantics.enabled, isTrue);
      expect(semantics.button, isTrue);
    });

    test('should create text field semantics correctly', () {
      final semantics = accessibilityService.getTextFieldSemantics(
        label: 'Email',
        hint: 'Enter your email',
        value: 'test@example.com',
        enabled: true,
        obscureText: false,
      );

      expect(semantics.label, equals('Email'));
      expect(semantics.hint, equals('Enter your email'));
      expect(semantics.value, equals('test@example.com'));
      expect(semantics.enabled, isTrue);
      expect(semantics.textField, isTrue);
      expect(semantics.obscured, isFalse);
    });

    test('should create list item semantics correctly', () {
      final semantics = accessibilityService.getListItemSemantics(
        label: 'Item 1',
        hint: 'Tap to select',
        index: 0,
        total: 5,
        selected: false,
        onTap: () {},
      );

      expect(semantics.label, equals('Item 1, item 1 of 5'));
      expect(semantics.hint, equals('Tap to select'));
      expect(semantics.selected, isFalse);
    });

    test('should handle accessibility features detection', () {
      // These will return false in test environment, but we can test the methods exist
      expect(accessibilityService.isScreenReaderEnabled, isA<bool>());
      expect(accessibilityService.isHighContrastEnabled, isA<bool>());
      expect(accessibilityService.isBoldTextEnabled, isA<bool>());
      expect(accessibilityService.isReduceMotionEnabled, isA<bool>());
      expect(accessibilityService.supportsAccessibility, isA<bool>());
    });

    test('should provide accessible animation duration', () {
      const defaultDuration = Duration(milliseconds: 300);
      final accessibleDuration = accessibilityService.getAccessibleAnimationDuration(defaultDuration);
      
      // In test environment, this should return the default duration
      expect(accessibleDuration, equals(defaultDuration));
    });
  });

  group('Focus Manager Unit Tests', () {
    late EnhancedFocusManager focusManager;

    setUp(() {
      focusManager = EnhancedFocusManager.instance;
    });

    tearDown(() {
      focusManager.dispose();
    });

    test('should register and retrieve focus nodes', () {
      final focusNode = FocusNode();
      focusManager.registerFocusNode('test_node', focusNode);

      final retrievedNode = focusManager.getFocusNode('test_node');
      expect(retrievedNode, equals(focusNode));

      focusManager.unregisterFocusNode('test_node');
      final removedNode = focusManager.getFocusNode('test_node');
      expect(removedNode, isNull);

      focusNode.dispose();
    });

    test('should provide navigation shortcuts', () {
      final shortcuts = focusManager.getNavigationShortcuts();
      
      expect(shortcuts, isNotEmpty);
      expect(shortcuts.keys.any((key) => key.toString().contains('Tab')), isTrue);
      expect(shortcuts.keys.any((key) => key.toString().contains('Escape')), isTrue);
      expect(shortcuts.keys.any((key) => key.toString().contains('Enter')), isTrue);
    });

    test('should clear focus history', () {
      focusManager.clearHistory();
      // Test passes if no exception is thrown
      expect(true, isTrue);
    });
  });

  group('Navigation Service Unit Tests', () {
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

    test('should initialize breadcrumbs for different routes', () {
      navigationService.initializeBreadcrumbs('/staff-inbox');
      
      expect(navigationService.breadcrumbs.length, equals(2));
      expect(navigationService.breadcrumbs.first.label, equals('Dashboard'));
      expect(navigationService.breadcrumbs.last.label, equals('Staff Inbox'));
    });
  });

  group('BreadcrumbItem Tests', () {
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

  group('NavigationContext Tests', () {
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
}