import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';

/// Base interface for all M5 enhanced services
/// Provides common functionality and error handling patterns
abstract class BaseService {
  /// Initialize the service
  Future<void> initialize();

  /// Dispose the service and clean up resources
  Future<void> dispose();

  /// Check if the service is initialized
  bool get isInitialized;

  /// Check if the service is healthy
  Future<bool> isHealthy();

  /// Get service name for logging and debugging
  String get serviceName;

  /// Get service version
  String get serviceVersion;

  /// Stream of service health status
  Stream<ServiceHealthStatus> get healthStatusStream;

  /// Handle service errors with recovery
  Future<void> handleError(BaseError error);

  /// Get service configuration
  Map<String, dynamic> get configuration;

  /// Update service configuration
  Future<void> updateConfiguration(Map<String, dynamic> config);
}

/// Service health status model
enum ServiceHealthStatus {
  healthy,
  degraded,
  unhealthy,
  unknown,
}

/// Base implementation of BaseService with common functionality
abstract class BaseServiceImpl implements BaseService {
  bool _isInitialized = false;
  final StreamController<ServiceHealthStatus> _healthStatusController = 
      StreamController<ServiceHealthStatus>.broadcast();
  
  Map<String, dynamic> _configuration = {};

  @override
  String get serviceVersion => '1.0.0';

  @override
  bool get isInitialized => _isInitialized;

  @override
  Stream<ServiceHealthStatus> get healthStatusStream => 
      _healthStatusController.stream;

  @override
  Map<String, dynamic> get configuration => Map.unmodifiable(_configuration);

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      await onInitialize();
      _isInitialized = true;
      _healthStatusController.add(ServiceHealthStatus.healthy);
    } catch (error) {
      _healthStatusController.add(ServiceHealthStatus.unhealthy);
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    if (!_isInitialized) {
      return;
    }

    try {
      await onDispose();
    } catch (error) {
      // Log error but don't rethrow during disposal
      debugPrint('Error during service disposal: $error');
    } finally {
      // Always mark as not initialized and close the controller
      _isInitialized = false;
      await _healthStatusController.close();
    }
  }

  @override
  Future<bool> isHealthy() async {
    if (!_isInitialized) {
      return false;
    }

    try {
      return await performHealthCheck();
    } catch (error) {
      _healthStatusController.add(ServiceHealthStatus.unhealthy);
      return false;
    }
  }

  @override
  Future<void> handleError(BaseError error) async {
    // Default error handling - can be overridden by subclasses
    debugPrint('Service $serviceName error: $error');
    
    if (error.severity == ErrorSeverity.critical) {
      _healthStatusController.add(ServiceHealthStatus.unhealthy);
    } else if (error.severity == ErrorSeverity.high) {
      _healthStatusController.add(ServiceHealthStatus.degraded);
    }
  }

  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    _configuration = Map.from(config);
    await onConfigurationUpdated(config);
  }

  /// Template method for service-specific initialization
  Future<void> onInitialize();

  /// Template method for service-specific disposal
  Future<void> onDispose();

  /// Template method for service-specific health checks
  Future<bool> performHealthCheck();

  /// Template method for handling configuration updates
  Future<void> onConfigurationUpdated(Map<String, dynamic> config) async {
    // Default implementation does nothing
  }

  /// Helper method to update health status
  void updateHealthStatus(ServiceHealthStatus status) {
    _healthStatusController.add(status);
  }

  /// Helper method to check if service is ready for operations
  void ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('Service $serviceName is not initialized');
    }
  }
}

/// Service registry interface for dependency injection
abstract class ServiceRegistry {
  T getService<T extends BaseService>();
  void registerService<T extends BaseService>(T service);
  Future<void> initializeAllServices();
  Future<void> disposeAllServices();
  List<BaseService> getAllServices();
}

/// Service dependency model
class ServiceDependency {
  final Type serviceType;
  final List<Type> dependencies;

  const ServiceDependency({
    required this.serviceType,
    this.dependencies = const [],
  });
}

/// Service lifecycle events
enum ServiceLifecycleEvent {
  initializing,
  initialized,
  configuring,
  configured,
  disposing,
  disposed,
  error,
}

/// Service lifecycle listener
abstract class ServiceLifecycleListener {
  void onServiceEvent(BaseService service, ServiceLifecycleEvent event);
}
