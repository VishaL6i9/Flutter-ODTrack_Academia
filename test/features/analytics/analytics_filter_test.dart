import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/models/analytics_models.dart';

void main() {
  group('AnalyticsFilter', () {
    test('should create filter with all null values by default', () {
      const filter = AnalyticsFilter();

      expect(filter.dateRange, isNull);
      expect(filter.department, isNull);
      expect(filter.year, isNull);
      expect(filter.statuses, isNull);
      expect(filter.staffId, isNull);
      expect(filter.studentId, isNull);
    });

    test('should create filter with specified values', () {
      final dateRange = DateRange(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      final filter = AnalyticsFilter(
        dateRange: dateRange,
        department: 'Computer Science',
        year: '2024-25',
        statuses: ['Approved', 'Pending'],
        staffId: 'staff123',
        studentId: 'student456',
      );

      expect(filter.dateRange, equals(dateRange));
      expect(filter.department, equals('Computer Science'));
      expect(filter.year, equals('2024-25'));
      expect(filter.statuses, equals(['Approved', 'Pending']));
      expect(filter.staffId, equals('staff123'));
      expect(filter.studentId, equals('student456'));
    });

    test('should serialize to JSON correctly', () {
      final dateRange = DateRange(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      final filter = AnalyticsFilter(
        dateRange: dateRange,
        department: 'Computer Science',
        year: '2024-25',
        statuses: ['Approved', 'Pending'],
      );

      final json = filter.toJson();

      expect(json['dateRange'], isNotNull);
      expect(json['department'], equals('Computer Science'));
      expect(json['year'], equals('2024-25'));
      expect(json['statuses'], equals(['Approved', 'Pending']));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'dateRange': {
          'startDate': '2024-01-01T00:00:00.000',
          'endDate': '2024-12-31T00:00:00.000',
        },
        'department': 'Computer Science',
        'year': '2024-25',
        'statuses': ['Approved', 'Pending'],
        'staffId': null,
        'studentId': null,
      };

      final filter = AnalyticsFilter.fromJson(json);

      expect(filter.department, equals('Computer Science'));
      expect(filter.year, equals('2024-25'));
      expect(filter.statuses, equals(['Approved', 'Pending']));
      expect(filter.staffId, isNull);
      expect(filter.studentId, isNull);
    });
  });

  group('DateRange', () {
    test('should create date range with start and end dates', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 12, 31);
      final dateRange = DateRange(startDate: startDate, endDate: endDate);

      expect(dateRange.startDate, equals(startDate));
      expect(dateRange.endDate, equals(endDate));
    });

    test('should serialize to JSON correctly', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 12, 31);
      final dateRange = DateRange(startDate: startDate, endDate: endDate);

      final json = dateRange.toJson();

      expect(json['startDate'], equals('2024-01-01T00:00:00.000'));
      expect(json['endDate'], equals('2024-12-31T00:00:00.000'));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'startDate': '2024-01-01T00:00:00.000',
        'endDate': '2024-12-31T00:00:00.000',
      };

      final dateRange = DateRange.fromJson(json);

      expect(dateRange.startDate, equals(DateTime(2024, 1, 1)));
      expect(dateRange.endDate, equals(DateTime(2024, 12, 31)));
    });
  });

  group('Filter Logic Tests', () {
    late List<MockODRequest> mockRequests;

    setUp(() {
      mockRequests = [
        MockODRequest(
          id: '1',
          department: 'Computer Science',
          status: 'Approved',
          createdAt: DateTime(2024, 1, 15), // Within range
          year: '2024-25',
        ),
        MockODRequest(
          id: '2',
          department: 'Electronics',
          status: 'Pending',
          createdAt: DateTime(2024, 2, 10), // Within range
          year: '2024-25',
        ),
        MockODRequest(
          id: '3',
          department: 'Computer Science',
          status: 'Rejected',
          createdAt: DateTime(2024, 3, 5), // Outside range
          year: '2023-24',
        ),
        MockODRequest(
          id: '4',
          department: 'Mechanical',
          status: 'Approved',
          createdAt: DateTime(2024, 1, 5), // Outside range (before start)
          year: '2024-25',
        ),
      ];
    });

    test('should filter by date range correctly', () {
      final filter = AnalyticsFilter(
        dateRange: DateRange(
          startDate: DateTime(2024, 1, 10),
          endDate: DateTime(2024, 2, 15),
        ),
      );

      final filtered = _applyFilter(mockRequests, filter);

      expect(filtered, hasLength(2));
      expect(filtered.map((r) => r.id), containsAll(['1', '2']));
    });

    test('should filter by department correctly', () {
      const filter = AnalyticsFilter(department: 'Computer Science');

      final filtered = _applyFilter(mockRequests, filter);

      expect(filtered, hasLength(2));
      expect(filtered.map((r) => r.id), containsAll(['1', '3']));
    });

    test('should filter by status correctly', () {
      const filter = AnalyticsFilter(statuses: ['Approved']);

      final filtered = _applyFilter(mockRequests, filter);

      expect(filtered, hasLength(2));
      expect(filtered.map((r) => r.id), containsAll(['1', '4']));
    });

    test('should filter by year correctly', () {
      const filter = AnalyticsFilter(year: '2024-25');

      final filtered = _applyFilter(mockRequests, filter);

      expect(filtered, hasLength(3));
      expect(filtered.map((r) => r.id), containsAll(['1', '2', '4']));
    });

    test('should apply multiple filters correctly', () {
      final filter = AnalyticsFilter(
        dateRange: DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 2, 28),
        ),
        department: 'Computer Science',
        statuses: ['Approved'],
        year: '2024-25',
      );

      final filtered = _applyFilter(mockRequests, filter);

      expect(filtered, hasLength(1));
      expect(filtered.first.id, equals('1'));
    });

    test('should return all requests when no filters are applied', () {
      const filter = AnalyticsFilter();

      final filtered = _applyFilter(mockRequests, filter);

      expect(filtered, hasLength(4));
    });

    test('should return empty list when no requests match filters', () {
      const filter = AnalyticsFilter(
        department: 'Non-existent Department',
      );

      final filtered = _applyFilter(mockRequests, filter);

      expect(filtered, isEmpty);
    });
  });
}

// Mock class for testing filter logic
class MockODRequest {
  final String id;
  final String department;
  final String status;
  final DateTime createdAt;
  final String year;

  MockODRequest({
    required this.id,
    required this.department,
    required this.status,
    required this.createdAt,
    required this.year,
  });
}

// Helper function to simulate filter application
List<MockODRequest> _applyFilter(List<MockODRequest> requests, AnalyticsFilter filter) {
  return requests.where((request) {
    // Date range filter
    if (filter.dateRange != null) {
      if (request.createdAt.isBefore(filter.dateRange!.startDate) ||
          request.createdAt.isAfter(filter.dateRange!.endDate)) {
        return false;
      }
    }

    // Department filter
    if (filter.department != null && request.department != filter.department) {
      return false;
    }

    // Status filter
    if (filter.statuses != null && !filter.statuses!.contains(request.status)) {
      return false;
    }

    // Year filter
    if (filter.year != null && request.year != filter.year) {
      return false;
    }

    return true;
  }).toList();
}