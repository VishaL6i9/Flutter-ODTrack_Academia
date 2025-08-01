import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/models/staff_member.dart';

class StaffDirectoryScreen extends ConsumerStatefulWidget {
  const StaffDirectoryScreen({super.key});

  @override
  ConsumerState<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends ConsumerState<StaffDirectoryScreen> {
  String _searchQuery = '';
  String _selectedDepartment = 'All';

  final List<String> _departments = [
    'All',
    'Computer Science',
    'Electronics',
    'Mechanical',
    'Civil',
    'Mathematics',
    'Physics',
    'Chemistry',
  ];

  final List<StaffMember> _demoStaff = [
    const StaffMember(
      id: '1',
      name: 'Dr. Rajesh Kumar',
      email: 'rajesh.kumar@college.edu',
      department: 'Computer Science',
      subject: 'Data Structures',
      years: ['2nd Year', '3rd Year'],
      phone: '+91 9876543210',
      designation: 'Professor',
    ),
    const StaffMember(
      id: '2',
      name: 'Prof. Priya Sharma',
      email: 'priya.sharma@college.edu',
      department: 'Computer Science',
      subject: 'Database Management',
      years: ['3rd Year', '4th Year'],
      phone: '+91 9876543211',
      designation: 'Associate Professor',
    ),
    const StaffMember(
      id: '3',
      name: 'Dr. Amit Patel',
      email: 'amit.patel@college.edu',
      department: 'Electronics',
      subject: 'Digital Electronics',
      years: ['2nd Year'],
      phone: '+91 9876543212',
      designation: 'Assistant Professor',
    ),
    const StaffMember(
      id: '4',
      name: 'Prof. Sunita Reddy',
      email: 'sunita.reddy@college.edu',
      department: 'Mathematics',
      subject: 'Calculus',
      years: ['1st Year', '2nd Year'],
      phone: '+91 9876543213',
      designation: 'Professor',
    ),
    const StaffMember(
      id: '5',
      name: 'Dr. Vikram Singh',
      email: 'vikram.singh@college.edu',
      department: 'Physics',
      subject: 'Quantum Physics',
      years: ['3rd Year', '4th Year'],
      phone: '+91 9876543214',
      designation: 'Associate Professor',
    ),
  ];

  List<StaffMember> get _filteredStaff {
    return _demoStaff.where((staff) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _buildStaffList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
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
              });
            },
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              const Text('Department: ', style: TextStyle(fontWeight: FontWeight.w500)),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedDepartment,
                  isExpanded: true,
                  items: _departments.map((dept) {
                    return DropdownMenuItem(
                      value: dept,
                      child: Text(dept),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value!;
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

  Widget _buildStaffList() {
    final filteredStaff = _filteredStaff;

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
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24.0,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    staff.name.split(' ').map((n) => n[0]).take(2).join(),
                    style: const TextStyle(
                      color: Colors.white,
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
            _buildInfoRow(MdiIcons.email, 'Email', staff.email),
            if (staff.phone != null)
              _buildInfoRow(MdiIcons.phone, 'Phone', staff.phone!),
          ],
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
}