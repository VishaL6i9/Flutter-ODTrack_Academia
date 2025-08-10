import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/models/notification_message.dart';
import 'package:odtrack_academia/features/notifications/notification_history_screen.dart';

/// Widget for filtering notifications
class NotificationFilterWidget extends StatefulWidget {
  final NotificationFilter currentFilter;
  final void Function(NotificationFilter) onFilterChanged;

  const NotificationFilterWidget({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<NotificationFilterWidget> createState() => _NotificationFilterWidgetState();
}

class _NotificationFilterWidgetState extends State<NotificationFilterWidget> {
  late TextEditingController _searchController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.currentFilter.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveFilters = _hasActiveFilters();
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Search bar and filter toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notifications...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _updateFilter(searchQuery: '');
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) => _updateFilter(searchQuery: value),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Filter toggle button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Badge(
                    isLabelVisible: hasActiveFilters,
                    child: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        MdiIcons.filterVariant,
                        color: hasActiveFilters 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  tooltip: 'Filter options',
                ),
              ],
            ),
          ),
          
          // Expandable filter options
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isExpanded ? null : 0,
            child: _isExpanded ? _buildFilterOptions() : null,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterOptions() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // Quick filters
          Row(
            children: [
              Text(
                'Quick filters:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(width: 12),
              
              FilterChip(
                label: const Text('Unread only'),
                selected: widget.currentFilter.showOnlyUnread,
                onSelected: (selected) => _updateFilter(showOnlyUnread: selected),
                avatar: const Icon(Icons.mark_email_unread, size: 16),
              ),
              
              const SizedBox(width: 8),
              
              FilterChip(
                label: const Text('Today'),
                selected: _isTodayFilter(),
                onSelected: (selected) {
                  if (selected) {
                    final today = DateTime.now();
                    final startOfDay = DateTime(today.year, today.month, today.day);
                    final endOfDay = startOfDay.add(const Duration(days: 1));
                    _updateFilter(startDate: startOfDay, endDate: endOfDay);
                  } else {
                    _updateFilter(startDate: null, endDate: null);
                  }
                },
                avatar: const Icon(Icons.today, size: 16),
              ),
              
              const Spacer(),
              
              // Clear filters button
              if (_hasActiveFilters())
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear all'),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Notification types
          Text(
            'Notification types:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: NotificationType.values.map((type) {
              final isSelected = widget.currentFilter.types.contains(type);
              return FilterChip(
                label: Text(_getTypeLabel(type)),
                selected: isSelected,
                onSelected: (selected) => _toggleType(type, selected),
                avatar: Icon(_getTypeIcon(type), size: 16),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Priority levels
          Text(
            'Priority levels:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: NotificationPriority.values.map((priority) {
              final isSelected = widget.currentFilter.priorities.contains(priority);
              return FilterChip(
                label: Text(_getPriorityLabel(priority)),
                selected: isSelected,
                onSelected: (selected) => _togglePriority(priority, selected),
                avatar: Icon(_getPriorityIcon(priority), size: 16),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Date range
          Row(
            children: [
              Text(
                'Date range:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(width: 12),
              
              OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(_getDateRangeLabel()),
              ),
              
              if (widget.currentFilter.startDate != null || 
                  widget.currentFilter.endDate != null)
                IconButton(
                  onPressed: () => _updateFilter(startDate: null, endDate: null),
                  icon: const Icon(Icons.clear, size: 16),
                  tooltip: 'Clear date range',
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _updateFilter({
    List<NotificationType>? types,
    List<NotificationPriority>? priorities,
    DateTime? startDate,
    DateTime? endDate,
    bool? showOnlyUnread,
    String? searchQuery,
  }) {
    final newFilter = widget.currentFilter.copyWith(
      types: types,
      priorities: priorities,
      startDate: startDate,
      endDate: endDate,
      showOnlyUnread: showOnlyUnread,
      searchQuery: searchQuery,
    );
    
    widget.onFilterChanged(newFilter);
  }
  
  void _toggleType(NotificationType type, bool selected) {
    final currentTypes = List<NotificationType>.from(widget.currentFilter.types);
    
    if (selected) {
      currentTypes.add(type);
    } else {
      currentTypes.remove(type);
    }
    
    _updateFilter(types: currentTypes);
  }
  
  void _togglePriority(NotificationPriority priority, bool selected) {
    final currentPriorities = List<NotificationPriority>.from(widget.currentFilter.priorities);
    
    if (selected) {
      currentPriorities.add(priority);
    } else {
      currentPriorities.remove(priority);
    }
    
    _updateFilter(priorities: currentPriorities);
  }
  
  void _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: widget.currentFilter.startDate != null && 
                       widget.currentFilter.endDate != null
          ? DateTimeRange(
              start: widget.currentFilter.startDate!,
              end: widget.currentFilter.endDate!,
            )
          : null,
    );
    
    if (dateRange != null) {
      _updateFilter(
        startDate: dateRange.start,
        endDate: dateRange.end,
      );
    }
  }
  
  void _clearAllFilters() {
    _searchController.clear();
    widget.onFilterChanged(const NotificationFilter());
  }
  
  bool _hasActiveFilters() {
    return widget.currentFilter.types.isNotEmpty ||
           widget.currentFilter.priorities.isNotEmpty ||
           widget.currentFilter.startDate != null ||
           widget.currentFilter.endDate != null ||
           widget.currentFilter.showOnlyUnread ||
           widget.currentFilter.searchQuery.isNotEmpty;
  }
  
  bool _isTodayFilter() {
    if (widget.currentFilter.startDate == null || widget.currentFilter.endDate == null) {
      return false;
    }
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return widget.currentFilter.startDate!.isAtSameMomentAs(startOfDay) &&
           widget.currentFilter.endDate!.isAtSameMomentAs(endOfDay);
  }
  
  String _getDateRangeLabel() {
    if (widget.currentFilter.startDate == null && widget.currentFilter.endDate == null) {
      return 'Select range';
    }
    
    if (_isTodayFilter()) {
      return 'Today';
    }
    
    final start = widget.currentFilter.startDate;
    final end = widget.currentFilter.endDate;
    
    if (start != null && end != null) {
      return '${_formatDate(start)} - ${_formatDate(end)}';
    } else if (start != null) {
      return 'From ${_formatDate(start)}';
    } else if (end != null) {
      return 'Until ${_formatDate(end)}';
    }
    
    return 'Select range';
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.odStatusChange:
        return 'Status Updates';
      case NotificationType.newODRequest:
        return 'New Requests';
      case NotificationType.reminder:
        return 'Reminders';
      case NotificationType.bulkOperationComplete:
        return 'Bulk Operations';
      case NotificationType.systemUpdate:
        return 'System Updates';
    }
  }
  
  String _getPriorityLabel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }
  
  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.odStatusChange:
        return MdiIcons.fileDocumentEdit;
      case NotificationType.newODRequest:
        return MdiIcons.fileDocumentPlus;
      case NotificationType.reminder:
        return MdiIcons.bell;
      case NotificationType.bulkOperationComplete:
        return MdiIcons.checkboxMultipleMarked;
      case NotificationType.systemUpdate:
        return MdiIcons.update;
    }
  }
  
  IconData _getPriorityIcon(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Icons.keyboard_arrow_down;
      case NotificationPriority.normal:
        return Icons.remove;
      case NotificationPriority.high:
        return Icons.keyboard_arrow_up;
      case NotificationPriority.urgent:
        return Icons.priority_high;
    }
  }
}