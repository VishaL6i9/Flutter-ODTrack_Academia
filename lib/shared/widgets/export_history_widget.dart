import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/providers/export_provider.dart';

/// Widget for displaying and managing export history
class ExportHistoryWidget extends ConsumerStatefulWidget {
  final bool showFilters;
  final bool showStatistics;

  const ExportHistoryWidget({
    super.key,
    this.showFilters = true,
    this.showStatistics = true,
  });

  @override
  ConsumerState<ExportHistoryWidget> createState() => _ExportHistoryWidgetState();
}

class _ExportHistoryWidgetState extends ConsumerState<ExportHistoryWidget> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exportProvider.notifier).refreshExportHistory();
      ref.read(exportProvider.notifier).loadExportStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = ref.watch(filteredExportHistoryProvider);
    final currentFilter = ref.watch(currentExportFilterProvider);
    final statistics = ref.watch(exportStatisticsProvider);
    final isLoadingHistory = ref.watch(exportHistoryLoadingProvider);
    final isLoadingStatistics = ref.watch(exportStatisticsLoadingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistics section
        if (widget.showStatistics && statistics != null)
          _buildStatisticsSection(context, statistics, isLoadingStatistics),

        // Filters section
        if (widget.showFilters)
          _buildFiltersSection(context, currentFilter),

        const SizedBox(height: 16),

        // History list
        Expanded(
          child: _buildHistoryList(context, filteredHistory, isLoadingHistory),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    ExportStatistics statistics,
    bool isLoading,
  ) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Exports',
                    statistics.totalExports.toString(),
                    Icons.file_download,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Success Rate',
                    '${statistics.successRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'This Week',
                    statistics.exportsThisWeek.toString(),
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Avg Size',
                    statistics.formattedAverageFileSize,
                    Icons.storage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).primaryColor).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color ?? Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context, ExportHistoryFilter currentFilter) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (currentFilter.hasFilters)
                  TextButton(
                    onPressed: () => _clearFilters(),
                    child: const Text('Clear All'),
                  ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFilterDialog(context, currentFilter),
                ),
              ],
            ),
            if (currentFilter.hasFilters) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (currentFilter.format != null)
                    Chip(
                      label: Text(currentFilter.format!.name.toUpperCase()),
                      onDeleted: () => _removeFormatFilter(),
                    ),
                  if (currentFilter.successOnly != null)
                    Chip(
                      label: Text(currentFilter.successOnly! ? 'Success Only' : 'Failed Only'),
                      onDeleted: () => _removeSuccessFilter(),
                    ),
                  if (currentFilter.searchQuery?.isNotEmpty == true)
                    Chip(
                      label: Text('Search: ${currentFilter.searchQuery}'),
                      onDeleted: () => _removeSearchFilter(),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<ExportResult> history,
    bool isLoading,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No export history found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your export history will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final export = history[index];
        return ExportHistoryTile(
          export: export,
          onShare: () => _shareExport(export),
          onOpen: () => _openExport(export),
          onDelete: () => _deleteExport(export),
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context, ExportHistoryFilter currentFilter) {
    showDialog<void>(
      context: context,
      builder: (context) => ExportFilterDialog(
        currentFilter: currentFilter,
        onApply: (filter) => _applyFilter(filter),
      ),
    );
  }

  void _applyFilter(ExportHistoryFilter filter) {
    ref.read(exportProvider.notifier).applyHistoryFilter(filter);
  }

  void _clearFilters() {
    _applyFilter(const ExportHistoryFilter());
  }

  void _removeFormatFilter() {
    final currentFilter = ref.read(currentExportFilterProvider);
    _applyFilter(currentFilter.copyWith(format: null));
  }

  void _removeSuccessFilter() {
    final currentFilter = ref.read(currentExportFilterProvider);
    _applyFilter(currentFilter.copyWith(successOnly: null));
  }

  void _removeSearchFilter() {
    final currentFilter = ref.read(currentExportFilterProvider);
    _applyFilter(currentFilter.copyWith(searchQuery: ''));
  }

  void _shareExport(ExportResult export) {
    ref.read(exportProvider.notifier).shareExportedFile(export.filePath);
  }

  void _openExport(ExportResult export) {
    ref.read(exportProvider.notifier).openExportedFile(export.filePath);
  }

  void _deleteExport(ExportResult export) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Export'),
        content: Text('Are you sure you want to delete "${export.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(exportProvider.notifier).deleteExportFromHistory(export.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Individual export history tile
class ExportHistoryTile extends StatelessWidget {
  final ExportResult export;
  final VoidCallback? onShare;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  const ExportHistoryTile({
    super.key,
    required this.export,
    this.onShare,
    this.onOpen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: export.success ? Colors.green : Colors.red,
          child: Icon(
            export.success ? Icons.check : Icons.error,
            color: Colors.white,
          ),
        ),
        title: Text(
          export.fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${export.format.name.toUpperCase()} • ${export.formattedFileSize}',
            ),
            Text(
              _formatDate(export.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!export.success && export.errorMessage != null)
              Text(
                export.errorMessage!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'share':
                onShare?.call();
                break;
              case 'open':
                onOpen?.call();
                break;
              case 'delete':
                onDelete?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            if (export.success) ...[
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'open',
                child: ListTile(
                  leading: Icon(Icons.open_in_new),
                  title: Text('Open'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        isThreeLine: !export.success && export.errorMessage != null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Dialog for filtering export history
class ExportFilterDialog extends StatefulWidget {
  final ExportHistoryFilter currentFilter;
  final void Function(ExportHistoryFilter) onApply;

  const ExportFilterDialog({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<ExportFilterDialog> createState() => _ExportFilterDialogState();
}

class _ExportFilterDialogState extends State<ExportFilterDialog> {
  late ExportFormat? selectedFormat;
  late bool? successOnly;
  late String searchQuery;
  late DateTime? startDate;
  late DateTime? endDate;

  @override
  void initState() {
    super.initState();
    selectedFormat = widget.currentFilter.format;
    successOnly = widget.currentFilter.successOnly;
    searchQuery = widget.currentFilter.searchQuery ?? '';
    startDate = widget.currentFilter.startDate;
    endDate = widget.currentFilter.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Export History'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format filter
            Text(
              'Format',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            DropdownButton<ExportFormat?>(
              value: selectedFormat,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Formats')),
                ...ExportFormat.values.map(
                  (format) => DropdownMenuItem(
                    value: format,
                    child: Text(format.name.toUpperCase()),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => selectedFormat = value),
            ),

            const SizedBox(height: 16),

            // Success filter
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            DropdownButton<bool?>(
              value: successOnly,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: null, child: Text('All Exports')),
                DropdownMenuItem(value: true, child: Text('Successful Only')),
                DropdownMenuItem(value: false, child: Text('Failed Only')),
              ],
              onChanged: (value) => setState(() => successOnly = value),
            ),

            const SizedBox(height: 16),

            // Search query
            Text(
              'Search',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextField(
              controller: TextEditingController(text: searchQuery),
              decoration: const InputDecoration(
                hintText: 'Search by filename or error message',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => searchQuery = value,
            ),

            const SizedBox(height: 16),

            // Date range
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _selectStartDate(context),
                    child: Text(
                      startDate != null
                          ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                          : 'Start Date',
                    ),
                  ),
                ),
                const Text(' - '),
                Expanded(
                  child: TextButton(
                    onPressed: () => _selectEndDate(context),
                    child: Text(
                      endDate != null
                          ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                          : 'End Date',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _clearFilters(),
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () => _applyFilters(),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  void _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => startDate = date);
    }
  }

  void _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => endDate = date);
    }
  }

  void _clearFilters() {
    setState(() {
      selectedFormat = null;
      successOnly = null;
      searchQuery = '';
      startDate = null;
      endDate = null;
    });
  }

  void _applyFilters() {
    final filter = ExportHistoryFilter(
      format: selectedFormat,
      successOnly: successOnly,
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      startDate: startDate,
      endDate: endDate,
    );
    widget.onApply(filter);
    Navigator.of(context).pop();
  }
}