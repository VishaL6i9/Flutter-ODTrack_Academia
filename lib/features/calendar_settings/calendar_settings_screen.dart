import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odtrack_academia/providers/calendar_provider.dart';

/// Screen for managing calendar integration settings
class CalendarSettingsScreen extends ConsumerStatefulWidget {
  const CalendarSettingsScreen({super.key});

  @override
  ConsumerState<CalendarSettingsScreen> createState() => _CalendarSettingsScreenState();
}

class _CalendarSettingsScreenState extends ConsumerState<CalendarSettingsScreen> {
  bool _isLoading = false;

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
              'Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _syncAllEvents(),
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync All Events'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cleanupEvents(),
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
}