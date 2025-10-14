import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odtrack_academia/core/accessibility/accessibility_service.dart';
import 'package:odtrack_academia/core/accessibility/focus_manager.dart';

/// Accessible text field with enhanced screen reader support
class AccessibleTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool required;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final FocusNode? focusNode;
  final String? semanticLabel;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.required = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.focusNode,
    this.semanticLabel,
  });

  @override
  State<AccessibleTextField> createState() => _AccessibleTextFieldState();
}

class _AccessibleTextFieldState extends State<AccessibleTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  final AccessibilityService _accessibilityService = AccessibilityService.instance;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    
    // Register focus node for keyboard navigation
    EnhancedFocusManager.instance.registerFocusNode(
      'text_field_${widget.label}',
      _focusNode,
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    EnhancedFocusManager.instance.unregisterFocusNode('text_field_${widget.label}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = _accessibilityService.isHighContrastEnabled;
    
    String semanticLabel = widget.semanticLabel ?? widget.label;
    if (widget.required) {
      semanticLabel += ', required';
    }
    if (widget.hint != null) {
      semanticLabel += ', ${widget.hint}';
    }
    if (widget.errorText != null) {
      semanticLabel += ', error: ${widget.errorText}';
    }

    return Semantics(
      textField: true,
      label: semanticLabel,
      enabled: widget.enabled,
      obscured: widget.obscureText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(
                  text: widget.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: widget.enabled 
                        ? theme.colorScheme.onSurface 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: _accessibilityService.isBoldTextEnabled 
                        ? FontWeight.bold 
                        : FontWeight.w500,
                  ),
                  children: [
                    if (widget.required)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Focus(
            focusNode: _focusNode,
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                _accessibilityService.announceToScreenReader(
                  'Focused on ${widget.label} text field'
                );
              }
            },
            child: TextFormField(
              controller: _controller,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              enabled: widget.enabled,
              validator: widget.validator,
              onChanged: (value) {
                widget.onChanged?.call(value);
                // Announce validation errors to screen reader
                if (widget.validator != null) {
                  final error = widget.validator!(value);
                  if (error != null) {
                    _accessibilityService.announceToScreenReader('Error: $error');
                  }
                }
              },
              onFieldSubmitted: widget.onSubmitted,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              inputFormatters: widget.inputFormatters,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.suffixIcon,
                errorText: widget.errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isHighContrast 
                        ? theme.colorScheme.onSurface 
                        : theme.colorScheme.outline,
                    width: isHighContrast ? 2 : 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isHighContrast 
                        ? theme.colorScheme.onSurface 
                        : theme.colorScheme.outline,
                    width: isHighContrast ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accessible dropdown field with screen reader support
class AccessibleDropdownField<T> extends StatefulWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final bool enabled;
  final bool required;
  final String? Function(T?)? validator;
  final FocusNode? focusNode;
  final String? semanticLabel;

  const AccessibleDropdownField({
    super.key,
    required this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
    this.required = false,
    this.validator,
    this.focusNode,
    this.semanticLabel,
  });

  @override
  State<AccessibleDropdownField<T>> createState() => _AccessibleDropdownFieldState<T>();
}

class _AccessibleDropdownFieldState<T> extends State<AccessibleDropdownField<T>> {
  late FocusNode _focusNode;
  final AccessibilityService _accessibilityService = AccessibilityService.instance;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    
    // Register focus node for keyboard navigation
    EnhancedFocusManager.instance.registerFocusNode(
      'dropdown_${widget.label}',
      _focusNode,
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    EnhancedFocusManager.instance.unregisterFocusNode('dropdown_${widget.label}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = _accessibilityService.isHighContrastEnabled;
    
    String semanticLabel = widget.semanticLabel ?? widget.label;
    if (widget.required) {
      semanticLabel += ', required';
    }
    if (widget.hint != null) {
      semanticLabel += ', ${widget.hint}';
    }
    semanticLabel += ', dropdown menu';

    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(
                  text: widget.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: widget.enabled 
                        ? theme.colorScheme.onSurface 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: _accessibilityService.isBoldTextEnabled 
                        ? FontWeight.bold 
                        : FontWeight.w500,
                  ),
                  children: [
                    if (widget.required)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Focus(
            focusNode: _focusNode,
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                _accessibilityService.announceToScreenReader(
                  'Focused on ${widget.label} dropdown'
                );
              }
            },
            child: DropdownButtonFormField<T>(
              value: widget.value,
              items: widget.items,
              onChanged: widget.enabled ? (value) {
                widget.onChanged?.call(value);
                if (value != null) {
                  _accessibilityService.announceToScreenReader(
                    'Selected ${value.toString()}'
                  );
                }
              } : null,
              validator: widget.validator,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isHighContrast 
                        ? theme.colorScheme.onSurface 
                        : theme.colorScheme.outline,
                    width: isHighContrast ? 2 : 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isHighContrast 
                        ? theme.colorScheme.onSurface 
                        : theme.colorScheme.outline,
                    width: isHighContrast ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accessible checkbox with enhanced semantics
class AccessibleCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool?)? onChanged;
  final bool enabled;
  final String? semanticLabel;

  const AccessibleCheckbox({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService.instance;
    
    String effectiveSemanticLabel = semanticLabel ?? label;
    effectiveSemanticLabel += value ? ', checked' : ', unchecked';

    return Semantics(
      label: effectiveSemanticLabel,
      checked: value,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? () {
          onChanged?.call(!value);
          accessibilityService.announceToScreenReader(
            value ? '$label unchecked' : '$label checked'
          );
          accessibilityService.provideHapticFeedback();
        } : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: enabled ? onChanged : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: enabled 
                        ? theme.colorScheme.onSurface 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: accessibilityService.isBoldTextEnabled 
                        ? FontWeight.w600 
                        : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}