import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';

/// Service for handling error recovery and retry mechanisms
/// Provides intelligent retry logic with exponential backoff
class ErrorRecoveryService {
  static ErrorRecoveryService? _instance;
  static ErrorRecoveryService get instance => _instance ??= ErrorRecoveryService._();
  
  ErrorRecoveryService._();

  /// Handle network errors with appropriate recovery strategies
  Future<void> handleNetworkError(NetworkError error) async {
    switch (error.code) {
      case 'NETWORK_TIMEOUT':
      case 'NO_CONNECTION':
        // Log error and wait for connectivity
        await _logError(error);
        break;
      case 'SERVER_ERROR':
        // Log error and potentially notify user
        await _logError(error);
        if (error.statusCode != null && error.statusCode! >= 500) {
          // Server error - retry might help
          await Future<void>.delayed(const Duration(seconds: 5));
        }
        break;
      default:
        await _logError(error);
    }
  }

  /// Handle storage errors with recovery mechanisms
  Future<void> handleStorageError(StorageError error) async {
    switch (error.code) {
      case 'INSUFFICIENT_SPACE':
        // Attempt to clean up cache
        await _attemptCacheCleanup();
        break;
      case 'CORRUPTED_DATA':
        // Attempt to recover or reset corrupted data
        await _attemptDataRecovery(error.key);
        break;
      default:
        await _logError(error);
    }
  }

  /// Handle permission errors
  Future<void> handlePermissionError(PermissionError error) async {
    await _logError(error);
    // Permission errors typically require user action
    // The UI should handle showing permission request dialogs
  }

  /// Handle sync errors with recovery strategies
  Future<void> handleSyncError(SyncError error) async {
    switch (error.code) {
      case 'SYNC_CONFLICT':
        // Conflicts need manual resolution or automatic resolution based on timestamp
        await _logError(error);
        break;
      case 'SYNC_FAILED':
        // Retry sync operation
        await _logError(error);
        break;
      default:
        await _logError(error);
    }
  }

  /// Retry operation with exponential backoff
  /// Returns the result of the operation or throws the last error
  Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    Duration maxDelay = const Duration(minutes: 1),
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        if (attempt >= maxRetries) {
          // Last attempt failed, rethrow the error
          rethrow;
        }
        
        // Check if error is retryable
        if (error is BaseError && !error.isRetryable) {
          rethrow;
        }
        
        // Wait before retry with exponential backoff
        await Future<void>.delayed(currentDelay);
        
        // Calculate next delay with jitter to avoid thundering herd
        final jitter = Random().nextDouble() * 0.1; // 10% jitter
        currentDelay = Duration(
          milliseconds: min(
            (currentDelay.inMilliseconds * backoffMultiplier * (1 + jitter)).round(),
            maxDelay.inMilliseconds,
          ),
        );
      }
    }
    
    throw StateError('Retry loop completed without success or failure');
  }

  /// Retry operation with linear backoff
  Future<T> retryWithLinearBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        if (error is BaseError && !error.isRetryable) {
          rethrow;
        }
        
        await Future<void>.delayed(delay);
      }
    }
    
    throw StateError('Retry loop completed without success or failure');
  }

  /// Check if an error is recoverable
  bool isRecoverable(BaseError error) {
    return error.isRetryable && error.severity != ErrorSeverity.critical;
  }

  /// Get suggested recovery action for an error
  String getRecoveryAction(BaseError error) {
    switch (error.category) {
      case ErrorCategory.network:
        return 'Check your internet connection and try again';
      case ErrorCategory.storage:
        return 'Free up storage space or restart the app';
      case ErrorCategory.permission:
        return 'Grant the required permission in settings';
      case ErrorCategory.sync:
        return 'The app will retry automatically';
      case ErrorCategory.export:
        return 'Try exporting again or check available storage';
      case ErrorCategory.calendar:
        return 'Check calendar permissions and try again';
      case ErrorCategory.notification:
        return 'Check notification permissions in settings';
      case ErrorCategory.performance:
        return 'Restart the app if performance issues persist';
      case ErrorCategory.validation:
        return 'Please correct the input and try again';
      case ErrorCategory.authentication:
        return 'Please log in again';
      case ErrorCategory.unknown:
        return 'Please try again or restart the app';
    }
  }

  /// Private helper methods
  Future<void> _logError(BaseError error) async {
    // In a real implementation, this would log to a logging service
    debugPrint('Error logged: ${error.toString()}');
    // TODO: Implement actual logging to file or remote service
  }

  Future<void> _attemptCacheCleanup() async {
    // In a real implementation, this would clean up cache
    debugPrint('Attempting cache cleanup...');
    // TODO: Implement actual cache cleanup logic
  }

  Future<void> _attemptDataRecovery(String? key) async {
    // In a real implementation, this would attempt data recovery
    debugPrint('Attempting data recovery for key: $key');
    // TODO: Implement actual data recovery logic
  }
}

/// Extension methods for easier error handling
extension BaseErrorExtension on BaseError {
  /// Check if this error should trigger a user notification
  bool get shouldNotifyUser => severity == ErrorSeverity.high || severity == ErrorSeverity.critical;
  
  /// Get user-friendly error message
  String get displayMessage => userMessage ?? message;
  
  /// Check if error occurred recently (within last 5 minutes)
  bool get isRecent => DateTime.now().difference(timestamp).inMinutes < 5;
}
