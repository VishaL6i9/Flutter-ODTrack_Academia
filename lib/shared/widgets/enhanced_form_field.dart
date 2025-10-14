import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odtrack_academia/utils/form_validators.dart';

/// Enhanced form field with real-time validation and contextual error messages
class EnhancedFormField extends StatefulWidget {
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final List<FormValidator>? validators;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final bool enableRealTimeValidation;
  final bool showErrorIcon;
  final bool showSuccessIcon;
  final String? helpText;
  final EdgeInsetsGeometry? contentPadding;

  const EnhancedFormField({
    super.key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.validator,
    this.validators,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.enableRealTimeValidation = true,
    this.showErrorIcon = true,
    this.showSuccessIcon = false,
    this.helpText,
    this.contentPadding,
  });

  @override
  State<EnhancedFormField> createState() => _EnhancedFormFieldState();
}

class _EnhancedFormFieldState extends State<EnhancedFormField> {
  String? _errorMessage;
  bool _hasBeenTouched = false;
  bool _isValid = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.enableRealTimeValidation) {
      _validateField(widget.controller?.text ?? '');
    }
  }

  void _validateField(String value) {
    if (!_hasBeenTouched && value.isEmpty) return;

    setState(() {
      _hasBeenTouched = true;
      _errorMessage = null;
      _isValid = false;

      // Use custom validators if provided
      if (widget.validators != null) {
        for (final validator in widget.validators!) {
          final result = validator.validate(value);
          if (result != null) {
            _errorMessage = result;
            return;
          }
        }
      }

      // Use traditional validator if provided
      if (widget.validator != null) {
        _errorMessage = widget.validator!(value);
      }

      _isValid = _errorMessage == null;
    });
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    if (!_hasBeenTouched || !widget.enableRealTimeValidation) {
      return null;
    }

    if (_errorMessage != null && widget.showErrorIcon) {
      return Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
      );
    }

    if (_isValid && widget.showSuccessIcon) {
      return Icon(
        Icons.check_circle_outline,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: _buildSuffixIcon(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
            contentPadding: widget.contentPadding,
            errorText: _hasBeenTouched ? _errorMessage : null,
            errorMaxLines: 3,
          ),
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: (value) {
            if (widget.enableRealTimeValidation) {
              _validateField(value);
            }
            widget.onChanged?.call(value);
          },
          onFieldSubmitted: widget.onFieldSubmitted,
          validator: widget.enableRealTimeValidation ? null : widget.validator,
        ),
        
        if (widget.helpText != null && _errorMessage == null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helpText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        
        if (_errorMessage != null && _hasBeenTouched) ...[
          const SizedBox(height: 4),
          _buildErrorMessage(),
        ],
      ],
    );
  }

  Widget _buildErrorMessage() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced password field with strength indicator
class EnhancedPasswordField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final List<FormValidator>? validators;
  final void Function(String)? onChanged;
  final bool showStrengthIndicator;
  final bool enableRealTimeValidation;
  final String? helpText;

  const EnhancedPasswordField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.validators,
    this.onChanged,
    this.showStrengthIndicator = true,
    this.enableRealTimeValidation = true,
    this.helpText,
  });

  @override
  State<EnhancedPasswordField> createState() => _EnhancedPasswordFieldState();
}

class _EnhancedPasswordFieldState extends State<EnhancedPasswordField> {
  bool _obscureText = true;
  PasswordStrength _strength = PasswordStrength.weak;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      _strength = FormValidators.getPasswordStrength(password);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EnhancedFormField(
          label: widget.label ?? 'Password',
          hint: widget.hint,
          controller: widget.controller,
          validator: widget.validator,
          validators: widget.validators,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: _toggleVisibility,
          ),
          obscureText: _obscureText,
          enableRealTimeValidation: widget.enableRealTimeValidation,
          helpText: widget.helpText,
          onChanged: (value) {
            if (widget.showStrengthIndicator) {
              _checkPasswordStrength(value);
            }
            widget.onChanged?.call(value);
          },
        ),
        
        if (widget.showStrengthIndicator && widget.controller?.text.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          _buildPasswordStrengthIndicator(),
        ],
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final theme = Theme.of(context);
    
    Color getStrengthColor() {
      switch (_strength) {
        case PasswordStrength.weak:
          return Colors.red;
        case PasswordStrength.medium:
          return Colors.orange;
        case PasswordStrength.strong:
          return Colors.green;
      }
    }

    String getStrengthText() {
      switch (_strength) {
        case PasswordStrength.weak:
          return 'Weak';
        case PasswordStrength.medium:
          return 'Medium';
        case PasswordStrength.strong:
          return 'Strong';
      }
    }

    double getStrengthValue() {
      switch (_strength) {
        case PasswordStrength.weak:
          return 0.33;
        case PasswordStrength.medium:
          return 0.66;
        case PasswordStrength.strong:
          return 1.0;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: getStrengthValue(),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(getStrengthColor()),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              getStrengthText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: getStrengthColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        if (_strength != PasswordStrength.strong) ...[
          const SizedBox(height: 4),
          Text(
            _getPasswordRequirements(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  String _getPasswordRequirements() {
    final password = widget.controller?.text ?? '';
    final requirements = <String>[];

    if (password.length < 8) {
      requirements.add('At least 8 characters');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      requirements.add('One uppercase letter');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      requirements.add('One lowercase letter');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      requirements.add('One number');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      requirements.add('One special character');
    }

    if (requirements.isEmpty) {
      return 'Password meets all requirements';
    }

    return 'Required: ${requirements.join(', ')}';
  }
}