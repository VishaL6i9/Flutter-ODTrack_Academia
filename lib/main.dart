import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/core/app.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/core/firebase/firebase_config.dart';
import 'package:odtrack_academia/core/storage/enhanced_storage_config.dart';
import 'package:odtrack_academia/core/services/service_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for M5 features
  await FirebaseConfig.initialize();
  
  // Initialize enhanced storage for M5 features
  await EnhancedStorageConfig.initialize();
  
  // Initialize existing app boxes
  await Hive.openBox<dynamic>(AppConstants.userBox);
  await Hive.openBox<dynamic>(AppConstants.cacheBox);
  
  // Initialize M5 services
  await ServiceRegistry.instance.initializeServices();
  
  runApp(
    const ProviderScope(
      child: ODTrackApp(),
    ),
  );
}