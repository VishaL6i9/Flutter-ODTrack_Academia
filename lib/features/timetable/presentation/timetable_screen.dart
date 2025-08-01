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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSection(),
            const SizedBox(height: 24),
            _buildTimetable(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildDropdown(
                  label: 'Year',
                  value: _selectedYear,
                  items: TimetableData.allTimetables.map((t) => t.year).toSet().toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedYear = newValue!;
                      _selectedSection = TimetableData.allTimetables
                          .firstWhere((t) => t.year == _selectedYear)
                          .section;
                    });
                  },
                ),
                _buildDropdown(
                  label: 'Section',
                  value: _selectedSection,
                  items: TimetableData.allTimetables
                      .where((t) => t.year == _selectedYear)
                      .map((t) => t.section)
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedSection = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSearchField(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search Subject',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (value) {
        setState(() {}); // Rebuild to apply filter
      },
    );
  }

  Widget _buildTimetable() {
    final selectedTimetable = TimetableData.allTimetables.firstWhere(
      (t) => t.year == _selectedYear && t.section == _selectedSection,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(selectedTimetable),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Day')),
                  ...TimetableData.periods.map((period) => DataColumn(label: Text(period))),
                ],
                rows: TimetableData.days.map((day) => _buildDayRow(day)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDayRow(String day) {
    final subjects = _getFilteredSubjects(day);
    return DataRow(
      cells: [
        DataCell(Text(day, style: const TextStyle(fontWeight: FontWeight.bold))),
        ...subjects.map((subject) => DataCell(_buildSubjectCell(subject))),
      ],
    );
  }

  Widget _buildSubjectCell(String subject) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TimetableData.getSubjectColor(subject).withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        subject,
        style: TextStyle(
          color: TimetableData.getSubjectColor(subject),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHeader(Timetable selectedTimetable) {
    return Row(
      children: [
        Icon(MdiIcons.timetable, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${selectedTimetable.year} - ${selectedTimetable.section}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Class Schedule',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getFilteredSubjects(String day) {
    final selectedTimetable = TimetableData.allTimetables.firstWhere(
      (t) => t.year == _selectedYear && t.section == _selectedSection,
    );
    final allSubjects = selectedTimetable.schedule[day] ?? List.filled(5, 'Free');
    if (_searchController.text.isEmpty) {
      return allSubjects;
    } else {
      return allSubjects
          .map((subject) =>
              subject.toLowerCase().contains(_searchController.text.toLowerCase()) ? subject : 'Free')
          .toList();
    }
  }
}
