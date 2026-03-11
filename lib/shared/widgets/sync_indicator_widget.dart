import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/sync_models.dart';
import 'package:odtrack_academia/providers/sync_provider.dart';

class SyncIndicatorWidget extends ConsumerWidget {
  const SyncIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return syncStatusAsync.when(
      data: (status) {
        // Show tooltip indicating state
        String tooltipStr = '';
        Widget iconWidget;
        bool isSyncing = false;

        switch (status) {
          case SyncStatus.inProgress:
            isSyncing = true;
            tooltipStr = 'Syncing...';
            iconWidget = const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            );
            break;
          case SyncStatus.completed:
            tooltipStr = 'Sync complete';
            iconWidget = const Icon(Icons.cloud_done, color: Colors.greenAccent, size: 20);
            break;
          case SyncStatus.failed:
          case SyncStatus.conflict:
            tooltipStr = 'Sync failed / offline actions pending';
            iconWidget = const Icon(Icons.cloud_off, color: Colors.redAccent, size: 20);
            break;
          case SyncStatus.pending:
            tooltipStr = 'Pending Sync';
            iconWidget = const Icon(Icons.cloud_queue, color: Colors.white70, size: 20);
            break;
        }

        return Tooltip(
          message: tooltipStr,
          child: IconButton(
            icon: iconWidget,
            onPressed: isSyncing
                ? null
                : () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Starting manual sync...'), duration: Duration(seconds: 1)),
                    );
                    final syncService = ref.read(syncServiceProvider);
                    final result = await syncService.forceSync();
                    
                    if (context.mounted && !result.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sync failed: ${result.errors.isNotEmpty ? result.errors.first : 'Unknown error'}'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
