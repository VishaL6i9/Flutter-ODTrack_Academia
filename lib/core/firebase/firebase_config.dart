import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration and initialization
class FirebaseConfig {
  static const String _projectId = 'odtrack-academia';
  static const String _appId = 'com.odtrack.academia';
  
  /// Initialize Firebase with platform-specific configuration
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: _getFirebaseOptions(),
    );
    
    // Configure Firebase Messaging
    await _configureMessaging();
  }
  
  /// Get platform-specific Firebase options
  static FirebaseOptions _getFirebaseOptions() {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'your-web-api-key',
        appId: _appId,
        messagingSenderId: 'your-messaging-sender-id',
        projectId: _projectId,
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return const FirebaseOptions(
        apiKey: 'your-android-api-key',
        appId: _appId,
        messagingSenderId: 'your-messaging-sender-id',
        projectId: _projectId,
        storageBucket: '$_projectId.appspot.com',
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const FirebaseOptions(
        apiKey: 'your-ios-api-key',
        appId: _appId,
        messagingSenderId: 'your-messaging-sender-id',
        projectId: _projectId,
        storageBucket: '$_projectId.appspot.com',
        iosBundleId: _appId,
      );
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }
  
  /// Configure Firebase Messaging settings
  static Future<void> _configureMessaging() async {
    final messaging = FirebaseMessaging.instance;
    
    // Request permission for notifications
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    // Configure foreground message handling
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Configure background message handling
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Configure notification tap handling
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
  
  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Received foreground message: ${message.messageId}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }
  }
  
  /// Handle notification tap events
  static void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.messageId}');
      print('Data: ${message.data}');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  if (kDebugMode) {
    print('Received background message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
  }
}
