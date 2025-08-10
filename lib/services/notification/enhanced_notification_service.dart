import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:odtrack_academia/models/notification_message.dart';
import 'package:odtrack_academia/services/notification/notification_service.dart';
import 'package:odtrack_academia/services/notification/firebase_notification_service.dart';
import 'package:odtrack_academia/services/notification/local_notification_service.dart';
import 'package:odtrack_academia/services/notification/notification_grouping_service.dart';

/// Enhanced notification service that combines Firebase and local notifications
/// with intelligent fallback and grouping capabilities
class EnhancedNotificationService implements NotificationService {
  final FirebaseNotificationService _firebaseService;
  final LocalNotificationService _localService;
  final NotificationGroupingService _groupingService;
  final Connectivity _connectivity;
  
  late StreamController<NotificationMessage> _messageController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<NotificationMessage>? _firebaseSubscription;
  StreamSubscription<NotificationMessage>? _localSubscription;
  
  bool _isInitialized = false;
  bool _isOnline = true;
  bool _useFirebaseWhenAvailable = true;
  
  EnhancedNotificationService({
    FirebaseNotificationService? firebaseService,
    LocalNotificationService? localService,
    NotificationGroupingService? groupingService,
    Connectivity? connectivity,
  }) : _firebaseService = firebaseService ?? FirebaseNotificationService(),
       _localService = localService ?? LocalNotificationService(),
       _groupingService = groupingService ?? NotificationGroupingService(),
       _connectivity = connectivity ?? Connectivity();
  
  @override
  Stream<NotificationMessage> get onMessageReceived => _messageController.stream;
  
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize message stream controller
      _messageController = StreamController<NotificationMessage>.broadcast();
      
      // Initialize grouping service
      await _groupingService.initialize();
      
      // Check initial connectivity
      final connectivityResults = await _connectivity.checkConnectivity();
      _isOnline = !connectivityResults.contains(ConnectivityResult.none);
      
      // Initialize services based on connectivity
      if (_isOnline && _useFirebaseWhenAvailable) {
        await _initializeFirebaseService();
      } else {
        await _initializeLocalService();
      }
      
      // Set up connectivity monitoring
      _setupConnectivityMonitoring();
      
      // Set up periodic cleanup
      Timer.periodic(const Duration(hours: 1), (_) {
        _groupingService.clearExpiredGroups();
      });
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('EnhancedNotificationService initialized successfully');
        print('Online: $_isOnline, Using Firebase: ${_isOnline && _useFirebaseWhenAvailable}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing EnhancedNotificationService: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<String?> getDeviceToken() async {
    if (!_isInitialized) {
      throw StateError('EnhancedNotificationService not initialized');
    }
    
    if (_isOnline && _useFirebaseWhenAvailable) {
      try {
        return await _firebaseService.getDeviceToken();
      } catch (e) {
        if (kDebugMode) {
          print('Error getting Firebase device token, falling back to local: $e');
        }
        return await _localService.getDeviceToken();
      }
    } else {
      return await _localService.getDeviceToken();
    }
  }
  
  @override
  Future<void> subscribeToTopic(String topic) async {
    if (!_isInitialized) {
      throw StateError('EnhancedNotificationService not initialized');
    }
    
    if (_isOnline && _useFirebaseWhenAvailable) {
      try {
        await _firebaseService.subscribeToTopic(topic);
      } catch (e) {
        if (kDebugMode) {
          print('Error subscribing to Firebase topic: $e');
        }
        // Local service doesn't support topics, so we just log this
      }
    }
  }
  
  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_isInitialized) {
      throw StateError('EnhancedNotificationService not initialized');
    }
    
    if (_isOnline && _useFirebaseWhenAvailable) {
      try {
        await _firebaseService.unsubscribeFromTopic(topic);
      } catch (e) {
        if (kDebugMode) {
          print('Error unsubscribing from Firebase topic: $e');
        }
        // Local service doesn't support topics, so we just log this
      }
    }
  }
  
  @override
  Future<void> showLocalNotification(NotificationMessage message) async {
    if (!_isInitialized) {
      throw StateError('EnhancedNotificationService not initialized');
    }
    
    try {
      // Check if notification should be grouped
      final groupResult = await _groupingService.shouldGroupNotification(message);
      
      if (groupResult.isSpamPrevention) {
        // Skip showing individual notification if it's spam prevention
        if (kDebugMode) {
          print('Notification skipped due to spam prevention: ${message.title}');
        }
        return;
      }
      
      // Show notification using appropriate service
      if (_isOnline && _useFirebaseWhenAvailable) {
        try {
          await _firebaseService.showLocalNotification(message);
        } catch (e) {
          if (kDebugMode) {
            print('Error showing Firebase notification, falling back to local: $e');
          }
          await _localService.showLocalNotification(message);
        }
      } else {
        await _localService.showLocalNotification(message);
      }
      
      // Add to message stream
      _messageController.add(message);
      
      if (kDebugMode) {
        print('Enhanced notification shown: ${message.title}');
        if (groupResult.shouldGroup) {
          print('Notification grouped: ${groupResult.groupKey} (size: ${groupResult.groupSize})');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing enhanced notification: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<void> handleNotificationTap(NotificationMessage message) async {
    if (!_isInitialized) {
      throw StateError('EnhancedNotificationService not initialized');
    }
    
    try {
      // Handle tap using appropriate service
      if (_isOnline && _useFirebaseWhenAvailable) {
        try {
          await _firebaseService.handleNotificationTap(message);
        } catch (e) {
          if (kDebugMode) {
            print('Error handling Firebase notification tap, falling back to local: $e');
          }
          await _localService.handleNotificationTap(message);
        }
      } else {
        await _localService.handleNotificationTap(message);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling enhanced notification tap: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      throw StateError('EnhancedNotificationService not initialized');
    }
    
    // Request permissions from both services
    bool firebasePermissions = false;
    bool localPermissions = false;
    
    if (_useFirebaseWhenAvailable) {
      try {
        firebasePermissions = await _firebaseService.requestPermissions();
      } catch (e) {
        if (kDebugMode) {
          print('Error requesting Firebase permissions: $e');
        }
      }
    }
    
    try {
      localPermissions = await _localService.requestPermissions();
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting local permissions: $e');
      }
    }
    
    return firebasePermissions || localPermissions;
  }
  
  @override
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) {
      throw StateError('EnhancedNotificationService not initialized');
    }
    
    if (_isOnline && _useFirebaseWhenAvailable) {
      try {
        return await _firebaseService.areNotificationsEnabled();
      } catch (e) {
        if (kDebugMode) {
          print('Error checking Firebase notification settings, falling back to local: $e');
        }
        return await _localService.areNotificationsEnabled();
      }
    } else {
      return await _localService.areNotificationsEnabled();
    }
  }
  
  @override
  Future<void> clearAllNotifications() async {
    if (!_isInitialized) {
      throw StateError('EnhancedNotificationService not initialized');
    }
    
    try {
      // Clear from both services
      await Future.wait([
        _firebaseService.clearAllNotifications(),
        _localService.clearAllNotifications(),
        _groupingService.clearAllGroups(),
      ]);
      
      if (kDebugMode) {
        print('All enhanced notifications cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing enhanced notifications: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<List<NotificationMessage>> getNotificationHistory() async {
    if (!_isInitialized) {
      throw StateError('EnhancedNotificationService not initialized');
    }
    
    try {
      // Get notifications from both services and merge
      final firebaseNotifications = await _firebaseService.getNotificationHistory();
      final localNotifications = await _localService.getNotificationHistory();
      
      // Merge and deduplicate notifications
      final allNotifications = <String, NotificationMessage>{};
      
      for (final notification in firebaseNotifications) {
        allNotifications[notification.id] = notification;
      }
      
      for (final notification in localNotifications) {
        // Only add if not already present (Firebase takes precedence)
        if (!allNotifications.containsKey(notification.id)) {
          allNotifications[notification.id] = notification;
        }
      }
      
      // Sort by timestamp (newest first)
      final sortedNotifications = allNotifications.values.toList();
      sortedNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return sortedNotifications;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting enhanced notification history: $e');
      }
      return [];
    }
  }
  
  /// Schedule a notification for future delivery (local only)
  Future<void> scheduleNotification(
    NotificationMessage message,
    DateTime scheduledTime,
  ) async {
    if (!_isInitialized) {
      throw StateError('EnhancedNotificationService not initialized');
    }
    
    try {
      await _localService.scheduleNotification(message, scheduledTime);
      
      if (kDebugMode) {
        print('Enhanced notification scheduled for: $scheduledTime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling enhanced notification: $e');
      }
      rethrow;
    }
  }
  
  /// Cancel a scheduled notification
  Future<void> cancelNotification(String notificationId) async {
    if (!_isInitialized) {
      throw StateError('EnhancedNotificationService not initialized');
    }
    
    try {
      await _localService.cancelNotification(notificationId);
      
      if (kDebugMode) {
        print('Enhanced notification cancelled: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling enhanced notification: $e');
      }
      rethrow;
    }
  }
  
  /// Get notification grouping statistics
  NotificationSpamStats getSpamStats() {
    return _groupingService.getSpamStats();
  }
  
  /// Get grouped notifications
  Map<String, List<NotificationMessage>> getGroupedNotifications() {
    return _groupingService.getAllActiveGroups();
  }
  
  /// Get group summary
  NotificationGroupSummary getGroupSummary(String groupKey) {
    return _groupingService.getGroupSummary(groupKey);
  }
  
  /// Enable or disable Firebase notifications
  void setFirebaseEnabled(bool enabled) {
    _useFirebaseWhenAvailable = enabled;
    
    if (kDebugMode) {
      print('Firebase notifications ${enabled ? 'enabled' : 'disabled'}');
    }
  }
  
  /// Check if currently using Firebase
  bool get isUsingFirebase => _isOnline && _useFirebaseWhenAvailable;
  
  /// Check if currently online
  bool get isOnline => _isOnline;
  
  /// Initialize Firebase service
  Future<void> _initializeFirebaseService() async {
    try {
      await _firebaseService.initialize();
      
      // Subscribe to Firebase messages
      _firebaseSubscription?.cancel();
      _firebaseSubscription = _firebaseService.onMessageReceived.listen(
        (message) => _handleIncomingMessage(message, isFromFirebase: true),
        onError: (Object error) {
          if (kDebugMode) {
            print('Firebase message stream error: $error');
          }
        },
      );
      
      if (kDebugMode) {
        print('Firebase notification service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase service: $e');
      }
      // Fall back to local service
      await _initializeLocalService();
    }
  }
  
  /// Initialize local service
  Future<void> _initializeLocalService() async {
    try {
      await _localService.initialize();
      
      // Subscribe to local messages
      _localSubscription?.cancel();
      _localSubscription = _localService.onMessageReceived.listen(
        (message) => _handleIncomingMessage(message, isFromFirebase: false),
        onError: (Object error) {
          if (kDebugMode) {
            print('Local message stream error: $error');
          }
        },
      );
      
      if (kDebugMode) {
        print('Local notification service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing local service: $e');
      }
      rethrow;
    }
  }
  
  /// Set up connectivity monitoring
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final wasOnline = _isOnline;
        _isOnline = !results.contains(ConnectivityResult.none);
        
        if (kDebugMode) {
          print('Connectivity changed: $_isOnline (was: $wasOnline)');
        }
        
        // Switch services if connectivity changed
        if (_isOnline && !wasOnline && _useFirebaseWhenAvailable) {
          // Came online, switch to Firebase
          await _initializeFirebaseService();
        } else if (!_isOnline && wasOnline) {
          // Went offline, ensure local service is ready
          await _initializeLocalService();
        }
      },
    );
  }
  
  /// Handle incoming messages from either service
  Future<void> _handleIncomingMessage(
    NotificationMessage message, {
    required bool isFromFirebase,
  }) async {
    try {
      // Check if notification should be grouped
      final groupResult = await _groupingService.shouldGroupNotification(message);
      
      if (groupResult.isSpamPrevention) {
        if (kDebugMode) {
          print('Message filtered due to spam prevention: ${message.title}');
        }
        return;
      }
      
      // Forward to main stream
      _messageController.add(message);
      
      if (kDebugMode) {
        print('Enhanced message received from ${isFromFirebase ? 'Firebase' : 'Local'}: ${message.title}');
        if (groupResult.shouldGroup) {
          print('Message grouped: ${groupResult.groupKey} (size: ${groupResult.groupSize})');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling incoming enhanced message: $e');
      }
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _firebaseSubscription?.cancel();
    await _localSubscription?.cancel();
    await _messageController.close();
    
    await Future.wait([
      _firebaseService.dispose(),
      _localService.dispose(),
      _groupingService.dispose(),
    ]);
  }
}