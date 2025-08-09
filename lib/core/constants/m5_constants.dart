/// Constants for M5 Enhanced Features
class M5Constants {
  // Firebase Configuration
  static const String firebaseProjectId = 'odtrack-academia';
  static const String firebaseAppId = 'com.odtrack.academia';
  
  // Notification Topics
  static const String odStatusChangeTopic = 'od_status_change';
  static const String newODRequestTopic = 'new_od_request';
  static const String systemUpdatesTopic = 'system_updates';
  static const String bulkOperationsTopic = 'bulk_operations';
  
  // Storage Keys
  static const String notificationSettingsKey = 'notification_settings';
  static const String syncSettingsKey = 'sync_settings';
  static const String analyticsSettingsKey = 'analytics_settings';
  static const String exportSettingsKey = 'export_settings';
  static const String calendarSettingsKey = 'calendar_settings';
  static const String performanceSettingsKey = 'performance_settings';
  
  // Cache Configuration
  static const Duration defaultCacheTTL = Duration(hours: 24);
  static const Duration analyticsCacheTTL = Duration(hours: 6);
  static const Duration syncCacheTTL = Duration(minutes: 30);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxSyncRetries = 3;
  static const Duration syncRetryDelay = Duration(seconds: 30);
  static const int maxOfflineQueueSize = 1000;
  
  // Export Configuration
  static const int maxExportItems = 10000;
  static const Duration exportTimeout = Duration(minutes: 10);
  static const List<String> supportedExportFormats = ['pdf', 'csv'];
  
  // Bulk Operations Configuration
  static const int maxBulkOperationSize = 500;
  static const Duration bulkOperationTimeout = Duration(minutes: 30);
  static const Duration undoTimeWindow = Duration(minutes: 5);
  
  // Performance Configuration
  static const Duration performanceMonitoringInterval = Duration(seconds: 30);
  static const double memoryUsageThreshold = 200.0; // MB
  static const double cpuUsageThreshold = 80.0; // percentage
  static const int frameDropThreshold = 5;
  
  // Analytics Configuration
  static const int analyticsDataRetentionDays = 90;
  static const int maxAnalyticsDataPoints = 1000;
  static const Duration analyticsRefreshInterval = Duration(hours: 1);
  
  // Calendar Configuration
  static const String defaultCalendarEventTitle = 'OD Request - {reason}';
  static const String defaultCalendarEventDescription = 'OD Request for {student} - {reason}';
  static const Duration defaultReminderTime = Duration(minutes: 30);
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration skeletonAnimationDuration = Duration(milliseconds: 1200);
  static const int maxNotificationBadgeCount = 99;
  
  // Error Messages
  static const String networkErrorMessage = 'Network connection error. Please check your internet connection.';
  static const String syncErrorMessage = 'Sync failed. Your changes will be saved and synced when connection is restored.';
  static const String exportErrorMessage = 'Export failed. Please try again.';
  static const String calendarPermissionErrorMessage = 'Calendar permission is required for this feature.';
  static const String notificationPermissionErrorMessage = 'Notification permission is required for this feature.';
  
  // Feature Flags (for gradual rollout)
  static const bool enablePushNotifications = true;
  static const bool enableOfflineSync = true;
  static const bool enableAdvancedAnalytics = true;
  static const bool enableBulkOperations = true;
  static const bool enableCalendarIntegration = true;
  static const bool enablePDFExport = true;
  static const bool enablePerformanceMonitoring = true;
}