import 'dart:async';
import 'package:odtrack_academia/models/performance_models.dart';
import 'package:odtrack_academia/models/analytics_models.dart';

/// Abstract interface for performance monitoring service
/// Handles app performance tracking and optimization
abstract class PerformanceService {
  /// Initialize the performance service
  Future<void> initialize();
  
  /// Start performance monitoring
  Future<void> startMonitoring();
  
  /// Stop performance monitoring
  Future<void> stopMonitoring();
  
  /// Record app launch time
  Future<void> recordAppLaunchTime(Duration launchTime);
  
  /// Record screen transition time
  Future<void> recordScreenTransitionTime(String screenName, Duration transitionTime);
  
  /// Record memory usage
  Future<void> recordMemoryUsage(double memoryUsage);
  
  /// Record frame drops
  Future<void> recordFrameDrops(int frameDropCount);
  
  /// Get current performance metrics
  Future<PerformanceMetrics> getCurrentMetrics();
  
  /// Get performance history
  Future<List<PerformanceMetrics>> getPerformanceHistory(DateRange dateRange);
  
  /// Trigger garbage collection
  Future<void> triggerGarbageCollection();
  
  /// Optimize app performance
  Future<void> optimizePerformance();
  
  /// Check if performance monitoring is enabled
  bool get isMonitoringEnabled;
}
