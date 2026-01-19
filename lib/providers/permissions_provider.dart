import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logging/logging.dart';
import 'dart:io';

final _logger = Logger('PermissionsProvider');

class PermissionsState {
  final Map<Permission, PermissionStatus> permissions;
  final bool isLoading;
  final bool allPermissionsGranted;
  final int? androidSdkVersion;

  const PermissionsState({
    this.permissions = const {},
    this.isLoading = true,
    this.allPermissionsGranted = false,
    this.androidSdkVersion,
  });

  PermissionsState copyWith({
    Map<Permission, PermissionStatus>? permissions,
    bool? isLoading,
    bool? allPermissionsGranted,
    int? androidSdkVersion,
  }) {
    return PermissionsState(
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
      allPermissionsGranted: allPermissionsGranted ?? this.allPermissionsGranted,
      androidSdkVersion: androidSdkVersion ?? this.androidSdkVersion,
    );
  }
}

class PermissionsNotifier extends StateNotifier<PermissionsState> {
  PermissionsNotifier() : super(const PermissionsState()) {
    _logger.info('PermissionsNotifier initialized');
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    _logger.info('Starting permission initialization...');
    
    if (!Platform.isAndroid) {
      _logger.info('Not Android platform, skipping permission check');
      state = state.copyWith(isLoading: false, allPermissionsGranted: true);
      return;
    }

    try {
      _logger.info('Platform is Android, proceeding with permission check');
      
      // Get Android SDK version
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;
      _logger.info('Android SDK Version: $sdkVersion');

      // Get required permissions
      final requiredPermissions = _getRequiredPermissions(sdkVersion);
      _logger.info('Required permissions for SDK $sdkVersion: ${requiredPermissions.map((p) => p.toString()).toList()}');

      // Check permission statuses
      final Map<Permission, PermissionStatus> permissionStatuses = {};
      for (final permission in requiredPermissions) {
        final status = await permission.status;
        permissionStatuses[permission] = status;
        _logger.info('Permission ${permission.toString()}: $status (isGranted: ${status.isGranted})');
      }

      // Check if all permissions are granted
      final allGranted = requiredPermissions.isEmpty || permissionStatuses.values.every(
        (status) => status.isGranted,
      );
      
      _logger.info('Required permissions count: ${requiredPermissions.length}');
      _logger.info('All permissions granted: $allGranted');
      _logger.info('Permission statuses: $permissionStatuses');

      state = state.copyWith(
        permissions: permissionStatuses,
        isLoading: false,
        allPermissionsGranted: allGranted,
        androidSdkVersion: sdkVersion,
      );
      
      _logger.info('Permission initialization completed. State: allPermissionsGranted=$allGranted, isLoading=false');
    } catch (e, stackTrace) {
      _logger.severe('Error during permission initialization: $e', e, stackTrace);
      state = state.copyWith(isLoading: false, allPermissionsGranted: true);
    }
  }

  List<Permission> _getRequiredPermissions(int sdkVersion) {
    if (sdkVersion >= 30) {
      // Android 11+ (R and above)
      // Use manageExternalStorage permission for Android 11+
      _logger.info('SDK >= 30: Requiring manageExternalStorage permission');
      return [Permission.manageExternalStorage];
    } else if (sdkVersion >= 29) {
      // Android 10 (Q) - Scoped storage, no special permission needed
      _logger.info('SDK 29: No special permissions required');
      return [];
    } else {
      // Android 9 and below (SDK 24-28)
      _logger.info('SDK < 29: Requiring storage permission');
      return [Permission.storage];
    }
  }

  Future<void> refreshPermissions() async {
    _logger.info('Refreshing permissions...');
    await _initializePermissions();
  }
}

final permissionsProvider =
    StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  return PermissionsNotifier();
});
