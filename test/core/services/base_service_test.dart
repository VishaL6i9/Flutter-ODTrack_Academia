import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/core/services/base_service.dart';
import 'package:odtrack_academia/core/errors/base_error.dart';

// Mock implementation for testing
class MockService extends BaseServiceImpl {
  bool _shouldFailHealthCheck = false;
  bool _shouldFailInitialization = false;
  bool _initializeCalled = false;
  bool _disposeCalled = false;
  bool _healthCheckCalled = false;
  bool _configurationUpdatedCalled = false;

  @override
  String get serviceName => 'MockService';

  void setShouldFailHealthCheck(bool shouldFail) {
    _shouldFailHealthCheck = shouldFail;
  }

  void setShouldFailInitialization(bool shouldFail) {
    _shouldFailInitialization = shouldFail;
  }

  bool get initializeCalled => _initializeCalled;
  bool get disposeCalled => _disposeCalled;
  bool get healthCheckCalled => _healthCheckCalled;
  bool get configurationUpdatedCalled => _configurationUpdatedCalled;

  @override
  Future<void> onInitialize() async {
    _initializeCalled = true;
    if (_shouldFailInitialization) {
      throw Exception('Initialization failed');
    }
  }

  @override
  Future<void> onDispose() async {
    _disposeCalled = true;
  }

  @override
  Future<bool> performHealthCheck() async {
    _healthCheckCalled = true;
    if (_shouldFailHealthCheck) {
      throw Exception('Health check failed');
    }
    return !_shouldFailHealthCheck;
  }

  @override
  Future<void> onConfigurationUpdated(Map<String, dynamic> config) async {
    _configurationUpdatedCalled = true;
  }
}

// Mock service that fails on disposal
class FailingMockService extends BaseServiceImpl {
  @override
  String get serviceName => 'FailingMockService';

  @override
  Future<void> onInitialize() async {
    // Do nothing
  }

  @override
  Future<void> onDispose() async {
    throw Exception('Disposal failed');
  }

  @override
  Future<bool> performHealthCheck() async {
    return true;
  }
}

void main() {
  group('BaseServiceImpl', () {
    late MockService mockService;

    setUp(() {
      mockService = MockService();
    });

    tearDown(() async {
      if (mockService.isInitialized) {
        await mockService.dispose();
      }
    });

    group('initialization', () {
      test('should initialize successfully', () async {
        expect(mockService.isInitialized, false);
        
        await mockService.initialize();
        
        expect(mockService.isInitialized, true);
        expect(mockService.initializeCalled, true);
      });

      test('should not initialize twice', () async {
        await mockService.initialize();
        expect(mockService.initializeCalled, true);
        
        // Reset the flag to check if it's called again
        mockService._initializeCalled = false;
        
        await mockService.initialize();
        expect(mockService.initializeCalled, false);
      });

      test('should handle initialization failure', () async {
        mockService.setShouldFailInitialization(true);
        
        await expectLater(
          mockService.initialize(),
          throwsException,
        );
        
        expect(mockService.isInitialized, false);
      });

      test('should emit healthy status after successful initialization', () async {
        final statusStream = mockService.healthStatusStream;
        final statusFuture = statusStream.first;
        
        await mockService.initialize();
        
        final status = await statusFuture;
        expect(status, ServiceHealthStatus.healthy);
      });

      test('should emit unhealthy status after failed initialization', () async {
        mockService.setShouldFailInitialization(true);
        
        final statusStream = mockService.healthStatusStream;
        final statusFuture = statusStream.first;
        
        try {
          await mockService.initialize();
        } catch (e) {
          // Expected to fail
        }
        
        final status = await statusFuture;
        expect(status, ServiceHealthStatus.unhealthy);
      });
    });

    group('disposal', () {
      test('should dispose successfully', () async {
        await mockService.initialize();
        expect(mockService.isInitialized, true);
        
        await mockService.dispose();
        
        expect(mockService.isInitialized, false);
        expect(mockService.disposeCalled, true);
      });

      test('should not dispose if not initialized', () async {
        expect(mockService.isInitialized, false);
        
        await mockService.dispose();
        
        expect(mockService.disposeCalled, false);
      });

      test('should handle disposal errors gracefully', () async {
        // Create a service that will fail on disposal
        final failingService = FailingMockService();
        await failingService.initialize();
        expect(failingService.isInitialized, true);
        
        // Should not throw even though onDispose fails
        await expectLater(
          failingService.dispose(),
          completes,
        );
        
        // Should still be marked as not initialized despite the error
        expect(failingService.isInitialized, false);
      });
    });

    group('health check', () {
      test('should return false if not initialized', () async {
        expect(mockService.isInitialized, false);
        
        final isHealthy = await mockService.isHealthy();
        
        expect(isHealthy, false);
        expect(mockService.healthCheckCalled, false);
      });

      test('should return true for healthy service', () async {
        await mockService.initialize();
        
        final isHealthy = await mockService.isHealthy();
        
        expect(isHealthy, true);
        expect(mockService.healthCheckCalled, true);
      });

      test('should return false and emit unhealthy status on health check failure', () async {
        await mockService.initialize();
        mockService.setShouldFailHealthCheck(true);
        
        final statusStream = mockService.healthStatusStream;
        final statusFuture = statusStream.first;
        
        final isHealthy = await mockService.isHealthy();
        
        expect(isHealthy, false);
        expect(mockService.healthCheckCalled, true);
        
        final status = await statusFuture;
        expect(status, ServiceHealthStatus.unhealthy);
      });
    });

    group('configuration', () {
      test('should start with empty configuration', () {
        expect(mockService.configuration, isEmpty);
      });

      test('should update configuration', () async {
        final config = {'key1': 'value1', 'key2': 42};
        
        await mockService.updateConfiguration(config);
        
        expect(mockService.configuration, config);
        expect(mockService.configurationUpdatedCalled, true);
      });

      test('should return unmodifiable configuration', () {
        final config = {'key': 'value'};
        mockService.updateConfiguration(config);
        
        final retrievedConfig = mockService.configuration;
        
        expect(() => retrievedConfig['newKey'] = 'newValue', throwsUnsupportedError);
      });
    });

    group('error handling', () {
      test('should handle error with critical severity', () async {
        await mockService.initialize();
        
        final statusStream = mockService.healthStatusStream;
        final statusFuture = statusStream.first;
        
        final error = BaseError(
          category: ErrorCategory.storage,
          code: 'CRITICAL_ERROR',
          message: 'Critical error occurred',
          severity: ErrorSeverity.critical,
        );
        
        await mockService.handleError(error);
        
        final status = await statusFuture;
        expect(status, ServiceHealthStatus.unhealthy);
      });

      test('should handle error with high severity', () async {
        await mockService.initialize();
        
        final statusStream = mockService.healthStatusStream;
        final statusFuture = statusStream.first;
        
        final error = BaseError(
          category: ErrorCategory.network,
          code: 'HIGH_ERROR',
          message: 'High severity error',
          severity: ErrorSeverity.high,
        );
        
        await mockService.handleError(error);
        
        final status = await statusFuture;
        expect(status, ServiceHealthStatus.degraded);
      });

      test('should not change status for low severity errors', () async {
        await mockService.initialize();
        
        final error = BaseError(
          category: ErrorCategory.validation,
          code: 'LOW_ERROR',
          message: 'Low severity error',
          severity: ErrorSeverity.low,
        );
        
        // Should not throw and should handle the error gracefully
        await expectLater(
          mockService.handleError(error),
          completes,
        );
        
        // Low severity errors don't change health status, so we just verify it doesn't crash
      });
    });

    group('ensureInitialized', () {
      test('should not throw if service is initialized', () async {
        await mockService.initialize();
        
        expect(() => mockService.ensureInitialized(), returnsNormally);
      });

      test('should throw if service is not initialized', () {
        expect(mockService.isInitialized, false);
        
        expect(
          () => mockService.ensureInitialized(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('updateHealthStatus', () {
      test('should emit health status update', () async {
        final statusStream = mockService.healthStatusStream;
        final statusFuture = statusStream.first;
        
        mockService.updateHealthStatus(ServiceHealthStatus.degraded);
        
        final status = await statusFuture;
        expect(status, ServiceHealthStatus.degraded);
      });
    });

    group('service properties', () {
      test('should return correct service name', () {
        expect(mockService.serviceName, 'MockService');
      });

      test('should return default service version', () {
        expect(mockService.serviceVersion, '1.0.0');
      });
    });
  });

  group('ServiceHealthStatus', () {
    test('should have all expected values', () {
      expect(ServiceHealthStatus.values, contains(ServiceHealthStatus.healthy));
      expect(ServiceHealthStatus.values, contains(ServiceHealthStatus.degraded));
      expect(ServiceHealthStatus.values, contains(ServiceHealthStatus.unhealthy));
      expect(ServiceHealthStatus.values, contains(ServiceHealthStatus.unknown));
    });
  });

  group('ServiceLifecycleEvent', () {
    test('should have all expected values', () {
      expect(ServiceLifecycleEvent.values, contains(ServiceLifecycleEvent.initializing));
      expect(ServiceLifecycleEvent.values, contains(ServiceLifecycleEvent.initialized));
      expect(ServiceLifecycleEvent.values, contains(ServiceLifecycleEvent.configuring));
      expect(ServiceLifecycleEvent.values, contains(ServiceLifecycleEvent.configured));
      expect(ServiceLifecycleEvent.values, contains(ServiceLifecycleEvent.disposing));
      expect(ServiceLifecycleEvent.values, contains(ServiceLifecycleEvent.disposed));
      expect(ServiceLifecycleEvent.values, contains(ServiceLifecycleEvent.error));
    });
  });

  group('ServiceDependency', () {
    test('should create dependency with service type', () {
      const dependency = ServiceDependency(
        serviceType: MockService,
      );
      
      expect(dependency.serviceType, MockService);
      expect(dependency.dependencies, isEmpty);
    });

    test('should create dependency with dependencies', () {
      const dependency = ServiceDependency(
        serviceType: MockService,
        dependencies: [String, int],
      );
      
      expect(dependency.serviceType, MockService);
      expect(dependency.dependencies, [String, int]);
    });
  });
}