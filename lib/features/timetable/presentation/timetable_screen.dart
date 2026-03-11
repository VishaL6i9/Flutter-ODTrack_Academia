import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/features/timetable/data/timetable_data.dart';
import 'package:odtrack_academia/features/timetable/presentation/staff_timetable_screen.dart';
import 'package:odtrack_academia/features/timetable/presentation/widgets/timetable_grid.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';
import 'package:odtrack_academia/providers/staff_provider.dart';
import 'package:odtrack_academia/providers/timetable_provider.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  late String _selectedYear;
  late String _selectedSection;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _selectedYear = user?.year ?? '3rd Year';
    _selectedSection = user?.section ?? 'A';
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Weekly Timetable'),
        backgroundColor: theme.colorScheme.surface,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(timetableProvider((section: _selectedSection, year: _selectedYear)));
              ref.read(staffProvider.notifier).fetchStaff();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterHeader(theme),
          Expanded(
            child: Container(
              color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: _buildTimetableDisplay(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSelectionCard(
                  icon: MdiIcons.calendarBlank,
                  label: 'Academic Year',
                  value: _selectedYear,
                  onTap: () => _showSelectionDialog(
                    title: 'Select Year',
                    currentValue: _selectedYear,
                    items: ['1st Year', '2nd Year', '3rd Year', '4th Year'],
                    onSelected: (newValue) {
                      setState(() {
                        _selectedYear = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectionCard(
                  icon: MdiIcons.accountGroup,
                  label: 'Class Section',
                  value: _selectedSection,
                  onTap: () => _showSelectionDialog(
                    title: 'Select Section',
                    currentValue: _selectedSection,
                    items: ['A', 'B', 'C'],
                    onSelected: (newValue) {
                      setState(() => _selectedSection = newValue);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.unfold_more, size: 14, color: theme.disabledColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectionDialog({
    required String title,
    required String currentValue,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    final theme = Theme.of(context);
    final dialogBg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface, // Keep dialog surface for elevation and clarity
          surfaceTintColor: Colors.transparent,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          content: Container(
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map((item) {
                  final isSelected = item == currentValue;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(
                      item,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    trailing: isSelected 
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) 
                        : null,
                    onTap: () {
                      onSelected(item);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by Subject Name or Code...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildTimetableDisplay(ThemeData theme) {
    final timetableAsync = ref.watch(timetableProvider((section: _selectedSection, year: _selectedYear)));

    return timetableAsync.when(
      data: (timetable) => TimetableGrid(
        schedule: timetable.schedule,
        searchTerm: _searchController.text,
        subjectCodeMap: TimetableData.subjectCodeMap,
        onStaffTap: (staffId) => _showStaffInfoDialog(context, staffId),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading timetable: $err')),
    );
  }

  void _showStaffInfoDialog(BuildContext context, String staffId) {
    final staffAsync = ref.read(staffProvider);
    
    staffAsync.whenData((staffList) {
      final staffMember = staffList.firstWhere(
        (s) => s.id == staffId,
        orElse: () => staffList.firstWhere((s) => s.name.contains(staffId), orElse: () => staffList.first),
      );
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Text(
                        staffMember.name[0],
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staffMember.name,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            staffMember.designation ?? 'Staff Member',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildInfoRow(MdiIcons.officeBuilding, 'Department', staffMember.department),
                    const SizedBox(height: 12),
                    _buildInfoRow(MdiIcons.email, 'Email', staffMember.email),
                    if (staffMember.phone != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(MdiIcons.phone, 'Phone', staffMember.phone!),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) => StaffTimetableScreen(staffId: staffId),
                            ),
                          );
                        },
                        child: const Text('Full Schedule'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    });
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
