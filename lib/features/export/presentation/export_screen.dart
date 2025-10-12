import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/providers/export_provider.dart';
import 'package:odtrack_academia/shared/widgets/export_progress_widget.dart';
import 'package:odtrack_academia/shared/widgets/export_history_widget.dart';

/// Screen for exporting reports and viewing export history
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exportProvider.notifier).refreshExportHistory();
      ref.read(exportProvider.notifier).loadExportStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeExports = ref.watch(activeExportsProvider);
    final hasActiveExports = ref.watch(hasActiveExportsProvider);
    final exportError = ref.watch(exportErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Export Actions', icon: Icon(Icons.file_download)),
            Tab(text: 'Progress', icon: Icon(Icons.timeline)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Error banner
          if (exportError != null)
            Container(
              width: double.infinity,
              color: Colors.red[100],
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exportError,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => ref.read(exportProvider.notifier).clearError(),
                  ),
                ],
              ),
            ),

          // Active exports indicator
          if (hasActiveExports)
            Container(
              width: double.infinity,
              color: Colors.blue[100],
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${activeExports.length} export(s) in progress',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ],
              ),
            ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExportActionsTab(),
                _buildProgressTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Student Report Export
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Student Report'),
              subtitle: const Text('Export student OD request history'),
              trailing: ElevatedButton(
                onPressed: () => _exportStudentReport(),
                child: const Text('Export'),
              ),
            ),
          ),

          // Staff Analytics Export
          Card(
            child: ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Staff Analytics'),
              subtitle: const Text('Export staff performance analytics'),
              trailing: ElevatedButton(
                onPressed: () => _exportStaffReport(),
                child: const Text('Export'),
              ),
            ),
          ),

          // Analytics Report Export
          Card(
            child: ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Analytics Report'),
              subtitle: const Text('Export comprehensive analytics'),
              trailing: ElevatedButton(
                onPressed: () => _exportAnalyticsReport(),
                child: const Text('Export'),
              ),
            ),
          ),

          // Bulk Export
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_zip),
              title: const Text('Bulk Export'),
              subtitle: const Text('Export multiple OD requests'),
              trailing: ElevatedButton(
                onPressed: () => _exportBulkRequests(),
                child: const Text('Export'),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Export Options
          Text(
            'Export Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showExportOptionsDialog(),
                          icon: const Icon(Icons.settings),
                          label: const Text('Configure Export'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _clearExportHistory(),
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear History'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _cleanupOldExports(),
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Cleanup Old Exports'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    final activeExports = ref.watch(activeExportsProvider);

    if (activeExports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active exports',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start an export to see progress here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: activeExports.length,
      itemBuilder: (context, index) {
        final exportId = activeExports.keys.elementAt(index);
        return ExportProgressWidget(
          exportId: exportId,
          showDetails: true,
          onCancel: () => _cancelExport(exportId),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return const ExportHistoryWidget(
      showFilters: true,
      showStatistics: true,
    );
  }

  // Export action methods

  Future<void> _exportStudentReport() async {
    try {
      final dateRange = DateRange(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime.now(),
      );

      const options = ExportOptions(
        format: ExportFormat.pdf,
        includeCharts: true,
        includeMetadata: true,
        customTitle: 'Demo Student Report',
      );

      await ref.read(exportProvider.notifier).exportStudentReport(
        'demo_student_123',
        dateRange,
        options,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student report export started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportStaffReport() async {
    try {
      final dateRange = DateRange(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime.now(),
      );

      const options = ExportOptions(
        format: ExportFormat.pdf,
        includeCharts: true,
        includeMetadata: true,
        customTitle: 'Demo Staff Analytics Report',
      );

      await ref.read(exportProvider.notifier).exportStaffReport(
        'demo_staff_456',
        dateRange,
        options,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff report export started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportAnalyticsReport() async {
    try {
      // Create demo analytics data
      const analyticsData = AnalyticsData(
        totalRequests: 150,
        approvedRequests: 120,
        rejectedRequests: 20,
        pendingRequests: 10,
        approvalRate: 80.0,
        requestsByMonth: {
          'Jan': 25,
          'Feb': 30,
          'Mar': 35,
          'Apr': 28,
          'May': 32,
        },
        requestsByDepartment: {
          'Computer Science': 60,
          'Information Technology': 45,
          'Electronics': 30,
          'Mechanical': 15,
        },
        topRejectionReasons: [
          RejectionReason(
            reason: 'Insufficient notice period',
            count: 12,
            percentage: 60.0,
          ),
          RejectionReason(
            reason: 'Missing documentation',
            count: 5,
            percentage: 25.0,
          ),
          RejectionReason(
            reason: 'Exceeds monthly limit',
            count: 3,
            percentage: 15.0,
          ),
        ],
        patterns: [
          RequestPattern(
            pattern: 'High requests on Fridays',
            description: 'Students tend to request more ODs on Fridays',
            confidence: 0.85,
          ),
          RequestPattern(
            pattern: 'Seasonal variation',
            description: 'More requests during exam periods',
            confidence: 0.72,
          ),
        ],
      );

      const options = ExportOptions(
        format: ExportFormat.pdf,
        includeCharts: true,
        includeMetadata: true,
        customTitle: 'Demo Analytics Report',
      );

      await ref.read(exportProvider.notifier).exportAnalyticsReport(
        analyticsData,
        options,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analytics report export started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportBulkRequests() async {
    try {
      // Create demo OD requests
      final requests = List.generate(10, (index) {
        return ODRequest(
          id: 'demo_req_$index',
          studentId: 'student_$index',
          studentName: 'Demo Student ${index + 1}',
          registerNumber: 'REG${(index + 1).toString().padLeft(3, '0')}',
          date: DateTime.now().subtract(Duration(days: index)),
          periods: [1, 2, 3],
          reason: index % 3 == 0 ? 'Medical appointment' : 
                  index % 3 == 1 ? 'Family function' : 'Personal work',
          status: index % 4 == 0 ? 'pending' : 
                  index % 4 == 1 ? 'approved' : 
                  index % 4 == 2 ? 'rejected' : 'approved',
          createdAt: DateTime.now().subtract(Duration(days: index, hours: 2)),
          staffId: 'demo_staff_456',
          approvedBy: index % 2 == 0 ? 'Dr. Demo Staff' : null,
          approvedAt: index % 2 == 0 ? DateTime.now().subtract(Duration(days: index, hours: 1)) : null,
          rejectionReason: index % 4 == 2 ? 'Insufficient notice' : null,
        );
      });

      const options = ExportOptions(
        format: ExportFormat.pdf,
        includeCharts: false,
        includeMetadata: true,
        customTitle: 'Demo Bulk Export',
      );

      await ref.read(exportProvider.notifier).exportBulkRequests(requests, options);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bulk export started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelExport(String exportId) async {
    try {
      await ref.read(exportProvider.notifier).cancelExport(exportId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearExportHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Export History'),
        content: const Text('Are you sure you want to clear all export history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(exportProvider.notifier).clearExportHistory();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export history cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear history: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cleanupOldExports() async {
    try {
      await ref.read(exportProvider.notifier).cleanupOldExports(
        olderThan: const Duration(days: 7),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Old exports cleaned up'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleanup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExportOptionsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available export formats:'),
            SizedBox(height: 8),
            Text('• PDF - Full featured reports with charts'),
            Text('• CSV - Data export for spreadsheets'),
            SizedBox(height: 16),
            Text('Features:'),
            SizedBox(height: 8),
            Text('• Progress tracking with cancellation'),
            Text('• Native sharing integration'),
            Text('• Export history management'),
            Text('• Automatic cleanup of old files'),
            Text('• Advanced filtering and search'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}