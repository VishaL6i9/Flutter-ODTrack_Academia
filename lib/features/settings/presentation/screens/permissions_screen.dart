import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/providers/permissions_provider.dart';
import 'dart:io';

final _logger = Logger('PermissionsScreen');

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  Map<Permission, PermissionStatus> permissions = {};
  int? androidSdkVersion;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _logger.info('PermissionsScreen initState called');
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    _logger.info('Initializing permissions screen...');
    // Get Android SDK version
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (mounted) {
        setState(() {
          androidSdkVersion = androidInfo.version.sdkInt;
        });
      }
      _logger.info('Android SDK Version: $androidSdkVersion');
    }

    await _checkPermissions();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    _logger.info('Permissions screen initialization complete');
  }

  Future<void> _checkPermissions() async {
    _logger.info('Checking permissions...');
    if (!Platform.isAndroid) {
      _logger.info('Not Android, skipping permission check');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    final permissionList = _getRequiredPermissions();
    _logger.info('Required permissions: ${permissionList.map((p) => p.toString()).toList()}');
    final Map<Permission, PermissionStatus> newPermissions = {};

    for (final permission in permissionList) {
      final status = await permission.status;
      newPermissions[permission] = status;
      _logger.info('Permission ${permission.toString()}: $status');
    }

    if (mounted) {
      setState(() {
        permissions = newPermissions;
      });
    }
    _logger.info('Permission check complete: $newPermissions');
  }

  List<Permission> _getRequiredPermissions() {
    if (androidSdkVersion == null) {
      return [];
    }

    if (androidSdkVersion! >= 30) {
      // Android 11+ (R and above)
      return [Permission.manageExternalStorage];
    } else if (androidSdkVersion! >= 29) {
      // Android 10 (Q) - Scoped storage, no special permission needed
      return [];
    } else {
      // Android 9 and below (SDK 24-28)
      return [Permission.storage];
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    _logger.info('Requesting permission: ${permission.toString()}');
    final status = await permission.request();
    _logger.info('Permission ${permission.toString()} result: $status');
    if (mounted) {
      setState(() {
        permissions[permission] = status;
      });
      
      // Refresh the provider so router knows permissions changed
      if (status.isGranted) {
        _logger.info('Permission granted, refreshing provider...');
        await ref.read(permissionsProvider.notifier).refreshPermissions();
      }
    }
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.storage:
        return 'Storage Access (Write External Storage)';
      case Permission.manageExternalStorage:
        return 'Manage External Storage';
      default:
        return permission.toString().split('.').last;
    }
  }

  String _getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.storage:
        return 'Required to save exports to public Downloads folder';
      case Permission.manageExternalStorage:
        return 'Required to save exports and access files on your device';
      default:
        return 'Required for app functionality';
    }
  }

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      case PermissionStatus.limited:
        return Colors.orange;
      case PermissionStatus.restricted:
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.restricted:
        return 'Restricted';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Permissions'),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : !Platform.isAndroid
              ? _buildNonAndroidView(context)
              : _buildAndroidView(context),
    );
  }

  Widget _buildNonAndroidView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Permissions Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This feature is only available on Android devices',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.go(AppConstants.dashboardRoute);
              },
              child: const Text('Continue to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Storage Permissions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grant permissions to enable export functionality and save files to your device.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Android Version: $androidSdkVersion',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Permissions list
          if (permissions.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All Permissions Granted',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your device is running Android $androidSdkVersion\nNo additional permissions required.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: permissions.length,
                itemBuilder: (context, index) {
                  final permissionEntry = permissions.entries.elementAt(index);
                  final permission = permissionEntry.key;
                  final status = permissionEntry.value;
                  final isGranted = status == PermissionStatus.granted;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getPermissionName(permission),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getPermissionDescription(permission),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isGranted 
                                      ? colorScheme.primary.withValues(alpha: 0.1)
                                      : colorScheme.error.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isGranted ? Icons.check_circle : Icons.cancel,
                                  color: isGranted ? colorScheme.primary : colorScheme.error,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (status != PermissionStatus.granted)
                                ElevatedButton.icon(
                                  onPressed: () => _requestPermission(permission),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Allow'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                )
                              else
                                TextButton(
                                  onPressed: () => _checkPermissions(),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('Refresh'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _checkPermissions,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Settings'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Proceed button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: permissions.isEmpty || permissions.values.every((status) => status.isGranted)
                  ? () async {
                      _logger.info('Continue to Login pressed, refreshing provider...');
                      await ref.read(permissionsProvider.notifier).refreshPermissions();
                      if (mounted) {
                        if (context.mounted) {
                          context.go(AppConstants.loginRoute);
                        }
                      }
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Continue to Login'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
