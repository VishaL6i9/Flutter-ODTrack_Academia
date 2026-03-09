import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/staff_member.dart';
import 'package:odtrack_academia/models/timetable.dart';
import 'package:odtrack_academia/models/period_slot.dart';
import 'package:odtrack_academia/services/api/api_client.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';

final educationalDataServiceProvider = Provider<EducationalDataService>((ref) {
  return EducationalDataService(ref.watch(apiClientProvider));
});

class EducationalDataService {
  final ApiClient _apiClient;

  EducationalDataService(this._apiClient);

  /// Get comprehensive list of all staff members
  Future<List<StaffMember>> getStaff() async {
    final response = await _apiClient.get('/dummy-data/staff');
    final List<dynamic> staffList = (response['staff'] as List? ?? []);
    return staffList.map((json) => StaffMember.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get specific staff member by ID
  Future<StaffMember> getStaffById(String staffId) async {
    final response = await _apiClient.get('/dummy-data/staff/$staffId');
    return StaffMember.fromJson(response);
  }

  /// Get personal timetable for a specific staff member
  Future<Map<String, List<PeriodSlot>>> getStaffTimetable(String staffId) async {
    final response = await _apiClient.get('/dummy-data/staff/$staffId/timetable');
    
    final Map<String, List<PeriodSlot>> schedule = {};
    response.forEach((day, slots) {
      if (slots is List) {
        schedule[day] = slots.map((s) => PeriodSlot.fromJson(s as Map<String, dynamic>)).toList();
      }
    });
    return schedule;
  }

  /// Get timetable for a specific section and year
  Future<Timetable> getTimetable({
    required String section,
    required int year,
  }) async {
    final response = await _apiClient.get(
      '/dummy-data/timetable',
      queryParams: {
        'section': section,
        'year': year.toString(),
      },
    );
    return Timetable.fromJson(response);
  }

  /// Get comprehensive list of all departments
  Future<List<dynamic>> getDepartments() async {
    final response = await _apiClient.get('/dummy-data/departments');
    return (response['departments'] as List? ?? []);
  }

  /// Get subjects for a department and year
  Future<List<dynamic>> getSubjects({
    required String department,
    required int year,
  }) async {
    final response = await _apiClient.get(
      '/dummy-data/subjects',
      queryParams: {
        'department': department,
        'year': year.toString(),
      },
    );
    return (response['subjects'] as List? ?? []);
  }

  /// Get comprehensive academic calendar
  Future<Map<String, dynamic>> getAcademicCalendar() async {
    return await _apiClient.get('/dummy-data/academic-calendar');
  }
}
