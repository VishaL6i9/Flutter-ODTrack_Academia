import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/core/app.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/core/storage/enhanced_storage_config.dart';
import 'package:odtrack_academia/core/services/service_registry.dart';
import 'package:odtrack_academia/services/sample_data_service.dart';
import 'package:odtrack_academia/models/staff_member.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Initialize enhanced storage for M5 features (registers adapters)
  await EnhancedStorageConfig.initialize();
  
  // Open all required Hive boxes with their specific types
  await Hive.openBox<User>(AppConstants.userBox); // For AuthState user data
  await Hive.openBox<StaffMember>('staff_members');
  await Hive.openBox<StaffWorkloadData>('staff_workload_data');
  await Hive.openBox<ODRequest>('od_requests');
  await Hive.openBox<Map<String, dynamic>>('staff_analytics_cache'); // Analytics cache
  await Hive.openLazyBox<dynamic>(AppConstants.cacheBox); // Generic cache box

  // Initialize M5 services
  await ServiceRegistry.instance.initializeServices();
  
  // Initialize sample data for analytics dashboard
  final sampleDataService = SampleDataService();
  await sampleDataService.initializeSampleData();
  
  runApp(
    const ProviderScope(
      child: ODTrackApp(),
    ),
  );
}
