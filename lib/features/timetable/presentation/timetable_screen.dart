import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/features/timetable/presentation/timetable_data.dart';

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
    // Initialize with the first timetable's data
    _selectedYear = TimetableData.allTimetables[0].year;
    _selectedSection = TimetableData.allTimetables[0].section;
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
      appBar: AppBar(
        title: const Text('Timetable'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFilterSection(theme),
          const SizedBox(height: 24),
          _buildTimetableDisplay(theme),
        ],
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Search',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              icon: MdiIcons.calendarBlank,
              label: 'Year',
              value: _selectedYear,
              items: TimetableData.allTimetables.map((t) => t.year).toSet().toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedYear = newValue;
                    // Update section to the first available for the new year
                    _selectedSection = TimetableData.allTimetables
                        .firstWhere((t) => t.year == _selectedYear)
                        .section;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              icon: MdiIcons.accountGroup,
              label: 'Section',
              value: _selectedSection,
              items: TimetableData.allTimetables
                  .where((t) => t.year == _selectedYear)
                  .map((t) => t.section)
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSection = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            _buildSearchField(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search Subject',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildTimetableDisplay(ThemeData theme) {
    final selectedTimetable = TimetableData.allTimetables.firstWhere(
      (t) => t.year == _selectedYear && t.section == _selectedSection,
    );
    final String searchTerm = _searchController.text.toLowerCase();

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
              final subjects = selectedTimetable.schedule[day] ?? List.filled(8, 'Free');
              return DataRow(
                cells: [
                  DataCell(Text(day, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ...subjects.map((subject) {
                    final isHighlighted = searchTerm.isNotEmpty && subject.toLowerCase().contains(searchTerm);
                    return DataCell(_buildSubjectCell(subject, isHighlighted, theme));
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCell(String subject, bool isHighlighted, ThemeData theme) {
    if (subject == 'Free' || subject == 'LUNCH') {
      return Center(
        child: Text(
          subject,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      );
    }

    final color = TimetableData.getSubjectColor(subject);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(isHighlighted ? 80 : 25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: isHighlighted
            ? [BoxShadow(color: color.withAlpha(77), blurRadius: 8, spreadRadius: 1)]
            : [],
      ),
      child: Center(
        child: Text(
          subject,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}