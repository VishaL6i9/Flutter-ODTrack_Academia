import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

/// Service for managing accessibility features and settings
class AccessibilityService {
  static AccessibilityService? _instance;
  static AccessibilityService get instance => _instance ??= AccessibilityService._();
  
  AccessibilityService._();

  /// Check if screen reader is enabled
  bool get isScreenReaderEnabled {
    return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.accessibleNavigation;
  }

  /// Check if high contrast mode is enabled
  bool get isHighContrastEnabled {
    return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.highContrast;
  }

  /// Check if reduce motion is enabled
  bool get isReduceMotionEnabled {
    return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  /// Check if bold text is enabled
  bool get isBoldTextEnabled {
    return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.boldText;
  }

  /// Get text scale factor for accessibility
  double getTextScaleFactor(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(14.0) / 14.0;
  }

  /// Announce message to screen reader
  void announceToScreenReader(String message) {
    if (isScreenReaderEnabled) {
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  /// Provide haptic feedback for accessibility
  void provideHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  /// Focus on a specific widget
  void focusWidget(FocusNode focusNode) {
    focusNode.requestFocus();
  }

  /// Get semantic label for screen readers
  String getSemanticLabel({
    required String label,
    String? hint,
    String? value,
    bool? isSelected,
    bool? isEnabled,
  }) {
    final buffer = StringBuffer(label);
    
    if (value != null && value.isNotEmpty) {
      buffer.write(', $value');
    }
    
    if (isSelected == true) {
      buffer.write(', selected');
    }
    
    if (isEnabled == false) {
      buffer.write(', disabled');
    }
    
    if (hint != null && hint.isNotEmpty) {
      buffer.write(', $hint');
    }
    
    return buffer.toString();
  }

  /// Get accessible button semantics
  SemanticsProperties getButtonSemantics({
    required String label,
    String? hint,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return SemanticsProperties(
      label: label,
      hint: hint,
      enabled: enabled,
      button: true,
      onTap: onTap,
    );
  }

  /// Get accessible text field semantics
  SemanticsProperties getTextFieldSemantics({
    required String label,
    String? hint,
    String? value,
    bool enabled = true,
    bool obscureText = false,
  }) {
    return SemanticsProperties(
      label: label,
      hint: hint,
      value: value,
      enabled: enabled,
      textField: true,
      obscured: obscureText,
    );
  }

  /// Get accessible list item semantics
  SemanticsProperties getListItemSemantics({
    required String label,
    String? hint,
    int? index,
    int? total,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    String fullLabel = label;
    if (index != null && total != null) {
      fullLabel = '$label, item ${index + 1} of $total';
    }
    
    return SemanticsProperties(
      label: fullLabel,
      hint: hint,
      selected: selected,
      onTap: onTap,
    );
  }

  /// Check if device supports accessibility features
  bool get supportsAccessibility {
    return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.accessibleNavigation ||
           WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.highContrast ||
           WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.boldText;
  }

  /// Get accessibility-friendly duration for animations
  Duration getAccessibleAnimationDuration(Duration defaultDuration) {
    if (isReduceMotionEnabled) {
      return Duration.zero;
    }
    return defaultDuration;
  }

  /// Create accessible focus traversal order
  List<FocusNode> createFocusTraversalOrder(List<FocusNode> nodes) {
    return nodes.where((node) => node.canRequestFocus).toList();
  }
}