import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odtrack_academia/providers/calendar_provider.dart';
import 'package:odtrack_academia/providers/od_request_provider.dart';
import 'package:odtrack_academia/services/calendar/calendar_sync_service.dart';

/// Screen for managing calendar integration settings
class CalendarSettingsScreen extends ConsumerStatefulWidget {
  const CalendarSettingsScreen({super.key});

  @override
  ConsumerState<CalendarSettingsScreen> createState() => _CalendarSettingsScreenState();
}

class _CalendarSettingsScreenState extends ConsumerState<CalendarSettingsScreen> {
  bool _isLoading = false;
  bool _isBatchSyncing = false;
  String? _batchSyncStatus;
  int _syncProgress = 0;
  int _totalSyncItems = 0;

  @override
  void initState() {
    super.initState();
    // Delay initialization to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCalendarSettings();
    });
  }

  Future<void> _initializeCalendarSettings() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      await ref.read(calendarProvider.notifier).initialize();
      await ref.read(calendarProvider.notifier).loadAvailableCalendars();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing calendar settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : calendarState.when(
              data: (state) => _buildSettingsContent(state),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorContent(error),
            ),
    );
  }

  Widget _buildSettingsContent(CalendarState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPermissionSection(state),
          const SizedBox(height: 24),
          if (state.hasPermission) ...[
            _buildCalendarSelectionSection(state),
            const SizedBox(height: 24),
            _buildSyncSettingsSection(state),
            const SizedBox(height: 24),
            _buildReminderSettingsSection(state),
            const SizedBox(height: 24),
            _buildActionButtons(state),
            const SizedBox(height: 24),
            _buildBatchSyncSection(state),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionSection(CalendarState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.hasPermission ? Icons.check_circle : Icons.warning,
                  color: state.hasPermission ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Calendar Permission',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              state.hasPermission
                  ? 'Calendar access is granted. You can sync OD requests with your device calendar.'
                  : 'Calendar permission is required to sync OD requests with your device calendar.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!state.hasPermission) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _requestPermission(),
                icon: const Icon(Icons.security),
                label: const Text('Grant Permission'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSelectionSection(CalendarState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Default Calendar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.availableCalendars.isEmpty)
              const Text('No calendars available')
            else
              DropdownButtonFormField<String>(
                value: state.syncSettings?.defaultCalendarId.isNotEmpty == true
                    ? state.syncSettings!.defaultCalendarId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Select Calendar',
                  border: OutlineInputBorder(),
                ),
                items: state.availableCalendars.map((calendar) {
                  return DropdownMenuItem<String>(
                    value: calendar.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(calendar.name),
                        if (calendar.accountName != null)
                          Text(
                            calendar.accountName!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (calendarId) {
                  if (calendarId != null) {
                    _updateDefaultCalendar(calendarId);
                  }
                },
              ),
            const SizedBox(height: 8),
            Text(
              'Select the calendar where OD events will be created',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSettingsSection(CalendarState state) {
    final settings = state.syncSettings;
    if (settings == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Sync Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto Sync'),
              subtitle: const Text('Automatically sync OD requests to calendar'),
              value: settings.autoSyncEnabled,
              onChanged: (value) => _updateAutoSync(value),
            ),
            SwitchListTile(
              title: const Text('Sync Approved Only'),
              subtitle: const Text('Only sync approved OD requests'),
              value: settings.syncApprovedOnly,
              onChanged: (value) => _updateSyncApprovedOnly(value),
            ),
            SwitchListTile(
              title: const Text('Include Rejected Events'),
              subtitle: const Text('Also create calendar events for rejected requests'),
              value: settings.includeRejectedEvents,
              onChanged: (value) => _updateIncludeRejected(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSettingsSection(CalendarState state) {
    final reminderSettings = state.syncSettings?.reminderSettings;
    if (reminderSettings == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Reminder Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Reminders'),
              subtitle: const Text('Set reminders for OD events'),
              value: reminderSettings.enabled,
              onChanged: (value) => _updateReminderEnabled(value),
            ),
            if (reminderSettings.enabled) ...[
              ListTile(
                title: const Text('Reminder Time'),
                subtitle: Text('${reminderSettings.minutesBefore} minutes before'),
                trailing: DropdownButton<int>(
                  value: reminderSettings.minutesBefore,
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5 minutes')),
                    DropdownMenuItem(value: 15, child: Text('15 minutes')),
                    DropdownMenuItem(value: 30, child: Text('30 minutes')),
                    DropdownMenuItem(value: 60, child: Text('1 hour')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _updateReminderTime(value);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(CalendarState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.isLoading || _isBatchSyncing ? null : () => _syncAllEvents(),
                    icon: state.isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: const Text('Quick Sync'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isLoading || _isBatchSyncing ? null : () => _cleanupEvents(),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Cleanup Events'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading calendar settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeCalendarSettings,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Action methods

  Future<void> _requestPermission() async {
    try {
      await ref.read(calendarProvider.notifier).requestPermission();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calendar permission granted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to grant permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateDefaultCalendar(String calendarId) async {
    try {
      await ref.read(calendarProvider.notifier).updateDefaultCalendar(calendarId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update default calendar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateAutoSync(bool enabled) async {
    try {
      await ref.read(calendarProvider.notifier).updateAutoSync(enabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update auto sync: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateSyncApprovedOnly(bool syncApprovedOnly) async {
    try {
      await ref.read(calendarProvider.notifier).updateSyncApprovedOnly(syncApprovedOnly);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update sync settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateIncludeRejected(bool includeRejected) async {
    try {
      await ref.read(calendarProvider.notifier).updateIncludeRejected(includeRejected);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update sync settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateReminderEnabled(bool enabled) async {
    try {
      await ref.read(calendarProvider.notifier).updateReminderEnabled(enabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update reminder settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateReminderTime(int minutes) async {
    try {
      await ref.read(calendarProvider.notifier).updateReminderTime(minutes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update reminder time: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncAllEvents() async {
    try {
      await ref.read(calendarProvider.notifier).syncAllEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All events synced successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync events: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cleanupEvents() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Calendar Events'),
        content: const Text(
          'This will remove all OD-related events from your calendar. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(calendarProvider.notifier).cleanupAllEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All calendar events cleaned up'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cleanup events: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildBatchSyncSection(CalendarState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync_alt, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Batch Calendar Sync',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sync all existing OD requests with your calendar based on current settings',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Sync status indicator
            if (_isBatchSyncing) ...[
              _buildSyncProgressIndicator(),
              const SizedBox(height: 16),
            ],
            
            if (_batchSyncStatus != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _batchSyncStatus!.contains('Error') 
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _batchSyncStatus!.contains('Error') 
                        ? Colors.red.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _batchSyncStatus!.contains('Error') 
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _batchSyncStatus!.contains('Error') 
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _batchSyncStatus!,
                        style: TextStyle(
                          color: _batchSyncStatus!.contains('Error') 
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ),
                    if (_batchSyncStatus!.contains('Error'))
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() => _batchSyncStatus = null),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Batch sync button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.hasPermission && 
                           !state.isLoading && 
                           !_isBatchSyncing &&
                           state.syncSettings?.defaultCalendarId.isNotEmpty == true
                    ? () => _performBatchSync()
                    : null,
                icon: _isBatchSyncing 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_alt),
                label: Text(_isBatchSyncing ? 'Syncing...' : 'Start Batch Sync'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            if (!state.hasPermission)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Calendar permission required for batch sync',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ),
            
            if (state.syncSettings?.defaultCalendarId.isEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please select a default calendar first',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncProgressIndicator() {
    final progress = _totalSyncItems > 0 ? _syncProgress / _totalSyncItems : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Syncing OD requests...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$_syncProgress / $_totalSyncItems',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.3),
        ),
      ],
    );
  }

  // Enhanced action methods

  Future<void> _performBatchSync() async {
    try {
      setState(() {
        _isBatchSyncing = true;
        _batchSyncStatus = null;
        _syncProgress = 0;
        _totalSyncItems = 0;
      });

      // Get all OD requests
      final odRequests = ref.read(odRequestProvider);
      
      if (odRequests.isEmpty) {
        setState(() {
          _batchSyncStatus = 'No OD requests found to sync';
          _isBatchSyncing = false;
        });
        return;
      }

      // Filter requests based on sync settings
      final calendarState = ref.read(calendarProvider).value;
      final syncSettings = calendarState?.syncSettings;
      
      if (syncSettings == null) {
        setState(() {
          _batchSyncStatus = 'Error: Calendar sync settings not available';
          _isBatchSyncing = false;
        });
        return;
      }

      final requestsToSync = odRequests.where((request) {
        if (syncSettings.syncApprovedOnly && !request.isApproved) {
          return syncSettings.includeRejectedEvents && request.isRejected;
        }
        if (request.isRejected && !syncSettings.includeRejectedEvents) {
          return false;
        }
        return true;
      }).toList();

      setState(() {
        _totalSyncItems = requestsToSync.length;
      });

      if (requestsToSync.isEmpty) {
        setState(() {
          _batchSyncStatus = 'No OD requests match current sync settings';
          _isBatchSyncing = false;
        });
        return;
      }

      // Perform batch sync using the enhanced calendar provider
      final result = await ref.read(calendarProvider.notifier).batchSyncODRequests(requestsToSync);

      setState(() {
        _isBatchSyncing = false;
        _syncProgress = result.totalRequests;
        
        if (result.errorCount == 0) {
          _batchSyncStatus = 'Successfully synced ${result.successCount} OD requests to calendar';
        } else if (result.successCount == 0) {
          _batchSyncStatus = 'Error: Failed to sync all ${result.totalRequests} requests. ${result.errors.values.first}';
        } else {
          _batchSyncStatus = 'Synced ${result.successCount} requests, ${result.errorCount} failed. Check logs for details.';
        }
      });

    } catch (e) {
      setState(() {
        _isBatchSyncing = false;
        _batchSyncStatus = 'Error during batch sync: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}