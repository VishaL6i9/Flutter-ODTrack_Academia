import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced focus manager for keyboard navigation and accessibility
class EnhancedFocusManager {
  static EnhancedFocusManager? _instance;
  static EnhancedFocusManager get instance => _instance ??= EnhancedFocusManager._();
  
  EnhancedFocusManager._();

  final Map<String, FocusNode> _namedFocusNodes = {};
  final List<FocusNode> _focusHistory = [];
  FocusNode? _currentFocus;

  /// Register a named focus node
  void registerFocusNode(String name, FocusNode focusNode) {
    _namedFocusNodes[name] = focusNode;
  }

  /// Unregister a named focus node
  void unregisterFocusNode(String name) {
    _namedFocusNodes.remove(name);
  }

  /// Get a named focus node
  FocusNode? getFocusNode(String name) {
    return _namedFocusNodes[name];
  }

  /// Focus on a named widget
  void focusNamed(String name) {
    final focusNode = _namedFocusNodes[name];
    if (focusNode != null && focusNode.canRequestFocus) {
      _addToHistory(_currentFocus);
      focusNode.requestFocus();
      _currentFocus = focusNode;
    }
  }

  /// Focus on the next focusable widget
  void focusNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Focus on the previous focusable widget
  void focusPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Go back to the previous focus
  void focusBack() {
    if (_focusHistory.isNotEmpty) {
      final previousFocus = _focusHistory.removeLast();
      if (previousFocus.canRequestFocus) {
        previousFocus.requestFocus();
        _currentFocus = previousFocus;
      }
    }
  }

  /// Clear focus history
  void clearHistory() {
    _focusHistory.clear();
  }

  /// Add focus node to history
  void _addToHistory(FocusNode? focusNode) {
    if (focusNode != null && !_focusHistory.contains(focusNode)) {
      _focusHistory.add(focusNode);
      // Keep history limited to prevent memory issues
      if (_focusHistory.length > 10) {
        _focusHistory.removeAt(0);
      }
    }
  }

  /// Create keyboard shortcuts for navigation
  Map<ShortcutActivator, Intent> getNavigationShortcuts() {
    return {
      const SingleActivator(LogicalKeyboardKey.tab): const NextFocusIntent(),
      const SingleActivator(LogicalKeyboardKey.tab, shift: true): const PreviousFocusIntent(),
      const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
      const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
      const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
      const SingleActivator(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(TraversalDirection.up),
      const SingleActivator(LogicalKeyboardKey.arrowDown): const DirectionalFocusIntent(TraversalDirection.down),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): const DirectionalFocusIntent(TraversalDirection.left),
      const SingleActivator(LogicalKeyboardKey.arrowRight): const DirectionalFocusIntent(TraversalDirection.right),
    };
  }

  /// Create keyboard actions for navigation
  Map<Type, Action<Intent>> getNavigationActions(BuildContext context) {
    return {
      NextFocusIntent: CallbackAction<NextFocusIntent>(
        onInvoke: (intent) => focusNext(context),
      ),
      PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
        onInvoke: (intent) => focusPrevious(context),
      ),
      DismissIntent: CallbackAction<DismissIntent>(
        onInvoke: (intent) => Navigator.of(context).maybePop(),
      ),
      DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
        onInvoke: (intent) {
          switch (intent.direction) {
            case TraversalDirection.up:
              FocusScope.of(context).focusInDirection(TraversalDirection.up);
              break;
            case TraversalDirection.down:
              FocusScope.of(context).focusInDirection(TraversalDirection.down);
              break;
            case TraversalDirection.left:
              FocusScope.of(context).focusInDirection(TraversalDirection.left);
              break;
            case TraversalDirection.right:
              FocusScope.of(context).focusInDirection(TraversalDirection.right);
              break;
          }
          return null;
        },
      ),
    };
  }

  /// Dispose all focus nodes
  void dispose() {
    for (final focusNode in _namedFocusNodes.values) {
      focusNode.dispose();
    }
    _namedFocusNodes.clear();
    _focusHistory.clear();
    _currentFocus = null;
  }
}

/// Custom focus traversal policy for better keyboard navigation
class AccessibleFocusTraversalPolicy extends ReadingOrderTraversalPolicy {
  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants, FocusNode currentNode) {
    // Filter out nodes that can't request focus
    final focusableNodes = descendants.where((node) => node.canRequestFocus);
    
    // Sort by reading order (top to bottom, left to right)
    return super.sortDescendants(focusableNodes, currentNode);
  }

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    // Allow directional navigation
    return super.inDirection(currentNode, direction);
  }
}