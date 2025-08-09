import 'package:json_annotation/json_annotation.dart';

part 'base_error.g.dart';

/// Enumeration for error categories in M5 enhanced features
enum ErrorCategory {
  @JsonValue('network')
  network,
  @JsonValue('storage')
  storage,
  @JsonValue('permission')
  permission,
  @JsonValue('sync')
  sync,
  @JsonValue('export')
  export,
  @JsonValue('calendar')
  calendar,
  @JsonValue('notification')
  notification,
  @JsonValue('performance')
  performance,
  @JsonValue('validation')
  validation,
  @JsonValue('authentication')
  authentication,
  @JsonValue('unknown')
  unknown,
}

/// Enumeration for error severity levels
enum ErrorSeverity {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

/// Base error class for M5 enhanced features
/// Provides structured error handling with categorization and context
@JsonSerializable()
class BaseError implements Exception {
  final ErrorCategory category;
  final String code;
  final String message;
  final String? userMessage;
  final Map<String, dynamic>? context;
  final DateTime timestamp;
  final bool isRetryable;
  final ErrorSeverity severity;
  final String? stackTrace;

  BaseError({
    required this.category,
    required this.code,
    required this.message,
    this.userMessage,
    this.context,
    DateTime? timestamp,
    this.isRetryable = false,
    this.severity = ErrorSeverity.medium,
    this.stackTrace,
  }) : timestamp = timestamp ?? DateTime.now();

  factory BaseError.fromJson(Map<String, dynamic> json) =>
      _$BaseErrorFromJson(json);

  Map<String, dynamic> toJson() => _$BaseErrorToJson(this);

  /// Create a copy of this error with updated fields
  BaseError copyWith({
    ErrorCategory? category,
    String? code,
    String? message,
    String? userMessage,
    Map<String, dynamic>? context,
    DateTime? timestamp,
    bool? isRetryable,
    ErrorSeverity? severity,
    String? stackTrace,
  }) {
    return BaseError(
      category: category ?? this.category,
      code: code ?? this.code,
      message: message ?? this.message,
      userMessage: userMessage ?? this.userMessage,
      context: context ?? this.context,
      timestamp: timestamp ?? this.timestamp,
      isRetryable: isRetryable ?? this.isRetryable,
      severity: severity ?? this.severity,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  @override
  String toString() {
    return 'BaseError(category: $category, code: $code, message: $message, severity: $severity)';
  }
}

/// Network-related errors
class NetworkError extends BaseError {
  final int? statusCode;
  final String? endpoint;

  NetworkError({
    required String code,
    required String message,
    String? userMessage,
    Map<String, dynamic>? context,
    DateTime? timestamp,
    bool isRetryable = true,
    ErrorSeverity severity = ErrorSeverity.medium,
    String? stackTrace,
    this.statusCode,
    this.endpoint,
  }) : super(
          category: ErrorCategory.network,
          code: code,
          message: message,
          userMessage: userMessage,
          context: context,
          timestamp: timestamp,
          isRetryable: isRetryable,
          severity: severity,
          stackTrace: stackTrace,
        );

  factory NetworkError.connectionTimeout({String? endpoint}) {
    return NetworkError(
      code: 'NETWORK_TIMEOUT',
      message: 'Network connection timeout',
      userMessage: 'Connection timed out. Please check your internet connection and try again.',
      endpoint: endpoint,
      isRetryable: true,
      severity: ErrorSeverity.medium,
    );
  }

  factory NetworkError.noConnection() {
    return NetworkError(
      code: 'NO_CONNECTION',
      message: 'No internet connection available',
      userMessage: 'No internet connection. Please check your network settings.',
      isRetryable: true,
      severity: ErrorSeverity.high,
    );
  }

  factory NetworkError.serverError(int statusCode, {String? endpoint}) {
    return NetworkError(
      code: 'SERVER_ERROR',
      message: 'Server returned error: $statusCode',
      userMessage: 'Server error occurred. Please try again later.',
      statusCode: statusCode,
      endpoint: endpoint,
      isRetryable: statusCode >= 500,
      severity: ErrorSeverity.high,
    );
  }
}

/// Storage-related errors
class StorageError extends BaseError {
  final String? operation;
  final String? key;

  StorageError({
    required String code,
    required String message,
    String? userMessage,
    Map<String, dynamic>? context,
    DateTime? timestamp,
    bool isRetryable = false,
    ErrorSeverity severity = ErrorSeverity.medium,
    String? stackTrace,
    this.operation,
    this.key,
  }) : super(
          category: ErrorCategory.storage,
          code: code,
          message: message,
          userMessage: userMessage,
          context: context,
          timestamp: timestamp,
          isRetryable: isRetryable,
          severity: severity,
          stackTrace: stackTrace,
        );

  factory StorageError.insufficientSpace() {
    return StorageError(
      code: 'INSUFFICIENT_SPACE',
      message: 'Insufficient storage space',
      userMessage: 'Not enough storage space available. Please free up some space and try again.',
      severity: ErrorSeverity.high,
    );
  }

  factory StorageError.corruptedData(String key) {
    return StorageError(
      code: 'CORRUPTED_DATA',
      message: 'Data corruption detected for key: $key',
      userMessage: 'Data corruption detected. The app will attempt to recover automatically.',
      key: key,
      severity: ErrorSeverity.high,
    );
  }
}

/// Permission-related errors
class PermissionError extends BaseError {
  final String permission;

  PermissionError({
    required String code,
    required String message,
    required this.permission,
    String? userMessage,
    Map<String, dynamic>? context,
    DateTime? timestamp,
    bool isRetryable = true,
    ErrorSeverity severity = ErrorSeverity.medium,
    String? stackTrace,
  }) : super(
          category: ErrorCategory.permission,
          code: code,
          message: message,
          userMessage: userMessage,
          context: context,
          timestamp: timestamp,
          isRetryable: isRetryable,
          severity: severity,
          stackTrace: stackTrace,
        );

  factory PermissionError.denied(String permission) {
    return PermissionError(
      code: 'PERMISSION_DENIED',
      message: 'Permission denied: $permission',
      userMessage: 'Permission required to access this feature. Please grant permission in settings.',
      permission: permission,
      isRetryable: true,
      severity: ErrorSeverity.medium,
    );
  }

  factory PermissionError.permanentlyDenied(String permission) {
    return PermissionError(
      code: 'PERMISSION_PERMANENTLY_DENIED',
      message: 'Permission permanently denied: $permission',
      userMessage: 'Permission permanently denied. Please enable it in device settings.',
      permission: permission,
      isRetryable: false,
      severity: ErrorSeverity.high,
    );
  }
}

/// Sync-related errors
class SyncError extends BaseError {
  final String? itemId;
  final String? itemType;

  SyncError({
    required String code,
    required String message,
    String? userMessage,
    Map<String, dynamic>? context,
    DateTime? timestamp,
    bool isRetryable = true,
    ErrorSeverity severity = ErrorSeverity.medium,
    String? stackTrace,
    this.itemId,
    this.itemType,
  }) : super(
          category: ErrorCategory.sync,
          code: code,
          message: message,
          userMessage: userMessage,
          context: context,
          timestamp: timestamp,
          isRetryable: isRetryable,
          severity: severity,
          stackTrace: stackTrace,
        );

  factory SyncError.conflictDetected(String itemId, String itemType) {
    return SyncError(
      code: 'SYNC_CONFLICT',
      message: 'Sync conflict detected for $itemType: $itemId',
      userMessage: 'Data conflict detected. Please resolve the conflict to continue.',
      itemId: itemId,
      itemType: itemType,
      isRetryable: false,
      severity: ErrorSeverity.medium,
    );
  }

  factory SyncError.syncFailed(String reason) {
    return SyncError(
      code: 'SYNC_FAILED',
      message: 'Sync operation failed: $reason',
      userMessage: 'Sync failed. The app will retry automatically.',
      isRetryable: true,
      severity: ErrorSeverity.medium,
    );
  }
}

/// Validation-related errors
class ValidationError extends BaseError {
  final String field;
  final dynamic value;

  ValidationError({
    required String code,
    required String message,
    required this.field,
    this.value,
    String? userMessage,
    Map<String, dynamic>? context,
    DateTime? timestamp,
    bool isRetryable = false,
    ErrorSeverity severity = ErrorSeverity.low,
    String? stackTrace,
  }) : super(
          category: ErrorCategory.validation,
          code: code,
          message: message,
          userMessage: userMessage,
          context: context,
          timestamp: timestamp,
          isRetryable: isRetryable,
          severity: severity,
          stackTrace: stackTrace,
        );

  factory ValidationError.required(String field) {
    return ValidationError(
      code: 'FIELD_REQUIRED',
      message: 'Field is required: $field',
      userMessage: 'This field is required.',
      field: field,
      severity: ErrorSeverity.low,
    );
  }

  factory ValidationError.invalid(String field, dynamic value, String reason) {
    return ValidationError(
      code: 'FIELD_INVALID',
      message: 'Invalid value for field $field: $value. Reason: $reason',
      userMessage: 'Invalid value. $reason',
      field: field,
      value: value,
      severity: ErrorSeverity.low,
    );
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