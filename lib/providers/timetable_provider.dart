import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/models/timetable.dart';
import 'package:odtrack_academia/services/api/educational_data_service.dart';

final timetableProvider = FutureProvider.family<Timetable, ({String section, String year})>((ref, arg) async {
  final service = ref.watch(educationalDataServiceProvider);
  
  // Convert "3rd Year" to 3
  final yearInt = int.tryParse(arg.year.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
  
  return await service.getTimetable(
    section: arg.section,
    year: yearInt,
  );
});

// Helper for human-readable year to int
int yearStringToInt(String yearStr) {
  return int.tryParse(yearStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
}
