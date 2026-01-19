import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/features/timetable/data/timetable_data.dart';
import 'package:odtrack_academia/models/period_slot.dart';

class TimetableGrid extends StatelessWidget {
  final Map<String, List<PeriodSlot>> schedule;
  final String searchTerm;
  final Function(String staffId)? onStaffTap;
  final Map<String, String> subjectCodeMap;

  const TimetableGrid({
    super.key,
    required this.schedule,
    this.searchTerm = '',
    this.onStaffTap,
    required this.subjectCodeMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String query = searchTerm.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Weekly Overview',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            _buildLegend(theme),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: theme.dividerColor.withOpacity(0.05)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                child: DataTable(
                  dataRowMinHeight: 70,
                  dataRowMaxHeight: 90,
                  headingRowHeight: 50,
                  columnSpacing: 16,
                  horizontalMargin: 16,
                  headingRowColor: WidgetStateProperty.all(
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  columns: [
                    const DataColumn(
                      label: Text('DAY',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2)),
                    ),
                    ...TimetableData.periods.map((period) => DataColumn(
                          label: Text(
                            period.replaceFirst('-', '\n'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                          ),
                        )),
                  ],
                  rows: TimetableData.days.map((day) {
                    final periodSlots = schedule[day] ?? List.filled(TimetableData.periods.length, const PeriodSlot(subject: 'Free'));
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              day.substring(0, 3).toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        ...periodSlots.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final slot = entry.value;
                          final timeRange = TimetableData.periods[idx];
                          final isActive = _isSlotActive(day, timeRange);
                          final isHighlighted = _isSubjectMatch(slot.subject, query);

                          return DataCell(
                            _buildSubjectTile(slot, isHighlighted, isActive, theme),
                            onTap: slot.staffId != null ? () => onStaffTap?.call(slot.staffId!) : null,
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      children: [
        _buildLegendItem(theme, 'Live', Colors.green),
        const SizedBox(width: 12),
        _buildLegendItem(theme, 'Active', theme.colorScheme.primary),
      ],
    );
  }

  Widget _buildLegendItem(ThemeData theme, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }

  Widget _buildSubjectTile(PeriodSlot slot, bool isHighlighted, bool isActive, ThemeData theme) {
    final subject = slot.subject;
    if (subject == 'Free' || subject == 'LUNCH') {
      return Opacity(
        opacity: 0.5,
        child: Center(
          child: Text(
            subject,
            style: TextStyle(color: theme.disabledColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final color = TimetableData.getSubjectColor(subject);
    final icon = _getSubjectIcon(subject);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      width: 110,
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.15) : color.withOpacity(isHighlighted ? 0.25 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : color.withOpacity(isHighlighted ? 0.8 : 0.2),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color.withOpacity(0.8)),
              if (isActive) ...[
                const SizedBox(width: 4),
                _LiveIndicator(color: color),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subject,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          if (slot.staffId != null)
            Text(
              slot.staffId!,
              style: TextStyle(
                color: color.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  bool _isSubjectMatch(String subjectCode, String query) {
    if (query.isEmpty) return false;
    final q = query.toLowerCase();
    final code = subjectCode.toLowerCase();
    final fullName = (subjectCodeMap[subjectCode] ?? '').toLowerCase();

    return code.contains(q) || fullName.contains(q);
  }

  bool _isSlotActive(String day, String timeRange) {
    final now = DateTime.now();
    final currentDay = _getDayFromInt(now.weekday);
    if (day != currentDay) return false;

    try {
      final parts = timeRange.split('-');
      if (parts.length != 2) return false;

      final startParts = parts[0].trim().split(':');
      final endParts = parts[1].trim().split(':');

      final startTime = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
      final endTime = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));

      return now.isAfter(startTime) && now.isBefore(endTime);
    } catch (e) {
      return false;
    }
  }

  String _getDayFromInt(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toUpperCase();
    if (s.contains('MATH')) return MdiIcons.function;
    if (s.contains('PHYSICS')) return MdiIcons.atom;
    if (s.contains('CHEM')) return MdiIcons.flask;
    if (s.contains('ENG')) return MdiIcons.translate;
    if (s.contains('DRAWING')) return MdiIcons.pencilRuler;
    if (s.contains('DSA') || s.contains('DATA')) return MdiIcons.database;
    if (s.contains('OOP')) return MdiIcons.codeBraces;
    if (s.contains('DBMS')) return MdiIcons.databaseSearch;
    if (s.contains('OS')) return MdiIcons.console;
    if (s.contains('CN') || s.contains('NETWORK')) return MdiIcons.lan;
    if (s.contains('LAB')) return MdiIcons.microscope;
    if (s.contains('AI')) return MdiIcons.robot;
    if (s.contains('ML')) return MdiIcons.brain;
    if (s.contains('WEB')) return MdiIcons.web;
    if (s.contains('PROJECT')) return MdiIcons.briefcase;
    if (s.contains('LUNCH')) return MdiIcons.food;
    return MdiIcons.bookOpenVariant;
  }
}

class _LiveIndicator extends StatefulWidget {
  final Color color;
  const _LiveIndicator({required this.color});

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
