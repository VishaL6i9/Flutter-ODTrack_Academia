import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/staff_member.dart';
import 'package:odtrack_academia/services/api/educational_data_service.dart';
import 'package:odtrack_academia/models/period_slot.dart';

final staffProvider = StateNotifierProvider<StaffNotifier, AsyncValue<List<StaffMember>>>((ref) {
  return StaffNotifier(ref.watch(educationalDataServiceProvider));
});

class StaffNotifier extends StateNotifier<AsyncValue<List<StaffMember>>> {
  final EducationalDataService _service;

  StaffNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchStaff();
  }

  Future<void> fetchStaff() async {
    state = const AsyncValue.loading();
    try {
      final staff = await _service.getStaff();
      state = AsyncValue.data(staff);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<StaffMember?> getStaffById(String id) async {
    // If we have data, we can find it locally
    if (state.hasValue) {
      final staff = state.value!.where((s) => s.id == id);
      if (staff.isNotEmpty) return staff.first;
    }
    
    // Otherwise fetch specifically (if API supports it, here we just return null or fetch all)
    try {
      return await _service.getStaffById(id);
    } catch (_) {
      return null;
    }
  }
}

final staffListProvider = Provider<List<StaffMember>>((ref) {
  return ref.watch(staffProvider).maybeWhen(
    data: (list) => list,
    orElse: () => [],
  );
});

final staffTimetableProvider = FutureProvider.family<Map<String, List<PeriodSlot>>, String>((ref, staffId) async {
  return ref.watch(educationalDataServiceProvider).getStaffTimetable(staffId);
});
