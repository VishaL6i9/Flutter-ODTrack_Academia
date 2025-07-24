import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/core/app.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize app boxes
  await Hive.openBox<dynamic>(AppConstants.userBox);
  await Hive.openBox<dynamic>(AppConstants.cacheBox);
  
  runApp(
    const ProviderScope(
      child: ODTrackApp(),
    ),
  );
}