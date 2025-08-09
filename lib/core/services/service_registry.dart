import '../../services/notification/notification_service.dart';
import '../../services/sync/sync_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/export/export_service.dart';
import '../../services/calendar/calendar_service.dart';
import '../../services/bulk_operations/bulk_operation_service.dart';
import '../../services/performance/performance_service.dart';

/// Service registry for M5 enhanced features
/// Provides centralized access to all services
class ServiceRegistry {
  static ServiceRegistry? _instance;
  static ServiceRegistry get instance => _instance ??= ServiceRegistry._();
  
  ServiceRegistry._();
  
  // Service instances
  NotificationService? _notificationService;
  SyncService? _syncService;
  AnalyticsService? _analyticsService;
  ExportService? _exportService;
  CalendarService? _calendarService;
  BulkOperationService? _bulkOperationService;
  PerformanceService? _performanceService;
  
  /// Initialize all M5 services
  Future<void> initializeServices() async {
    // Services will be initialized in dependency order
    await _initializePerformanceService();
    await _initializeSyncService();
    await _initializeNotificationService();
    await _initializeAnalyticsService();
    await _initializeExportService();
    await _initializeCalendarService();
    await _initializeBulkOperationService();
  }
  
  /// Get notification service instance
  NotificationService get notificationService {
    if (_notificationService == null) {
      throw StateError('NotificationService not initialized. Call initializeServices() first.');
    }
    return _notificationService!;
  }
  
  /// Get sync service instance
  SyncService get syncService {
    if (_syncService == null) {
      throw StateError('SyncService not initialized. Call initializeServices() first.');
    }
    return _syncService!;
  }
  
  /// Get analytics service instance
  AnalyticsService get analyticsService {
    if (_analyticsService == null) {
      throw StateError('AnalyticsService not initialized. Call initializeServices() first.');
    }
    return _analyticsService!;
  }
  
  /// Get export service instance
  ExportService get exportService {
    if (_exportService == null) {
      throw StateError('ExportService not initialized. Call initializeServices() first.');
    }
    return _exportService!;
  }
  
  /// Get calendar service instance
  CalendarService get calendarService {
    if (_calendarService == null) {
      throw StateError('CalendarService not initialized. Call initializeServices() first.');
    }
    return _calendarService!;
  }
  
  /// Get bulk operation service instance
  BulkOperationService get bulkOperationService {
    if (_bulkOperationService == null) {
      throw StateError('BulkOperationService not initialized. Call initializeServices() first.');
    }
    return _bulkOperationService!;
  }
  
  /// Get performance service instance
  PerformanceService get performanceService {
    if (_performanceService == null) {
      throw StateError('PerformanceService not initialized. Call initializeServices() first.');
    }
    return _performanceService!;
  }
  
  /// Register custom service implementations (for testing or custom implementations)
  void registerNotificationService(NotificationService service) {
    _notificationService = service;
  }
  
  void registerSyncService(SyncService service) {
    _syncService = service;
  }
  
  void registerAnalyticsService(AnalyticsService service) {
    _analyticsService = service;
  }
  
  void registerExportService(ExportService service) {
    _exportService = service;
  }
  
  void registerCalendarService(CalendarService service) {
    _calendarService = service;
  }
  
  void registerBulkOperationService(BulkOperationService service) {
    _bulkOperationService = service;
  }
  
  void registerPerformanceService(PerformanceService service) {
    _performanceService = service;
  }
  
  /// Dispose all services
  Future<void> disposeServices() async {
    // Dispose services in reverse order
    _bulkOperationService = null;
    _calendarService = null;
    _exportService = null;
    _analyticsService = null;
    _notificationService = null;
    _syncService = null;
    _performanceService = null;
  }
  
  // Private initialization methods
  Future<void> _initializeNotificationService() async {
    // Implementation will be added in later tasks
    // _notificationService = FirebaseNotificationService();
    // await _notificationService!.initialize();
  }
  
  Future<void> _initializeSyncService() async {
    // Implementation will be added in later tasks
    // _syncService = HiveSyncService();
    // await _syncService!.initialize();
  }
  
  Future<void> _initializeAnalyticsService() async {
    // Implementation will be added in later tasks
    // _analyticsService = LocalAnalyticsService();
    // await _analyticsService!.initialize();
  }
  
  Future<void> _initializeExportService() async {
    // Implementation will be added in later tasks
    // _exportService = PDFExportService();
    // await _exportService!.initialize();
  }
  
  Future<void> _initializeCalendarService() async {
    // Implementation will be added in later tasks
    // _calendarService = DeviceCalendarService();
    // await _calendarService!.initialize();
  }
  
  Future<void> _initializeBulkOperationService() async {
    // Implementation will be added in later tasks
    // _bulkOperationService = DefaultBulkOperationService();
    // await _bulkOperationService!.initialize();
  }
  
  Future<void> _initializePerformanceService() async {
    // Implementation will be added in later tasks
    // _performanceService = DefaultPerformanceService();
    // await _performanceService!.initialize();
  }
}