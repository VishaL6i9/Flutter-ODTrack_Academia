import 'package:flutter/material.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';
import 'package:odtrack_academia/shared/widgets/enhanced_error_dialog.dart';

/// Enhanced form widget with improved validation and error handling
class EnhancedForm extends StatefulWidget {
  final GlobalKey<FormState>? formKey;
  final Widget child;
  final VoidCallback? onSubmit;
  final bool enableAutoValidation;
  final bool showProgressIndicator;
  final String? submitButtonText;
  final IconData? submitButtonIcon;
  final bool isSubmitting;
  final BaseError? error;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  const EnhancedForm({
    super.key,
    this.formKey,
    required this.child,
    this.onSubmit,
    this.enableAutoValidation = true,
    this.showProgressIndicator = true,
    this.submitButtonText,
    this.submitButtonIcon,
    this.isSubmitting = false,
    this.error,
    this.onRetry,
    this.padding,
    this.scrollable = true,
  });

  @override
  State<EnhancedForm> createState() => _EnhancedFormState();
}

class _EnhancedFormState extends State<EnhancedForm> {
  late GlobalKey<FormState> _formKey;
  bool _hasShownError = false;

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey ?? GlobalKey<FormState>();
  }

  @override
  void didUpdateWidget(EnhancedForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Show error dialog when error changes
    if (widget.error != null && widget.error != oldWidget.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog();
      });
    }
  }

  void _showErrorDialog() {
    if (widget.error != null && !_hasShownError) {
      _hasShownError = true;
      
      // Show different UI based on error severity
      if (widget.error!.severity == ErrorSeverity.low) {
        ErrorSnackBar.show(
          context,
          widget.error!,
          onRetry: widget.onRetry,
        );
      } else {
        EnhancedErrorDialog.show(
          context,
          widget.error!,
          onRetry: widget.onRetry,
          onDismiss: () => _hasShownError = false,
        );
      }
    }
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      autovalidateMode: widget.enableAutoValidation
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.child,

          if (widget.onSubmit != null) ...[
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton.icon(
      onPressed: widget.isSubmitting ? null : _handleSubmit,
      icon: widget.isSubmitting
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : Icon(widget.submitButtonIcon ?? Icons.check),
      label: Text(
        widget.isSubmitting 
            ? 'Processing...' 
            : (widget.submitButtonText ?? 'Submit'),
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  void _handleSubmit() {
    // Reset error state
    _hasShownError = false;
    
    // Validate form
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit?.call();
    } else {
      // Show validation error
      _showValidationError();
    }
  }

  void _showValidationError() {
    final validationError = ValidationError(
      code: 'FORM_VALIDATION_FAILED',
      message: 'Form validation failed',
      userMessage: 'Please correct the errors above and try again.',
      field: 'form',
      severity: ErrorSeverity.low,
    );
    
    ErrorSnackBar.show(context, validationError);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _buildContent();
    
    if (widget.scrollable) {
      content = SingleChildScrollView(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: content,
      );
    } else if (widget.padding != null) {
      content = Padding(
        padding: widget.padding!,
        child: content,
      );
    }
    
    return content;
  }
}

/// Form field wrapper with enhanced error display
class FormFieldWrapper extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? helpText;
  final bool required;
  final EdgeInsetsGeometry? margin;

  const FormFieldWrapper({
    super.key,
    required this.child,
    this.label,
    this.helpText,
    this.required = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            RichText(
              text: TextSpan(
                text: label!,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                children: required
                    ? [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          child,
          
          if (helpText != null) ...[
            const SizedBox(height: 4),
            Text(
              helpText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Form section divider with optional title
class FormSection extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;

  const FormSection({
    super.key,
    this.title,
    required this.child,
    this.padding,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          child,
          
          if (showDivider) ...[
            const SizedBox(height: 16),
            Divider(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ],
        ],
      ),
    );
  }
}

/// Form validation summary widget
class FormValidationSummary extends StatelessWidget {
  final List<String> errors;
  final VoidCallback? onDismiss;

  const FormValidationSummary({
    super.key,
    required this.errors,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please correct the following errors:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          ...errors.map((error) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}