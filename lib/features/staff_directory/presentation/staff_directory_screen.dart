import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/features/timetable/presentation/staff_timetable_screen.dart';
import 'package:odtrack_academia/models/staff_member.dart';
import 'package:odtrack_academia/providers/staff_provider.dart';
import 'package:odtrack_academia/core/theme/app_theme.dart';

class StaffDirectoryScreen extends ConsumerStatefulWidget {
  final String? preFilterStaffId; // Optional parameter to pre-filter to specific staff
  
  const StaffDirectoryScreen({super.key, this.preFilterStaffId});

  @override
  ConsumerState<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends ConsumerState<StaffDirectoryScreen> {
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  bool _isPreFiltered = false;
  late TextEditingController _searchController;

  List<String> getDepartments(List<StaffMember> staffList) {
    final departments = staffList.map((staff) => staff.department).toSet().toList();
    departments.sort();
    departments.insert(0, 'All');
    return departments;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    
    // Pre-filtering logic moved to build or data handling
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StaffMember> getFilteredStaff(List<StaffMember> staffList) {
    // If pre-filtered, show only the specific staff member initially
    if (_isPreFiltered && widget.preFilterStaffId != null) {
      return staffList.where((staff) => staff.id == widget.preFilterStaffId).toList();
    }
    
    return staffList.where((staff) {
      final matchesSearch = staff.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          staff.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          staff.department.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesDepartment = _selectedDepartment == 'All' || 
          staff.department == _selectedDepartment;
      
      return matchesSearch && matchesDepartment;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Staff Directory'),
        actions: _isPreFiltered ? [
          TextButton(
            onPressed: () {
              setState(() {
                _isPreFiltered = false;
                _searchQuery = '';
                _searchController.clear();
                _selectedDepartment = 'All';
              });
            },
            child: const Text(
              'View All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ] : [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(staffProvider.notifier).fetchStaff(),
          ),
        ],
      ),
      body: staffAsync.when(
        data: (staffList) {
          // Initialize pre-filter if needed and not already done
          if (widget.preFilterStaffId != null && _searchQuery.isEmpty && !_isPreFiltered && _selectedDepartment == 'All') {
            try {
              final staff = staffList.firstWhere((s) => s.id == widget.preFilterStaffId);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _searchQuery = staff.name;
                    _searchController.text = staff.name;
                    _selectedDepartment = staff.department;
                    _isPreFiltered = true;
                  });
                }
              });
            } catch (_) {}
          }

          final filteredStaff = getFilteredStaff(staffList);
          final departments = getDepartments(staffList);

          return Column(
            children: [
              _buildSearchAndFilter(departments),
              Expanded(
                child: _buildStaffList(filteredStaff),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err'),
              ElevatedButton(
                onPressed: () => ref.read(staffProvider.notifier).fetchStaff(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentTeal,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(List<String> departments) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search staff by name, subject, or department',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                // If user modifies search, disable pre-filtering
                if (widget.preFilterStaffId != null && _isPreFiltered) {
                  _isPreFiltered = false;
                }
              });
            },
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              const Text('Department: ', style: TextStyle(fontWeight: FontWeight.w500)),
              Expanded(
                child: DropdownButton<String>(
                  value: departments.contains(_selectedDepartment) ? _selectedDepartment : 'All',
                  isExpanded: true,
                  items: departments.map((dept) {
                    return DropdownMenuItem(
                      value: dept,
                      child: Text(dept),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value!;
                      // If user modifies department filter, disable pre-filtering
                      if (widget.preFilterStaffId != null && _isPreFiltered) {
                        _isPreFiltered = false;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList(List<StaffMember> filteredStaff) {
    if (filteredStaff.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64.0, color: Colors.grey),
            SizedBox(height: 16.0),
            Text(
              'No staff members found',
              style: TextStyle(fontSize: 18.0, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredStaff.length,
      itemBuilder: (context, index) {
        final staff = filteredStaff[index];
        return _buildStaffCard(staff);
      },
    );
  }

  Widget _buildStaffCard(StaffMember staff) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => StaffTimetableScreen(staffId: staff.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24.0,
                    backgroundColor: AppTheme.accentPurple.withValues(alpha: 0.2),
                    child: Text(
                      staff.name.split(' ').map((n) => n[0]).take(2).join(),
                      style: const TextStyle(
                        color: AppTheme.accentPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.name,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (staff.designation != null)
                          Text(
                            staff.designation!,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              _buildInfoRow(MdiIcons.domain, 'Department', staff.department),
              _buildInfoRow(MdiIcons.bookOpenPageVariant, 'Subject', staff.subject),
              _buildInfoRow(MdiIcons.schoolOutline, 'Years', staff.years.join(', ')),
              _buildCoordinatorInfoRow(staff),
              _buildInfoRow(MdiIcons.email, 'Email', staff.email),
              if (staff.phone != null)
                _buildInfoRow(MdiIcons.phone, 'Phone', staff.phone!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.0, color: Colors.grey[600]),
          const SizedBox(width: 8.0),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatorInfoRow(StaffMember staff) {
    List<String> coordinatorRoles = [];

    if (staff.isClassCoordinator && staff.coordinatedSections.isNotEmpty) {
      // Show specific sections instead of just count
      for (String section in staff.coordinatedSections) {
        coordinatorRoles.add('Class Coordinator ($section)');
      }
    }

    if (staff.isYearCoordinator && staff.coordinatedYears.isNotEmpty) {
      // Show specific years instead of just count
      for (String year in staff.coordinatedYears) {
        coordinatorRoles.add('Year Coordinator ($year)');
      }
    }

    if (coordinatorRoles.isEmpty) {
      return Container(); // Return empty container if not a coordinator
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(MdiIcons.accountTie, size: 16.0, color: Colors.grey[600]),
          const SizedBox(width: 8.0),
          const Text(
            'Roles: ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Wrap(
              spacing: 4.0,
              runSpacing: 2.0,
              children: [
                for (int i = 0; i < coordinatorRoles.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      coordinatorRoles[i],
                      style: const TextStyle(
                        color: AppTheme.accentTeal,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
