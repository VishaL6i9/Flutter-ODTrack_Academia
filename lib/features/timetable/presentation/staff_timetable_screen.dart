import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/features/staff_directory/data/staff_data.dart';
import 'package:odtrack_academia/features/timetable/data/timetable_data.dart';
import 'package:odtrack_academia/models/staff_member.dart';

class StaffTimetableScreen extends ConsumerStatefulWidget {
  final String staffId;

  const StaffTimetableScreen({super.key, required this.staffId});

  @override
  ConsumerState<StaffTimetableScreen> createState() => _StaffTimetableScreenState();
}

class _StaffTimetableScreenState extends ConsumerState<StaffTimetableScreen> {
  StaffMember? _staffMember;

  @override
  void initState() {
    super.initState();
    try {
      _staffMember = StaffData.allStaff.firstWhere((staff) => staff.id == widget.staffId);
    } catch (e) {
      // If no staff member found with exact ID, use the first one as demo
      _staffMember = StaffData.allStaff.isNotEmpty ? StaffData.allStaff.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_staffMember == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Staff Timetable'),
          backgroundColor: theme.colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Text('Staff member not found'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${_staffMember!.name}\'s Timetable'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStaffHeader(theme),
          const SizedBox(height: 24),
          _buildTimetableDisplay(theme),
        ],
      ),
    );
  }

  Widget _buildStaffHeader(ThemeData theme) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(MdiIcons.accountTie, size: 40, color: theme.primaryColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _staffMember!.name,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _staffMember!.designation ?? 'Staff',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableDisplay(ThemeData theme) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
          child: DataTable(
            dataRowMinHeight: 60,
            dataRowMaxHeight: 80,
            headingRowHeight: 40,
            columnSpacing: 20,
            columns: [
              const DataColumn(label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold))),
              ...TimetableData.periods.map((period) => DataColumn(
                label: Text(
                  period.replaceFirst('-', '\n'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              )),
            ],
            rows: TimetableData.days.map((day) {
              return DataRow(
                cells: [
                  DataCell(Text(day, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ...List.generate(TimetableData.periods.length, (periodIndex) {
                    final assignedClass = _findAssignedClass(day, periodIndex);
                    return DataCell(_buildClassCell(assignedClass, theme));
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _findAssignedClass(String day, int periodIndex) {
    for (final timetable in TimetableData.allTimetables) {
      final schedule = timetable.schedule[day];
      if (schedule != null && schedule.length > periodIndex) {
        final periodSlot = schedule[periodIndex];
        if (periodSlot.staffId == _staffMember!.id) {
          return '${timetable.year}\n${timetable.section}\n(${periodSlot.subject})';
        }
      }
    }
    return 'Free';
  }

  Widget _buildClassCell(String classInfo, ThemeData theme) {
    if (classInfo == 'Free') {
      return Center(
        child: Text(
          'Free',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      );
    }

    // Extract subject from classInfo (format: "Year\nSection\n(Subject)")
    final lines = classInfo.split('\n');
    final subject = lines.length >= 3 ? lines[2].replaceAll(RegExp(r'[()]'), '') : 'Unknown';
    final color = TimetableData.getSubjectColor(subject);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Center(
        child: Text(
          classInfo,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
