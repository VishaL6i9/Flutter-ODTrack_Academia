import 'package:odtrack_academia/models/analytics_models.dart';

/// Filter classes for enhanced export functionality

class StudentReportFilter {
  final List<String>? statuses;
  final DateRange? dateRange;
  final String? reasonKeyword;

  const StudentReportFilter({
    this.statuses,
    this.dateRange,
    this.reasonKeyword,
  });
}

class StaffReportFilter {
  final DateRange? dateRange;
  final List<String>? departments;

  const StaffReportFilter({this.dateRange, this.departments});
}

class BulkReportFilter {
  final List<String>? statuses;
  final List<String>? departments;
  final DateRange? dateRange;

  const BulkReportFilter({this.statuses, this.departments, this.dateRange});
}
