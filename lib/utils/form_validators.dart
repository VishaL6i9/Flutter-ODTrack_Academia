
/// Enumeration for password strength levels
enum PasswordStrength { weak, medium, strong }

/// Abstract base class for form validators
abstract class FormValidator {
  String? validate(String? value);
}

/// Collection of form validation utilities with contextual error messages
class FormValidators {
  FormValidators._();

  /// Validates required fields
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address (e.g., user@example.com)';
    }
    return null;
  }

  /// Validates password strength
  static String? password(String? value, {bool requireStrong = false}) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (requireStrong) {
      final hasUppercase = value.contains(RegExp(r'[A-Z]'));
      final hasLowercase = value.contains(RegExp(r'[a-z]'));
      final hasNumbers = value.contains(RegExp(r'[0-9]'));
      final hasSpecialCharacters = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      
      if (!hasUppercase) {
        return 'Password must contain at least one uppercase letter';
      }
      if (!hasLowercase) {
        return 'Password must contain at least one lowercase letter';
      }
      if (!hasNumbers) {
        return 'Password must contain at least one number';
      }
      if (!hasSpecialCharacters) {
        return 'Password must contain at least one special character';
      }
    }
    
    return null;
  }

  /// Validates phone number format
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (digitsOnly.length > 15) {
      return 'Phone number cannot exceed 15 digits';
    }
    
    return null;
  }

  /// Validates minimum length
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters long';
    }
    return null;
  }

  /// Validates maximum length
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length > maxLength) {
      return '${fieldName ?? 'This field'} cannot exceed $maxLength characters';
    }
    return null;
  }

  /// Validates numeric input
  static String? numeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;
    
    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'This field'} must be a valid number';
    }
    return null;
  }

  /// Validates integer input
  static String? integer(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;
    
    if (int.tryParse(value) == null) {
      return '${fieldName ?? 'This field'} must be a valid whole number';
    }
    return null;
  }

  /// Validates range for numeric values
  static String? range(String? value, double min, double max, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;
    
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return '${fieldName ?? 'This field'} must be a valid number';
    }
    
    if (numValue < min || numValue > max) {
      return '${fieldName ?? 'This field'} must be between $min and $max';
    }
    return null;
  }

  /// Validates register number format (academic context)
  static String? registerNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // Remove spaces and convert to uppercase
    final cleanValue = value.replaceAll(' ', '').toUpperCase();
    
    if (cleanValue.length < 6) {
      return 'Register number must be at least 6 characters long';
    }
    
    if (cleanValue.length > 15) {
      return 'Register number cannot exceed 15 characters';
    }
    
    // Check for valid alphanumeric format
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleanValue)) {
      return 'Register number can only contain letters and numbers';
    }
    
    return null;
  }

  /// Validates date is not in the past (for future events)
  static String? futureDate(DateTime? value, {String? fieldName}) {
    if (value == null) return null;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(value.year, value.month, value.day);
    
    if (selectedDate.isBefore(today)) {
      return '${fieldName ?? 'Date'} cannot be in the past';
    }
    return null;
  }

  /// Validates date is not too far in the future
  static String? dateRange(DateTime? value, {int maxDaysInFuture = 365, String? fieldName}) {
    if (value == null) return null;
    
    final now = DateTime.now();
    final maxDate = now.add(Duration(days: maxDaysInFuture));
    
    if (value.isAfter(maxDate)) {
      return '${fieldName ?? 'Date'} cannot be more than $maxDaysInFuture days in the future';
    }
    return null;
  }

  /// Validates weekday (Monday to Friday)
  static String? weekday(DateTime? value, {String? fieldName}) {
    if (value == null) return null;
    
    if (value.weekday > 5) { // Saturday = 6, Sunday = 7
      return '${fieldName ?? 'Date'} must be a weekday (Monday to Friday)';
    }
    return null;
  }

  /// Validates OD reason (academic context)
  static String? odReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please provide a reason for your OD request';
    }
    
    if (value.trim().length < 10) {
      return 'Please provide a more detailed reason (at least 10 characters)';
    }
    
    if (value.trim().length > 500) {
      return 'Reason cannot exceed 500 characters';
    }
    
    // Check for inappropriate content (basic check)
    final inappropriateWords = ['test', 'dummy', 'fake'];
    final lowerValue = value.toLowerCase();
    
    for (final word in inappropriateWords) {
      if (lowerValue.contains(word)) {
        return 'Please provide a genuine reason for your OD request';
      }
    }
    
    return null;
  }

  /// Get password strength
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;
    
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character variety checks
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// Combine multiple validators
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}

/// Specific validator classes for reusable validation logic
class RequiredValidator extends FormValidator {
  final String? fieldName;
  
  RequiredValidator({this.fieldName});
  
  @override
  String? validate(String? value) {
    return FormValidators.required(value, fieldName: fieldName);
  }
}

class EmailValidator extends FormValidator {
  @override
  String? validate(String? value) {
    return FormValidators.email(value);
  }
}

class PasswordValidator extends FormValidator {
  final bool requireStrong;
  
  PasswordValidator({this.requireStrong = false});
  
  @override
  String? validate(String? value) {
    return FormValidators.password(value, requireStrong: requireStrong);
  }
}

class MinLengthValidator extends FormValidator {
  final int minLength;
  final String? fieldName;
  
  MinLengthValidator(this.minLength, {this.fieldName});
  
  @override
  String? validate(String? value) {
    return FormValidators.minLength(value, minLength, fieldName: fieldName);
  }
}

class MaxLengthValidator extends FormValidator {
  final int maxLength;
  final String? fieldName;
  
  MaxLengthValidator(this.maxLength, {this.fieldName});
  
  @override
  String? validate(String? value) {
    return FormValidators.maxLength(value, maxLength, fieldName: fieldName);
  }
}

class NumericValidator extends FormValidator {
  final String? fieldName;
  
  NumericValidator({this.fieldName});
  
  @override
  String? validate(String? value) {
    return FormValidators.numeric(value, fieldName: fieldName);
  }
}

class RangeValidator extends FormValidator {
  final double min;
  final double max;
  final String? fieldName;
  
  RangeValidator(this.min, this.max, {this.fieldName});
  
  @override
  String? validate(String? value) {
    return FormValidators.range(value, min, max, fieldName: fieldName);
  }
}

class RegisterNumberValidator extends FormValidator {
  @override
  String? validate(String? value) {
    return FormValidators.registerNumber(value);
  }
}

class ODReasonValidator extends FormValidator {
  @override
  String? validate(String? value) {
    return FormValidators.odReason(value);
  }
}

/// Composite validator for complex validation scenarios
class CompositeValidator extends FormValidator {
  final List<FormValidator> validators;
  
  CompositeValidator(this.validators);
  
  @override
  String? validate(String? value) {
    for (final validator in validators) {
      final result = validator.validate(value);
      if (result != null) return result;
    }
    return null;
  }
}