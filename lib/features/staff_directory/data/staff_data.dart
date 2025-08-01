import 'package:odtrack_academia/models/staff_member.dart';

class StaffData {
  static final List<StaffMember> allStaff = [
    const StaffMember(
      id: 'S001',
      name: 'Dr. Alan Grant',
      email: 'alan.grant@example.com',
      department: 'Computer Science',
      subject: 'Data Structures',
      years: ['3rd Year'],
      phone: '123-456-7890',
      designation: 'Professor',
    ),
    const StaffMember(
      id: 'S002',
      name: 'Dr. Ellie Sattler',
      email: 'ellie.sattler@example.com',
      department: 'Computer Science',
      subject: 'Operating Systems',
      years: ['3rd Year'],
      phone: '123-456-7891',
      designation: 'Professor',
    ),
    const StaffMember(
      id: 'S003',
      name: 'Dr. Ian Malcolm',
      email: 'ian.malcolm@example.com',
      department: 'Computer Science',
      subject: 'Computer Networks',
      years: ['3rd Year'],
      phone: '123-456-7892',
      designation: 'Professor',
    ),
    const StaffMember(
      id: 'S004',
      name: 'John Hammond',
      email: 'john.hammond@example.com',
      department: 'Information Technology',
      subject: 'Cloud Computing',
      years: ['4th Year'],
      phone: '123-456-7893',
      designation: 'Associate Professor',
    ),
     const StaffMember(
      id: 'S005',
      name: 'Dennis Nedry',
      email: 'dennis.nedry@example.com',
      department: 'Information Technology',
      subject: 'DevOps',
      years: ['4th Year'],
      phone: '123-456-7894',
      designation: 'Assistant Professor',
    ),
  ];
}
