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

class _StaffTimetableScreenState extends ConsumerState<StaffTimetableScreen> {
  StaffMember? _staffMember;
  late Map<String, List<PeriodSlot>> _staffSchedule;

  @override
  void initState() {
    super.initState();
    try {
      _staffMember = StaffData.allStaff.firstWhere((staff) => staff.id == widget.staffId);
    } catch (e) {
      _staffMember = StaffData.allStaff.isNotEmpty ? StaffData.allStaff.first : null;
    }
    _generateStaffSchedule();
  }

  void _generateStaffSchedule() {
    _staffSchedule = {};
    if (_staffMember == null) return;

    for (final day in TimetableData.days) {
      final List<PeriodSlot> daySlots = List.generate(
        TimetableData.periods.length,
        (index) => const PeriodSlot(subject: 'Free'),
      );

      for (final timetable in TimetableData.allTimetables) {
        final schedule = timetable.schedule[day];
        if (schedule != null) {
          for (int i = 0; i < schedule.length; i++) {
            if (i < daySlots.length && schedule[i].staffId == _staffMember!.id) {
              // Create a modified subject string to show Year/Section in the grid
              daySlots[i] = PeriodSlot(
                subject: schedule[i].subject,
                staffId: '${timetable.year} ${timetable.section}',
              );
            }
          }
        }
      }
      _staffSchedule[day] = daySlots;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_staffMember == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Staff Timetable'),
          backgroundColor: theme.colorScheme.surface,
        ),
        body: const Center(
          child: Text('Staff member not found'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${_staffMember!.name}\'s Timetable'),
        backgroundColor: theme.colorScheme.surface,
        scrolledUnderElevation: 2,
      ),
      body: Container(
        color: theme.colorScheme.surfaceContainerLowest.withOpacity(0.5),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            _buildStaffHeader(theme),
            const SizedBox(height: 24),
            SizedBox(
              height: 600, // Constrain height for the scrollable grid
              child: TimetableGrid(
                schedule: _staffSchedule,
                subjectCodeMap: TimetableData.subjectCodeMap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffHeader(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(MdiIcons.accountTie, size: 30, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _staffMember!.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _staffMember!.designation ?? 'Staff Member',
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
