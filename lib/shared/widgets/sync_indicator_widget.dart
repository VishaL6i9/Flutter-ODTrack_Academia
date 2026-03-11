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

        switch (status) {
          case SyncStatus.inProgress:
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: iconWidget),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
