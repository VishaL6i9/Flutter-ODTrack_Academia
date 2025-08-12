
import 'package:odtrack_academia/core/storage/enhanced_storage_manager.dart';
import 'package:odtrack_academia/core/storage/sync_queue_manager.dart';
import 'package:odtrack_academia/services/sync/sync_service.dart';
import 'package:odtrack_academia/services/sync/hive_sync_service.dart';
import 'package:odtrack_academia/services/analytics/analytics_service.dart';
import 'package:odtrack_academia/services/export/export_service.dart';
import 'package:odtrack_academia/services/calendar/calendar_service.dart';
import 'package:odtrack_academia/services/bulk_operations/bulk_operation_service.dart';
import 'package:odtrack_academia/services/performance/performance_service.dart';

/// Service registry for M5 enhanced features
/// Provides centralized access to all services
class ServiceRegistry {
  static ServiceRegistry? _instance;
  static ServiceRegistry get instance => _instance ??= ServiceRegistry._();
  
  ServiceRegistry._();
  
  // Service instances
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
    await _initializeAnalyticsService();
    await _initializeExportService();
    await _initializeCalendarService();
    await _initializeBulkOperationService();
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
    _syncService = null;
    _performanceService = null;
  }
  
  // Private initialization methods
  Future<void> _initializeSyncService() async {
    if (_syncService == null) {
      final storageManager = EnhancedStorageManager();
      final queueManager = SyncQueueManager(storageManager);
      _syncService = HiveSyncService(
        storageManager: storageManager,
        queueManager: queueManager,
      );
      await _syncService!.initialize();
    }
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
