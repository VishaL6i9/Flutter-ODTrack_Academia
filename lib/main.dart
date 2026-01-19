import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/core/app.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/core/storage/storage_config.dart';
import 'package:odtrack_academia/core/services/service_registry.dart';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:odtrack_academia/services/sample_data_service.dart';
import 'package:odtrack_academia/models/staff_member.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/user.dart';

void main() async {
  // Setup logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // Use debugPrint instead of print for production
    debugPrint('${record.level.name}: ${record.loggerName} - ${record.message}');
    if (record.error != null) {
      debugPrint('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('Stack: ${record.stackTrace}');
    }
  });

  final logger = Logger('main');
  logger.info('App starting...');

  WidgetsFlutterBinding.ensureInitialized();
  logger.info('WidgetsFlutterBinding initialized');

  await Hive.initFlutter();
  logger.info('Hive initialized');

  // Initialize enhanced storage for M5 features (registers adapters)
  await EnhancedStorageConfig.initialize();
  logger.info('EnhancedStorageConfig initialized');

  // Open all required Hive boxes with their specific types
  await Hive.openBox<User>(AppConstants.userBox); // For AuthState user data
  await Hive.openBox<StaffMember>('staff_members');
  await Hive.openBox<StaffWorkloadData>('staff_workload_data');
  await Hive.openBox<ODRequest>('od_requests');
  await Hive.openBox<Map<String, dynamic>>('staff_analytics_cache'); // Analytics cache
  await Hive.openLazyBox<dynamic>(AppConstants.cacheBox); // Generic cache box
  logger.info('All Hive boxes opened');

  // Initialize M5 services
  await ServiceRegistry.instance.initializeServices();
  logger.info('ServiceRegistry initialized');

  // Initialize sample data for analytics dashboard
  final sampleDataService = SampleDataService();
  await sampleDataService.initializeSampleData();
  logger.info('Sample data initialized');

  // Log Android version for debugging
  await _logAndroidVersion();

  logger.info('App initialization complete, running app...');

  runApp(
    const ProviderScope(
      child: ODTrackApp(),
    ),
  );
}

/// Log Android version for debugging
Future<void> _logAndroidVersion() async {
  final logger = Logger('main');
  if (Platform.isAndroid) {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      logger.info('Android SDK Version: $sdkInt');
    } catch (e) {
      logger.warning('Could not determine Android SDK version: $e');
    }
  } else {
    logger.info('Not running on Android platform');
  }
}
