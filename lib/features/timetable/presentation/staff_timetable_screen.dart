import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/features/staff_directory/data/staff_data.dart';
import 'package:odtrack_academia/features/timetable/data/timetable_data.dart';
import 'package:odtrack_academia/features/timetable/presentation/widgets/timetable_grid.dart';
import 'package:odtrack_academia/models/period_slot.dart';
import 'package:odtrack_academia/models/staff_member.dart';

class StaffTimetableScreen extends ConsumerStatefulWidget {
  final String staffId;

  const StaffTimetableScreen({super.key, required this.staffId});

  @override
  ConsumerState<StaffTimetableScreen> createState() => _StaffTimetableScreenState();
}

  // Manual schedule generation removed in favor of provider

class _StaffTimetableScreenState extends ConsumerState<StaffTimetableScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staffAsync = ref.watch(staffProvider);
    final timetableAsync = ref.watch(staffTimetableProvider(widget.staffId));
    
    return staffAsync.when(
      data: (staffList) {
        final staffMember = staffList.firstWhere(
          (s) => s.id == widget.staffId,
          orElse: () => staffList.first,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('${staffMember.name}\'s Timetable'),
            backgroundColor: theme.colorScheme.surface,
            scrolledUnderElevation: 2,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(staffTimetableProvider(widget.staffId));
                  ref.read(staffProvider.notifier).fetchStaff();
                },
              ),
            ],
          ),
          body: timetableAsync.when(
            data: (schedule) => Container(
              color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  _buildStaffHeader(theme, staffMember),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 600,
                    child: TimetableGrid(
                      schedule: schedule,
                      subjectCodeMap: TimetableData.subjectCodeMap,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading timetable: $err')),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Staff Timetable')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Staff Timetable')),
        body: Center(child: Text('Error loading staff: $err')),
      ),
    );
  }

  Widget _buildStaffHeader(ThemeData theme, StaffMember staffMember) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(MdiIcons.accountTie, size: 30, color: theme.colorScheme.primary),
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
