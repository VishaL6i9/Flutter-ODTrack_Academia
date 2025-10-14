import 'package:flutter/material.dart';
import 'package:odtrack_academia/core/accessibility/accessibility_service.dart';
import 'package:odtrack_academia/core/accessibility/focus_manager.dart';

/// Accessible button with enhanced screen reader support and keyboard navigation
class AccessibleButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool enabled;
  final String? tooltip;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final ButtonType type;

  const AccessibleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style,
    this.icon,
    this.enabled = true,
    this.tooltip,
    this.semanticLabel,
    this.focusNode,
    this.type = ButtonType.elevated,
  });

  const AccessibleButton.elevated({
    super.key,
    required this.label,
    this.onPressed,
    this.style,
    this.icon,
    this.enabled = true,
    this.tooltip,
    this.semanticLabel,
    this.focusNode,
  }) : type = ButtonType.elevated;

  const AccessibleButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.style,
    this.icon,
    this.enabled = true,
    this.tooltip,
    this.semanticLabel,
    this.focusNode,
  }) : type = ButtonType.outlined;

  const AccessibleButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.style,
    this.icon,
    this.enabled = true,
    this.tooltip,
    this.semanticLabel,
    this.focusNode,
  }) : type = ButtonType.text;

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton> {
  late FocusNode _focusNode;
  final AccessibilityService _accessibilityService = AccessibilityService.instance;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    
    // Register focus node for keyboard navigation
    EnhancedFocusManager.instance.registerFocusNode(
      'button_${widget.label}',
      _focusNode,
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    EnhancedFocusManager.instance.unregisterFocusNode('button_${widget.label}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && widget.onPressed != null;
    
    String semanticLabel = widget.semanticLabel ?? widget.label;
    if (!isEnabled) {
      semanticLabel += ', disabled';
    }
    if (widget.tooltip != null) {
      semanticLabel += ', ${widget.tooltip}';
    }

    Widget buttonChild = widget.icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.icon!,
              const SizedBox(width: 8),
              Text(widget.label),
            ],
          )
        : Text(widget.label);

    Widget button;
    switch (widget.type) {
      case ButtonType.elevated:
        button = ElevatedButton(
          onPressed: isEnabled ? _handlePressed : null,
          style: widget.style,
          focusNode: _focusNode,
          child: buttonChild,
        );
        break;
      case ButtonType.outlined:
        button = OutlinedButton(
          onPressed: isEnabled ? _handlePressed : null,
          style: widget.style,
          focusNode: _focusNode,
          child: buttonChild,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: isEnabled ? _handlePressed : null,
          style: widget.style,
          focusNode: _focusNode,
          child: buttonChild,
        );
        break;
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: isEnabled,
      onTap: isEnabled ? _handlePressed : null,
      child: Tooltip(
        message: widget.tooltip ?? widget.label,
        child: Focus(
          focusNode: _focusNode,
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              _accessibilityService.announceToScreenReader(
                'Focused on ${widget.label} button'
              );
            }
          },
          child: button,
        ),
      ),
    );
  }

  void _handlePressed() {
    _accessibilityService.provideHapticFeedback();
    _accessibilityService.announceToScreenReader('${widget.label} button pressed');
    widget.onPressed?.call();
  }
}

/// Accessible icon button with enhanced semantics
class AccessibleIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final bool enabled;
  final FocusNode? focusNode;
  final double? iconSize;
  final Color? color;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.enabled = true,
    this.focusNode,
    this.iconSize,
    this.color,
  });

  @override
  State<AccessibleIconButton> createState() => _AccessibleIconButtonState();
}

class _AccessibleIconButtonState extends State<AccessibleIconButton> {
  late FocusNode _focusNode;
  final AccessibilityService _accessibilityService = AccessibilityService.instance;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    
    // Register focus node for keyboard navigation
    EnhancedFocusManager.instance.registerFocusNode(
      'icon_button_${widget.tooltip ?? widget.icon.toString()}',
      _focusNode,
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    EnhancedFocusManager.instance.unregisterFocusNode(
      'icon_button_${widget.tooltip ?? widget.icon.toString()}'
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && widget.onPressed != null;
    
    String semanticLabel = widget.semanticLabel ?? widget.tooltip ?? 'Button';
    if (!isEnabled) {
      semanticLabel += ', disabled';
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: isEnabled,
      onTap: isEnabled ? _handlePressed : null,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            _accessibilityService.announceToScreenReader(
              'Focused on ${widget.tooltip ?? 'button'}'
            );
          }
        },
        child: IconButton(
          icon: Icon(widget.icon),
          onPressed: isEnabled ? _handlePressed : null,
          tooltip: widget.tooltip,
          focusNode: _focusNode,
          iconSize: widget.iconSize,
          color: widget.color,
        ),
      ),
    );
  }

  void _handlePressed() {
    _accessibilityService.provideHapticFeedback();
    _accessibilityService.announceToScreenReader(
      '${widget.tooltip ?? 'Button'} pressed'
    );
    widget.onPressed?.call();
  }
}

/// Accessible floating action button
class AccessibleFloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final String? semanticLabel;
  final bool enabled;
  final FocusNode? focusNode;

  const AccessibleFloatingActionButton({
    super.key,
    this.onPressed,
    required this.child,
    this.tooltip,
    this.semanticLabel,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<AccessibleFloatingActionButton> createState() => _AccessibleFloatingActionButtonState();
}

class _AccessibleFloatingActionButtonState extends State<AccessibleFloatingActionButton> {
  late FocusNode _focusNode;
  final AccessibilityService _accessibilityService = AccessibilityService.instance;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    
    // Register focus node for keyboard navigation
    EnhancedFocusManager.instance.registerFocusNode(
      'fab_${widget.tooltip ?? 'floating_action_button'}',
      _focusNode,
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    EnhancedFocusManager.instance.unregisterFocusNode(
      'fab_${widget.tooltip ?? 'floating_action_button'}'
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && widget.onPressed != null;
    
    String semanticLabel = widget.semanticLabel ?? widget.tooltip ?? 'Floating action button';
    if (!isEnabled) {
      semanticLabel += ', disabled';
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: isEnabled,
      onTap: isEnabled ? _handlePressed : null,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            _accessibilityService.announceToScreenReader(
              'Focused on ${widget.tooltip ?? 'floating action button'}'
            );
          }
        },
        child: FloatingActionButton(
          onPressed: isEnabled ? _handlePressed : null,
          tooltip: widget.tooltip,
          focusNode: _focusNode,
          child: widget.child,
        ),
      ),
    );
  }

  void _handlePressed() {
    _accessibilityService.provideHapticFeedback();
    _accessibilityService.announceToScreenReader(
      '${widget.tooltip ?? 'Floating action button'} pressed'
    );
    widget.onPressed?.call();
  }
}

enum ButtonType {
  elevated,
  outlined,
  text,
}