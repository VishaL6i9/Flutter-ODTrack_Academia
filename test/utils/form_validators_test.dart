import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/utils/form_validators.dart';

void main() {
  group('FormValidators', () {
    group('required', () {
      test('should return error for null value', () {
        final result = FormValidators.required(null);
        expect(result, equals('This field is required'));
      });

      test('should return error for empty string', () {
        final result = FormValidators.required('');
        expect(result, equals('This field is required'));
      });

      test('should return error for whitespace only', () {
        final result = FormValidators.required('   ');
        expect(result, equals('This field is required'));
      });

      test('should return null for valid value', () {
        final result = FormValidators.required('valid value');
        expect(result, isNull);
      });

      test('should use custom field name in error message', () {
        final result = FormValidators.required(null, fieldName: 'Email');
        expect(result, equals('Email is required'));
      });
    });

    group('email', () {
      test('should return null for null or empty value', () {
        expect(FormValidators.email(null), isNull);
        expect(FormValidators.email(''), isNull);
      });

      test('should return error for invalid email formats', () {
        final invalidEmails = [
          'invalid',
          'invalid@',
          '@invalid.com',
          'invalid@.com',
          'invalid.com',
          'invalid@com',
          'invalid@domain.',
        ];

        for (final email in invalidEmails) {
          final result = FormValidators.email(email);
          expect(result, isNotNull, reason: 'Email "$email" should be invalid');
          expect(result, contains('valid email address'));
        }
      });

      test('should return null for valid email formats', () {
        final validEmails = [
          'user@example.com',
          'test.email@domain.co.uk',
          'user+tag@example.org',
          'user123@test-domain.com',
        ];

        for (final email in validEmails) {
          final result = FormValidators.email(email);
          expect(result, isNull, reason: 'Email "$email" should be valid');
        }
      });
    });

    group('password', () {
      test('should return null for null or empty value', () {
        expect(FormValidators.password(null), isNull);
        expect(FormValidators.password(''), isNull);
      });

      test('should return error for short passwords', () {
        final result = FormValidators.password('short');
        expect(result, contains('at least 8 characters'));
      });

      test('should return null for valid length password', () {
        final result = FormValidators.password('validpassword');
        expect(result, isNull);
      });

      test('should enforce strong password requirements when required', () {
        final weakPasswords = [
          'password', // no uppercase, numbers, special chars
          'PASSWORD', // no lowercase, numbers, special chars
          'Password', // no numbers, special chars
          'Password1', // no special chars
        ];

        for (final password in weakPasswords) {
          final result = FormValidators.password(password, requireStrong: true);
          expect(result, isNotNull, reason: 'Password "$password" should be invalid');
        }
      });

      test('should accept strong passwords', () {
        final strongPasswords = [
          'Password123!',
          'MyStr0ng@Pass',
          'C0mplex#Password',
        ];

        for (final password in strongPasswords) {
          final result = FormValidators.password(password, requireStrong: true);
          expect(result, isNull, reason: 'Password "$password" should be valid');
        }
      });
    });

    group('phoneNumber', () {
      test('should return null for null or empty value', () {
        expect(FormValidators.phoneNumber(null), isNull);
        expect(FormValidators.phoneNumber(''), isNull);
      });

      test('should return error for too short phone numbers', () {
        final result = FormValidators.phoneNumber('123456789');
        expect(result, contains('at least 10 digits'));
      });

      test('should return error for too long phone numbers', () {
        final result = FormValidators.phoneNumber('1234567890123456');
        expect(result, contains('cannot exceed 15 digits'));
      });

      test('should accept valid phone numbers with formatting', () {
        final validNumbers = [
          '1234567890',
          '+1 234 567 8900',
          '(123) 456-7890',
          '+91-9876543210',
        ];

        for (final number in validNumbers) {
          final result = FormValidators.phoneNumber(number);
          expect(result, isNull, reason: 'Phone "$number" should be valid');
        }
      });
    });

    group('minLength', () {
      test('should return null for null or empty value', () {
        expect(FormValidators.minLength(null, 5), isNull);
        expect(FormValidators.minLength('', 5), isNull);
      });

      test('should return error for short values', () {
        final result = FormValidators.minLength('abc', 5);
        expect(result, contains('at least 5 characters'));
      });

      test('should return null for valid length', () {
        final result = FormValidators.minLength('abcdef', 5);
        expect(result, isNull);
      });

      test('should use custom field name', () {
        final result = FormValidators.minLength('abc', 5, fieldName: 'Description');
        expect(result, contains('Description must be at least 5 characters'));
      });
    });

    group('maxLength', () {
      test('should return null for null or empty value', () {
        expect(FormValidators.maxLength(null, 5), isNull);
        expect(FormValidators.maxLength('', 5), isNull);
      });

      test('should return error for long values', () {
        final result = FormValidators.maxLength('abcdef', 5);
        expect(result, contains('cannot exceed 5 characters'));
      });

      test('should return null for valid length', () {
        final result = FormValidators.maxLength('abc', 5);
        expect(result, isNull);
      });
    });

    group('numeric', () {
      test('should return null for null or empty value', () {
        expect(FormValidators.numeric(null), isNull);
        expect(FormValidators.numeric(''), isNull);
      });

      test('should return error for non-numeric values', () {
        final invalidValues = ['abc', '12abc', 'abc12', '12.34.56'];
        
        for (final value in invalidValues) {
          final result = FormValidators.numeric(value);
          expect(result, contains('valid number'), reason: 'Value "$value" should be invalid');
        }
      });

      test('should return null for valid numeric values', () {
        final validValues = ['123', '12.34', '-45', '0', '0.0'];
        
        for (final value in validValues) {
          final result = FormValidators.numeric(value);
          expect(result, isNull, reason: 'Value "$value" should be valid');
        }
      });
    });

    group('integer', () {
      test('should return null for null or empty value', () {
        expect(FormValidators.integer(null), isNull);
        expect(FormValidators.integer(''), isNull);
      });

      test('should return error for non-integer values', () {
        final invalidValues = ['abc', '12.34', '12abc'];
        
        for (final value in invalidValues) {
          final result = FormValidators.integer(value);
          expect(result, contains('valid whole number'), reason: 'Value "$value" should be invalid');
        }
      });

      test('should return null for valid integer values', () {
        final validValues = ['123', '-45', '0'];
        
        for (final value in validValues) {
          final result = FormValidators.integer(value);
          expect(result, isNull, reason: 'Value "$value" should be valid');
        }
      });
    });

    group('range', () {
      test('should return null for null or empty value', () {
        expect(FormValidators.range(null, 1, 10), isNull);
        expect(FormValidators.range('', 1, 10), isNull);
      });

      test('should return error for non-numeric values', () {
        final result = FormValidators.range('abc', 1, 10);
        expect(result, contains('valid number'));
      });

      test('should return error for values outside range', () {
        expect(FormValidators.range('0', 1, 10), contains('between 1.0 and 10.0'));
        expect(FormValidators.range('11', 1, 10), contains('between 1.0 and 10.0'));
      });

      test('should return null for values within range', () {
        expect(FormValidators.range('1', 1, 10), isNull);
        expect(FormValidators.range('5', 1, 10), isNull);
        expect(FormValidators.range('10', 1, 10), isNull);
      });
    });

    group('registerNumber', () {
      test('should return null for null or empty value', () {
        expect(FormValidators.registerNumber(null), isNull);
        expect(FormValidators.registerNumber(''), isNull);
      });

      test('should return error for short register numbers', () {
        final result = FormValidators.registerNumber('12345');
        expect(result, contains('at least 6 characters'));
      });

      test('should return error for long register numbers', () {
        final result = FormValidators.registerNumber('1234567890123456');
        expect(result, contains('cannot exceed 15 characters'));
      });

      test('should return error for invalid characters', () {
        final result = FormValidators.registerNumber('ABC123@#');
        expect(result, contains('letters and numbers'));
      });

      test('should return null for valid register numbers', () {
        final validNumbers = ['ABC123', 'CS2021001', '21BCS001'];
        
        for (final number in validNumbers) {
          final result = FormValidators.registerNumber(number);
          expect(result, isNull, reason: 'Register number "$number" should be valid');
        }
      });

      test('should handle spaces and convert to uppercase', () {
        final result = FormValidators.registerNumber('abc 123');
        expect(result, isNull);
      });
    });

    group('futureDate', () {
      test('should return null for null value', () {
        expect(FormValidators.futureDate(null), isNull);
      });

      test('should return error for past dates', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final result = FormValidators.futureDate(pastDate);
        expect(result, contains('cannot be in the past'));
      });

      test('should return null for today', () {
        final today = DateTime.now();
        final result = FormValidators.futureDate(today);
        expect(result, isNull);
      });

      test('should return null for future dates', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final result = FormValidators.futureDate(futureDate);
        expect(result, isNull);
      });
    });

    group('weekday', () {
      test('should return null for null value', () {
        expect(FormValidators.weekday(null), isNull);
      });

      test('should return error for weekends', () {
        // Saturday
        final saturday = DateTime(2024, 1, 6); // Assuming this is a Saturday
        final saturdayResult = FormValidators.weekday(saturday);
        expect(saturdayResult, contains('weekday'));

        // Sunday
        final sunday = DateTime(2024, 1, 7); // Assuming this is a Sunday
        final sundayResult = FormValidators.weekday(sunday);
        expect(sundayResult, contains('weekday'));
      });

      test('should return null for weekdays', () {
        // Monday to Friday
        for (int i = 1; i <= 5; i++) {
          final weekday = DateTime(2024, 1, i); // Assuming Jan 1-5, 2024 are weekdays
          final result = FormValidators.weekday(weekday);
          expect(result, isNull, reason: 'Weekday $i should be valid');
        }
      });
    });

    group('odReason', () {
      test('should return error for null or empty value', () {
        expect(FormValidators.odReason(null), contains('provide a reason'));
        expect(FormValidators.odReason(''), contains('provide a reason'));
        expect(FormValidators.odReason('   '), contains('provide a reason'));
      });

      test('should return error for short reasons', () {
        final result = FormValidators.odReason('short');
        expect(result, contains('more detailed reason'));
      });

      test('should return error for too long reasons', () {
        final longReason = 'a' * 501;
        final result = FormValidators.odReason(longReason);
        expect(result, contains('cannot exceed 500 characters'));
      });

      test('should return error for inappropriate content', () {
        final inappropriateReasons = ['test reason for od', 'dummy request for leave', 'fake od request'];
        
        for (final reason in inappropriateReasons) {
          final result = FormValidators.odReason(reason);
          expect(result, contains('genuine reason'), reason: 'Reason "$reason" should be invalid');
        }
      });

      test('should return null for valid reasons', () {
        final validReasons = [
          'Medical appointment with family doctor',
          'Attending cousin\'s wedding ceremony',
          'Important family function at home',
        ];
        
        for (final reason in validReasons) {
          final result = FormValidators.odReason(reason);
          expect(result, isNull, reason: 'Reason "$reason" should be valid');
        }
      });
    });

    group('getPasswordStrength', () {
      test('should return weak for empty password', () {
        final strength = FormValidators.getPasswordStrength('');
        expect(strength, equals(PasswordStrength.weak));
      });

      test('should return weak for simple passwords', () {
        final weakPasswords = ['password', '12345678', 'abcdefgh'];
        
        for (final password in weakPasswords) {
          final strength = FormValidators.getPasswordStrength(password);
          expect(strength, equals(PasswordStrength.weak), reason: 'Password "$password" should be weak');
        }
      });

      test('should return medium for moderately complex passwords', () {
        final mediumPasswords = ['Password1', 'abc123DEF', 'MyPass123'];
        
        for (final password in mediumPasswords) {
          final strength = FormValidators.getPasswordStrength(password);
          expect(strength, equals(PasswordStrength.medium), reason: 'Password "$password" should be medium');
        }
      });

      test('should return strong for complex passwords', () {
        final strongPasswords = ['Password123!', 'MyStr0ng@Pass', 'C0mplex#Password'];
        
        for (final password in strongPasswords) {
          final strength = FormValidators.getPasswordStrength(password);
          expect(strength, equals(PasswordStrength.strong), reason: 'Password "$password" should be strong');
        }
      });
    });

    group('combine', () {
      test('should return first error from multiple validators', () {
        final validators = [
          FormValidators.required,
          (String? value) => FormValidators.minLength(value, 5),
          FormValidators.email,
        ];
        
        final combinedValidator = FormValidators.combine(validators);
        
        // Test with empty value (should fail required validation)
        expect(combinedValidator(''), contains('required'));
        
        // Test with short value (should fail minLength validation)
        expect(combinedValidator('abc'), contains('at least 5 characters'));
        
        // Test with invalid email (should fail email validation)
        expect(combinedValidator('invalid'), contains('valid email'));
        
        // Test with valid value
        expect(combinedValidator('user@example.com'), isNull);
      });
    });
  });

  group('Validator Classes', () {
    group('RequiredValidator', () {
      test('should validate required fields', () {
        final validator = RequiredValidator(fieldName: 'Email');
        
        expect(validator.validate(null), contains('Email is required'));
        expect(validator.validate(''), contains('Email is required'));
        expect(validator.validate('value'), isNull);
      });
    });

    group('EmailValidator', () {
      test('should validate email format', () {
        final validator = EmailValidator();
        
        expect(validator.validate('invalid'), isNotNull);
        expect(validator.validate('user@example.com'), isNull);
      });
    });

    group('PasswordValidator', () {
      test('should validate password strength', () {
        final weakValidator = PasswordValidator();
        final strongValidator = PasswordValidator(requireStrong: true);
        
        expect(weakValidator.validate('short'), isNotNull);
        expect(weakValidator.validate('validpassword'), isNull);
        
        expect(strongValidator.validate('password'), isNotNull);
        expect(strongValidator.validate('Password123!'), isNull);
      });
    });

    group('CompositeValidator', () {
      test('should combine multiple validators', () {
        final validator = CompositeValidator([
          RequiredValidator(),
          MinLengthValidator(5),
          EmailValidator(),
        ]);
        
        expect(validator.validate(''), isNotNull);
        expect(validator.validate('abc'), isNotNull);
        expect(validator.validate('invalid'), isNotNull);
        expect(validator.validate('user@example.com'), isNull);
      });
    });
  });
}