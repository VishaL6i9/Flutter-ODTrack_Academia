import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

class SyncNotificationService {
  static final SyncNotificationService _instance = SyncNotificationService._internal();
  factory SyncNotificationService() => _instance;
  SyncNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger('SyncNotificationService');
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    // Request permission is handled dynamically or via manifest
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(initSettings);
      _initialized = true;
      _logger.info('SyncNotificationService initialized successfully');
    } catch (e) {
      _logger.warning('Failed to initialize local notifications: $e');
    }
  }

  Future<void> showSyncSuccessNotification({int itemsSynced = 0}) async {
    if (!_initialized) return;
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sync_success_channel',
      'Sync Completions',
      channelDescription: 'Notifications for successful offline data synchronization',
      importance: Importance.low,
      priority: Priority.low,
    );
    
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    
    String body = itemsSynced > 0 
        ? '$itemsSynced offline items have been safely synchronized.' 
        : 'Offline data has been safely synchronized with the server.';

    await _notificationsPlugin.show(
      0,
      'Sync Complete',
      body,
      platformDetails,
    );
  }

  Future<void> showSyncErrorNotification(String errorMsg) async {
    if (!_initialized) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sync_error_channel',
      'Sync Errors',
      channelDescription: 'Notifications for offline data synchronization failures',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    
    await _notificationsPlugin.show(
      1,
      'Sync Failed',
      errorMsg,
      platformDetails,
    );
  }
}
