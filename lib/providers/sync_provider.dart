import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/core/services/service_registry.dart';
import 'package:odtrack_academia/models/sync_models.dart';
import 'package:odtrack_academia/services/sync/sync_service.dart';

/// Exposes the global SyncService instance from the ServiceRegistry
final syncServiceProvider = Provider<SyncService>((ref) {
  return ServiceRegistry.instance.syncService;
});

/// A continuous stream of the current sync status
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStatusStream;
});
