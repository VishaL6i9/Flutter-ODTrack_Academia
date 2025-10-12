import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/core/theme/app_theme.dart';
import 'package:odtrack_academia/providers/sample_data_provider.dart';

/// Debug screen for managing sample data
class SampleDataDebugScreen extends ConsumerWidget {
  const SampleDataDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sampleDataState = ref.watch(sampleDataProvider);
    final isLoading = ref.watch(sampleDataLoadingProvider);
    final error = ref.watch(sampleDataErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Data Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sample Data Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          sampleDataState.isInitialized 
                              ? Icons.check_circle 
                              : Icons.error_outline,
                          color: sampleDataState.isInitialized 
                              ? Colors.green 
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sampleDataState.isInitialized 
                              ? 'Sample data is initialized' 
                              : 'Sample data not initialized',
                          style: TextStyle(
                            color: sampleDataState.isInitialized 
                                ? Colors.green 
                                : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Processing...'),
                        ],
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sample Data Information
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What Sample Data Includes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _InfoItem(
                      icon: Icons.people,
                      title: 'Staff Members',
                      description: '5 sample staff members across different departments',
                    ),
                    _InfoItem(
                      icon: Icons.work,
                      title: 'Workload Data',
                      description: 'Teaching schedules, subjects, and class assignments',
                    ),
                    _InfoItem(
                      icon: Icons.assignment,
                      title: 'OD Requests',
                      description: '50-100 sample OD requests with various statuses',
                    ),
                    _InfoItem(
                      icon: Icons.account_circle,
                      title: 'User Accounts',
                      description: 'Staff and student user accounts for testing',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () {
                  ref.read(sampleDataProvider.notifier).initializeSampleData();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Initialize Sample Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () {
                  ref.read(sampleDataProvider.notifier).reinitializeSampleData();
                },
                icon: const Icon(Icons.autorenew),
                label: const Text('Recreate Sample Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () {
                  _showClearDataDialog(context, ref);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Clear Sample Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Sample Data'),
        content: const Text(
          'Are you sure you want to clear all sample data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(sampleDataProvider.notifier).clearSampleData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}