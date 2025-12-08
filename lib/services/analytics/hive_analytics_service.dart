import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/user.dart';
import 'package:odtrack_academia/services/analytics/analytics_service.dart';
import 'package:odtrack_academia/core/storage/storage_manager.dart';

/// Concrete implementation of AnalyticsService using Hive storage
/// Provides data aggregation and analytics computation from local data
class HiveAnalyticsService implements AnalyticsService {
  static const String _odRequestsBox = 'od_requests_box';
  static const String _usersBox = 'users_box';
  
  final EnhancedStorageManager _storageManager;
  
  // Cache duration for analytics data
  static const Duration _cacheExpiry = Duration(hours: 1);
  
  HiveAnalyticsService(this._storageManager);
  
  @override
  Future<void> initialize() async {
    await _storageManager.initialize();
    await _ensureBoxesOpen();
  }
  
  /// Ensure all required Hive boxes are open
  Future<void> _ensureBoxesOpen() async {
    if (!Hive.isBoxOpen(_odRequestsBox)) {
      await Hive.openBox<ODRequest>(_odRequestsBox);
    }
    if (!Hive.isBoxOpen(_usersBox)) {
      await Hive.openBox<User>(_usersBox);
    }
  }
  
  @override
  Future<AnalyticsData> getODRequestAnalytics(DateRange dateRange) async {
    final cacheKey = 'od_analytics_${dateRange.startDate.millisecondsSinceEpoch}_${dateRange.endDate.millisecondsSinceEpoch}';
    
    // Check cache first
    final cachedData = await _storageManager.getCachedData(cacheKey);
    if (cachedData != null) {
      return AnalyticsData.fromJson(cachedData);
    }
    
    await _ensureBoxesOpen();
    final odRequestsBox = Hive.box<ODRequest>(_odRequestsBox);
    
    // Filter requests by date range
    final requests = odRequestsBox.values
        .where((request) => 
            request.createdAt.isAfter(dateRange.startDate) &&
            request.createdAt.isBefore(dateRange.endDate.add(const Duration(days: 1))))
        .toList();
    
    // Calculate basic statistics
    final totalRequests = requests.length;
    final approvedRequests = requests.where((r) => r.isApproved).length;
    final rejectedRequests = requests.where((r) => r.isRejected).length;
    final pendingRequests = requests.where((r) => r.isPending).length;
    final approvalRate = totalRequests > 0 ? (approvedRequests / totalRequests) * 100 : 0.0;
    
    // Aggregate requests by month
    final requestsByMonth = <String, int>{};
    for (final request in requests) {
      final monthKey = '${request.createdAt.year}-${request.createdAt.month.toString().padLeft(2, '0')}';
      requestsByMonth[monthKey] = (requestsByMonth[monthKey] ?? 0) + 1;
    }
    
    // Aggregate requests by department (using student department from user data)
    final requestsByDepartment = await _aggregateByDepartment(requests);
    
    // Calculate top rejection reasons
    final topRejectionReasons = _calculateTopRejectionReasons(requests);
    
    // Identify patterns
    final patterns = await _identifyRequestPatterns(requests);
    
    final analyticsData = AnalyticsData(
      totalRequests: totalRequests,
      approvedRequests: approvedRequests,
      rejectedRequests: rejectedRequests,
      pendingRequests: pendingRequests,
      approvalRate: approvalRate,
      requestsByMonth: requestsByMonth,
      requestsByDepartment: requestsByDepartment,
      topRejectionReasons: topRejectionReasons,
      patterns: patterns,
    );
    
    // Cache the result
    await _storageManager.cacheData(cacheKey, analyticsData.toJson(), ttl: _cacheExpiry);
    
    return analyticsData;
  }
  
  @override
  Future<DepartmentAnalytics> getDepartmentAnalytics(String department) async {
    final cacheKey = 'dept_analytics_$department';
    
    // Check cache first
    final cachedData = await _storageManager.getCachedData(cacheKey);
    if (cachedData != null) {
      return DepartmentAnalytics.fromJson(cachedData);
    }
    
    await _ensureBoxesOpen();
    final odRequestsBox = Hive.box<ODRequest>(_odRequestsBox);
    final usersBox = Hive.box<User>(_usersBox);
    
    // Get students from the department
    final departmentStudents = usersBox.values
        .where((user) => user.department == department && user.role == 'student')
        .map((user) => user.id)
        .toSet();
    
    // Filter requests by department students
    final departmentRequests = odRequestsBox.values
        .where((request) => departmentStudents.contains(request.studentId))
        .toList();
    
    final totalRequests = departmentRequests.length;
    final approvedRequests = departmentRequests.where((r) => r.isApproved).length;
    final approvalRate = totalRequests > 0 ? (approvedRequests / totalRequests) * 100 : 0.0;
    
    // Aggregate by status
    final requestsByStatus = <String, int>{
      'approved': approvedRequests,
      'rejected': departmentRequests.where((r) => r.isRejected).length,
      'pending': departmentRequests.where((r) => r.isPending).length,
    };
    
    // Find top students by request count
    final studentRequestCounts = <String, int>{};
    for (final request in departmentRequests) {
      studentRequestCounts[request.studentId] = 
          (studentRequestCounts[request.studentId] ?? 0) + 1;
    }
    
    final topStudents = (studentRequestCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((entry) => entry.key)
        .toList();
    
    final departmentAnalytics = DepartmentAnalytics(
      departmentName: department,
      totalRequests: totalRequests,
      approvalRate: approvalRate,
      requestsByStatus: requestsByStatus,
      topStudents: topStudents,
    );
    
    // Cache the result
    await _storageManager.cacheData(cacheKey, departmentAnalytics.toJson(), ttl: _cacheExpiry);
    
    return departmentAnalytics;
  }
  
  @override
  Future<StudentAnalytics> getStudentAnalytics(String studentId) async {
    final cacheKey = 'student_analytics_$studentId';
    
    // Check cache first
    final cachedData = await _storageManager.getCachedData(cacheKey);
    if (cachedData != null) {
      return StudentAnalytics.fromJson(cachedData);
    }
    
    await _ensureBoxesOpen();
    final odRequestsBox = Hive.box<ODRequest>(_odRequestsBox);
    final usersBox = Hive.box<User>(_usersBox);
    
    final student = usersBox.get(studentId);
    final studentName = student?.name ?? 'Unknown Student';
    
    // Filter requests by student
    final studentRequests = odRequestsBox.values
        .where((request) => request.studentId == studentId)
        .toList();
    
    final totalRequests = studentRequests.length;
    final approvedRequests = studentRequests.where((r) => r.isApproved).length;
    final rejectedRequests = studentRequests.where((r) => r.isRejected).length;
    final approvalRate = totalRequests > 0 ? (approvedRequests / totalRequests) * 100 : 0.0;
    
    // Find frequent reasons
    final reasonCounts = <String, int>{};
    for (final request in studentRequests) {
      reasonCounts[request.reason] = (reasonCounts[request.reason] ?? 0) + 1;
    }
    
    final frequentReasons = (reasonCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
        .take(3)
        .map((entry) => entry.key)
        .toList();
    
    final studentAnalytics = StudentAnalytics(
      studentId: studentId,
      studentName: studentName,
      totalRequests: totalRequests,
      approvedRequests: approvedRequests,
      rejectedRequests: rejectedRequests,
      approvalRate: approvalRate,
      frequentReasons: frequentReasons,
    );
    
    // Cache the result
    await _storageManager.cacheData(cacheKey, studentAnalytics.toJson(), ttl: _cacheExpiry);
    
    return studentAnalytics;
  }  
 
 @override
  Future<StaffAnalytics> getStaffAnalytics(String staffId) async {
    final cacheKey = 'staff_analytics_$staffId';
    
    // Check cache first
    final cachedData = await _storageManager.getCachedData(cacheKey);
    if (cachedData != null) {
      return StaffAnalytics.fromJson(cachedData);
    }
    
    await _ensureBoxesOpen();
    final odRequestsBox = Hive.box<ODRequest>(_odRequestsBox);
    final usersBox = Hive.box<User>(_usersBox);
    
    final staff = usersBox.get(staffId);
    final staffName = staff?.name ?? 'Unknown Staff';
    
    // Filter requests processed by staff
    final staffRequests = odRequestsBox.values
        .where((request) => request.approvedBy == staffId || request.staffId == staffId)
        .toList();
    
    final requestsProcessed = staffRequests.length;
    final requestsApproved = staffRequests.where((r) => r.isApproved).length;
    final requestsRejected = staffRequests.where((r) => r.isRejected).length;
    
    // Calculate average processing time
    final processedRequests = staffRequests
        .where((r) => r.approvedAt != null)
        .toList();
    
    double averageProcessingTime = 0.0;
    if (processedRequests.isNotEmpty) {
      final totalProcessingTime = processedRequests
          .map((r) => r.approvedAt!.difference(r.createdAt).inHours)
          .reduce((a, b) => a + b);
      averageProcessingTime = totalProcessingTime / processedRequests.length;
    }
    
    // Find common rejection reasons
    final rejectionReasons = staffRequests
        .where((r) => r.isRejected && r.rejectionReason != null)
        .map((r) => r.rejectionReason!)
        .toList();
    
    final reasonCounts = <String, int>{};
    for (final reason in rejectionReasons) {
      reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
    }
    
    final commonRejectionReasons = (reasonCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
        .take(3)
        .map((entry) => entry.key)
        .toList();
    
    final staffAnalytics = StaffAnalytics(
      staffId: staffId,
      staffName: staffName,
      requestsProcessed: requestsProcessed,
      requestsApproved: requestsApproved,
      requestsRejected: requestsRejected,
      averageProcessingTime: averageProcessingTime,
      commonRejectionReasons: commonRejectionReasons,
    );
    
    // Cache the result
    await _storageManager.cacheData(cacheKey, staffAnalytics.toJson(), ttl: _cacheExpiry);
    
    return staffAnalytics;
  }
  
  @override
  Future<List<TrendData>> getTrendAnalysis(AnalyticsType type) async {
    final cacheKey = 'trend_analysis_${type.name}';
    
    // Check cache first
    final cachedData = await _storageManager.getCachedData(cacheKey);
    if (cachedData != null) {
      final List<dynamic> trendList = cachedData['trends'] as List<dynamic>;
      return trendList.map((json) => TrendData.fromJson(json as Map<String, dynamic>)).toList();
    }
    
    await _ensureBoxesOpen();
    final odRequestsBox = Hive.box<ODRequest>(_odRequestsBox);
    
    final requests = odRequestsBox.values.toList();
    final trends = <TrendData>[];
    
    switch (type) {
      case AnalyticsType.requests:
        trends.addAll(await _calculateRequestTrends(requests));
        break;
      case AnalyticsType.approvals:
        trends.addAll(await _calculateApprovalTrends(requests));
        break;
      case AnalyticsType.departments:
        trends.addAll(await _calculateDepartmentTrends(requests));
        break;
      case AnalyticsType.students:
        trends.addAll(await _calculateStudentTrends(requests));
        break;
    }
    
    // Cache the result
    final cacheData = {
      'trends': trends.map((t) => t.toJson()).toList(),
    };
    await _storageManager.cacheData(cacheKey, cacheData, ttl: _cacheExpiry);
    
    return trends;
  }
  
  @override
  Future<ExportData> prepareAnalyticsForExport(AnalyticsFilter filter) async {
    final dateRange = filter.dateRange ?? DateRange(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
    
    final analyticsData = await getODRequestAnalytics(dateRange);
    final chartData = await getChartData(ChartType.bar, filter);
    
    return ExportData(
      title: 'OD Request Analytics Report',
      data: analyticsData.toJson(),
      chartData: chartData,
      generatedAt: DateTime.now(),
    );
  }
  
  @override
  Future<List<ChartData>> getChartData(ChartType type, AnalyticsFilter filter) async {
    await _ensureBoxesOpen();
    final odRequestsBox = Hive.box<ODRequest>(_odRequestsBox);
    
    var requests = odRequestsBox.values.toList();
    
    // Apply filters
    if (filter.dateRange != null) {
      requests = requests.where((r) => 
          r.createdAt.isAfter(filter.dateRange!.startDate) &&
          r.createdAt.isBefore(filter.dateRange!.endDate.add(const Duration(days: 1)))).toList();
    }
    
    if (filter.department != null) {
      final usersBox = Hive.box<User>(_usersBox);
      final departmentStudents = usersBox.values
          .where((user) => user.department == filter.department && user.role == 'student')
          .map((user) => user.id)
          .toSet();
      requests = requests.where((r) => departmentStudents.contains(r.studentId)).toList();
    }
    
    if (filter.statuses != null && filter.statuses!.isNotEmpty) {
      requests = requests.where((r) => filter.statuses!.contains(r.status)).toList();
    }
    
    if (filter.studentId != null) {
      requests = requests.where((r) => r.studentId == filter.studentId).toList();
    }
    
    switch (type) {
      case ChartType.bar:
        return _generateBarChartData(requests);
      case ChartType.line:
        return _generateLineChartData(requests);
      case ChartType.pie:
        return _generatePieChartData(requests);
      case ChartType.area:
        return _generateAreaChartData(requests);
    }
  }
  
  @override
  Future<double> getApprovalRate(AnalyticsFilter filter) async {
    await _ensureBoxesOpen();
    final odRequestsBox = Hive.box<ODRequest>(_odRequestsBox);
    
    var requests = odRequestsBox.values.toList();
    
    // Apply filters
    if (filter.dateRange != null) {
      requests = requests.where((r) => 
          r.createdAt.isAfter(filter.dateRange!.startDate) &&
          r.createdAt.isBefore(filter.dateRange!.endDate.add(const Duration(days: 1)))).toList();
    }
    
    if (filter.department != null) {
      final usersBox = Hive.box<User>(_usersBox);
      final departmentStudents = usersBox.values
          .where((user) => user.department == filter.department && user.role == 'student')
          .map((user) => user.id)
          .toSet();
      requests = requests.where((r) => departmentStudents.contains(r.studentId)).toList();
    }
    
    final totalRequests = requests.length;
    if (totalRequests == 0) return 0.0;
    
    final approvedRequests = requests.where((r) => r.isApproved).length;
    return (approvedRequests / totalRequests) * 100;
  }
  
  @override
  Future<Map<String, int>> getRejectionReasonsStats(AnalyticsFilter filter) async {
    await _ensureBoxesOpen();
    final odRequestsBox = Hive.box<ODRequest>(_odRequestsBox);
    
    var requests = odRequestsBox.values
        .where((r) => r.isRejected && r.rejectionReason != null)
        .toList();
    
    // Apply filters
    if (filter.dateRange != null) {
      requests = requests.where((r) => 
          r.createdAt.isAfter(filter.dateRange!.startDate) &&
          r.createdAt.isBefore(filter.dateRange!.endDate.add(const Duration(days: 1)))).toList();
    }
    
    if (filter.department != null) {
      final usersBox = Hive.box<User>(_usersBox);
      final departmentStudents = usersBox.values
          .where((user) => user.department == filter.department && user.role == 'student')
          .map((user) => user.id)
          .toSet();
      requests = requests.where((r) => departmentStudents.contains(r.studentId)).toList();
    }
    
    final reasonCounts = <String, int>{};
    for (final request in requests) {
      final reason = request.rejectionReason!;
      reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
    }
    
    return reasonCounts;
  }
  
  @override
  Future<void> refreshAnalyticsCache() async {
    // Clear all analytics-related cache entries
    // Note: This is a simplified implementation
    // In a real scenario, we would need to iterate through cache keys
    // and remove those matching our patterns
  }
  
  // PRIVATE HELPER METHODS
  
  /// Aggregate requests by department using user data
  Future<Map<String, int>> _aggregateByDepartment(List<ODRequest> requests) async {
    final usersBox = Hive.box<User>(_usersBox);
    final departmentCounts = <String, int>{};
    
    for (final request in requests) {
      final user = usersBox.get(request.studentId);
      final department = user?.department ?? 'Unknown';
      departmentCounts[department] = (departmentCounts[department] ?? 0) + 1;
    }
    
    return departmentCounts;
  }
  
  /// Calculate top rejection reasons with statistics
  List<RejectionReason> _calculateTopRejectionReasons(List<ODRequest> requests) {
    final rejectedRequests = requests.where((r) => r.isRejected && r.rejectionReason != null).toList();
    final totalRejected = rejectedRequests.length;
    
    if (totalRejected == 0) return [];
    
    final reasonCounts = <String, int>{};
    for (final request in rejectedRequests) {
      final reason = request.rejectionReason!;
      reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
    }
    
    return (reasonCounts.entries
        .map((entry) => RejectionReason(
              reason: entry.key,
              count: entry.value,
              percentage: (entry.value / totalRejected) * 100,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count)))
      .take(5)
      .toList();
  }
  
  /// Identify request patterns using pattern recognition algorithms
  Future<List<RequestPattern>> _identifyRequestPatterns(List<ODRequest> requests) async {
    final patterns = <RequestPattern>[];
    
    // Pattern 1: Peak request days
    final dayOfWeekCounts = <int, int>{};
    for (final request in requests) {
      final dayOfWeek = request.createdAt.weekday;
      dayOfWeekCounts[dayOfWeek] = (dayOfWeekCounts[dayOfWeek] ?? 0) + 1;
    }
    
    if (dayOfWeekCounts.isNotEmpty) {
      final maxDay = dayOfWeekCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      patterns.add(RequestPattern(
        pattern: 'peak_day',
        description: 'Most requests are submitted on ${dayNames[maxDay.key - 1]}',
        confidence: (maxDay.value / requests.length) * 100,
      ));
    }
    
    // Pattern 2: Seasonal trends
    final monthCounts = <int, int>{};
    for (final request in requests) {
      final month = request.createdAt.month;
      monthCounts[month] = (monthCounts[month] ?? 0) + 1;
    }
    
    if (monthCounts.isNotEmpty) {
      final maxMonth = monthCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      patterns.add(RequestPattern(
        pattern: 'seasonal_trend',
        description: 'Peak request month is ${monthNames[maxMonth.key - 1]}',
        confidence: (maxMonth.value / requests.length) * 100,
      ));
    }
    
    // Pattern 3: Approval rate by reason
    final reasonApprovalRates = <String, double>{};
    final reasonCounts = <String, int>{};
    final reasonApprovals = <String, int>{};
    
    for (final request in requests) {
      reasonCounts[request.reason] = (reasonCounts[request.reason] ?? 0) + 1;
      if (request.isApproved) {
        reasonApprovals[request.reason] = (reasonApprovals[request.reason] ?? 0) + 1;
      }
    }
    
    for (final reason in reasonCounts.keys) {
      final approvals = reasonApprovals[reason] ?? 0;
      final total = reasonCounts[reason]!;
      reasonApprovalRates[reason] = (approvals / total) * 100;
    }
    
    if (reasonApprovalRates.isNotEmpty) {
      final bestReason = reasonApprovalRates.entries.reduce((a, b) => a.value > b.value ? a : b);
      patterns.add(RequestPattern(
        pattern: 'best_reason',
        description: 'Highest approval rate for reason: ${bestReason.key}',
        confidence: bestReason.value,
      ));
    }
    
    return patterns;
  }  

  // TREND ANALYSIS METHODS
  
  /// Calculate request volume trends over time
  Future<List<TrendData>> _calculateRequestTrends(List<ODRequest> requests) async {
    final trends = <TrendData>[];
    
    // Group requests by week for the last 12 weeks
    final now = DateTime.now();
    final weeklyData = <DateTime, int>{};
    
    for (int i = 11; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: (i * 7) + now.weekday - 1));
      final weekStartNormalized = DateTime(weekStart.year, weekStart.month, weekStart.day);
      weeklyData[weekStartNormalized] = 0;
    }
    
    for (final request in requests) {
      final requestWeekStart = request.createdAt.subtract(
        Duration(days: request.createdAt.weekday - 1)
      );
      final weekStartNormalized = DateTime(
        requestWeekStart.year, 
        requestWeekStart.month, 
        requestWeekStart.day
      );
      
      if (weeklyData.containsKey(weekStartNormalized)) {
        weeklyData[weekStartNormalized] = weeklyData[weekStartNormalized]! + 1;
      }
    }
    
    final dataPoints = weeklyData.entries
        .map((entry) => DataPoint(timestamp: entry.key, value: entry.value.toDouble()))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Calculate trend direction
    final trendDirection = _calculateTrendDirection(dataPoints);
    final changePercentage = _calculateChangePercentage(dataPoints);
    
    trends.add(TrendData(
      label: 'Weekly Request Volume',
      dataPoints: dataPoints,
      direction: trendDirection,
      changePercentage: changePercentage,
    ));
    
    return trends;
  }
  
  /// Calculate approval rate trends over time
  Future<List<TrendData>> _calculateApprovalTrends(List<ODRequest> requests) async {
    final trends = <TrendData>[];
    
    // Group by month for the last 6 months
    final now = DateTime.now();
    final monthlyApprovalRates = <DateTime, double>{};
    
    for (int i = 5; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0);
      
      final monthRequests = requests.where((r) => 
          r.createdAt.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          r.createdAt.isBefore(monthEnd.add(const Duration(days: 1)))).toList();
      
      if (monthRequests.isNotEmpty) {
        final approvedCount = monthRequests.where((r) => r.isApproved).length;
        final approvalRate = (approvedCount / monthRequests.length) * 100;
        monthlyApprovalRates[monthStart] = approvalRate;
      } else {
        monthlyApprovalRates[monthStart] = 0.0;
      }
    }
    
    final dataPoints = monthlyApprovalRates.entries
        .map((entry) => DataPoint(timestamp: entry.key, value: entry.value))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final trendDirection = _calculateTrendDirection(dataPoints);
    final changePercentage = _calculateChangePercentage(dataPoints);
    
    trends.add(TrendData(
      label: 'Monthly Approval Rate',
      dataPoints: dataPoints,
      direction: trendDirection,
      changePercentage: changePercentage,
    ));
    
    return trends;
  }
  
  /// Calculate department-wise trends
  Future<List<TrendData>> _calculateDepartmentTrends(List<ODRequest> requests) async {
    final usersBox = Hive.box<User>(_usersBox);
    final trends = <TrendData>[];
    
    // Get all departments
    final departments = usersBox.values
        .where((user) => user.role == 'student')
        .map((user) => user.department)
        .toSet()
        .where((dept) => dept != null)
        .cast<String>()
        .toList();
    
    for (final department in departments) {
      final departmentStudents = usersBox.values
          .where((user) => user.department == department && user.role == 'student')
          .map((user) => user.id)
          .toSet();
      
      final departmentRequests = requests
          .where((r) => departmentStudents.contains(r.studentId))
          .toList();
      
      // Calculate monthly trends for this department
      final now = DateTime.now();
      final monthlyData = <DateTime, double>{};
      
      for (int i = 5; i >= 0; i--) {
        final monthStart = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 0);
        
        final monthRequests = departmentRequests.where((r) => 
            r.createdAt.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            r.createdAt.isBefore(monthEnd.add(const Duration(days: 1)))).length;
        
        monthlyData[monthStart] = monthRequests.toDouble();
      }
      
      final dataPoints = monthlyData.entries
          .map((entry) => DataPoint(timestamp: entry.key, value: entry.value))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      if (dataPoints.isNotEmpty) {
        final trendDirection = _calculateTrendDirection(dataPoints);
        final changePercentage = _calculateChangePercentage(dataPoints);
        
        trends.add(TrendData(
          label: '$department Department Requests',
          dataPoints: dataPoints,
          direction: trendDirection,
          changePercentage: changePercentage,
        ));
      }
    }
    
    return trends;
  }
  
  /// Calculate student activity trends
  Future<List<TrendData>> _calculateStudentTrends(List<ODRequest> requests) async {
    final trends = <TrendData>[];
    
    // Calculate average requests per student over time
    final now = DateTime.now();
    final monthlyStudentActivity = <DateTime, double>{};
    
    for (int i = 5; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0);
      
      final monthRequests = requests.where((r) => 
          r.createdAt.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          r.createdAt.isBefore(monthEnd.add(const Duration(days: 1)))).toList();
      
      if (monthRequests.isNotEmpty) {
        final uniqueStudents = monthRequests.map((r) => r.studentId).toSet().length;
        final avgRequestsPerStudent = monthRequests.length / uniqueStudents;
        monthlyStudentActivity[monthStart] = avgRequestsPerStudent;
      } else {
        monthlyStudentActivity[monthStart] = 0.0;
      }
    }
    
    final dataPoints = monthlyStudentActivity.entries
        .map((entry) => DataPoint(timestamp: entry.key, value: entry.value))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final trendDirection = _calculateTrendDirection(dataPoints);
    final changePercentage = _calculateChangePercentage(dataPoints);
    
    trends.add(TrendData(
      label: 'Average Requests per Student',
      dataPoints: dataPoints,
      direction: trendDirection,
      changePercentage: changePercentage,
    ));
    
    return trends;
  }
  
  // CHART DATA GENERATION METHODS
  
  /// Generate bar chart data
  List<ChartData> _generateBarChartData(List<ODRequest> requests) {
    final statusCounts = <String, int>{
      'Approved': requests.where((r) => r.isApproved).length,
      'Rejected': requests.where((r) => r.isRejected).length,
      'Pending': requests.where((r) => r.isPending).length,
    };
    
    return statusCounts.entries
        .map((entry) => ChartData(
              label: entry.key,
              value: entry.value.toDouble(),
            ))
        .toList();
  }
  
  /// Generate line chart data
  List<ChartData> _generateLineChartData(List<ODRequest> requests) {
    final now = DateTime.now();
    final dailyData = <DateTime, int>{};
    
    // Last 30 days
    for (int i = 29; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      dailyData[day] = 0;
    }
    
    for (final request in requests) {
      final requestDay = DateTime(
        request.createdAt.year,
        request.createdAt.month,
        request.createdAt.day,
      );
      
      if (dailyData.containsKey(requestDay)) {
        dailyData[requestDay] = dailyData[requestDay]! + 1;
      }
    }
    
    return dailyData.entries
        .map((entry) => ChartData(
              label: '${entry.key.day}/${entry.key.month}',
              value: entry.value.toDouble(),
              timestamp: entry.key,
            ))
        .toList()
      ..sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
  }
  
  /// Generate pie chart data
  List<ChartData> _generatePieChartData(List<ODRequest> requests) {
    final reasonCounts = <String, int>{};
    
    for (final request in requests) {
      reasonCounts[request.reason] = (reasonCounts[request.reason] ?? 0) + 1;
    }
    
    return reasonCounts.entries
        .map((entry) => ChartData(
              label: entry.key,
              value: entry.value.toDouble(),
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
  
  /// Generate area chart data
  List<ChartData> _generateAreaChartData(List<ODRequest> requests) {
    // Similar to line chart but with cumulative data
    final now = DateTime.now();
    final dailyData = <DateTime, int>{};
    
    // Last 30 days
    for (int i = 29; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      dailyData[day] = 0;
    }
    
    for (final request in requests) {
      final requestDay = DateTime(
        request.createdAt.year,
        request.createdAt.month,
        request.createdAt.day,
      );
      
      if (dailyData.containsKey(requestDay)) {
        dailyData[requestDay] = dailyData[requestDay]! + 1;
      }
    }
    
    // Convert to cumulative data
    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    int cumulative = 0;
    return sortedEntries.map((entry) {
      cumulative += entry.value;
      return ChartData(
        label: '${entry.key.day}/${entry.key.month}',
        value: cumulative.toDouble(),
        timestamp: entry.key,
      );
    }).toList();
  }
  
  // UTILITY METHODS
  
  /// Calculate trend direction from data points
  TrendDirection _calculateTrendDirection(List<DataPoint> dataPoints) {
    if (dataPoints.length < 2) return TrendDirection.stable;
    
    final firstHalf = dataPoints.take(dataPoints.length ~/ 2).toList();
    final secondHalf = dataPoints.skip(dataPoints.length ~/ 2).toList();
    
    final firstAvg = firstHalf.isEmpty ? 0.0 : 
        firstHalf.map((p) => p.value).reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.isEmpty ? 0.0 : 
        secondHalf.map((p) => p.value).reduce((a, b) => a + b) / secondHalf.length;
    
    const threshold = 0.05; // 5% threshold for stability
    final changeRatio = firstAvg == 0 ? 0 : (secondAvg - firstAvg) / firstAvg;
    
    if (changeRatio > threshold) return TrendDirection.up;
    if (changeRatio < -threshold) return TrendDirection.down;
    return TrendDirection.stable;
  }
  
  /// Calculate percentage change from first to last data point
  double _calculateChangePercentage(List<DataPoint> dataPoints) {
    if (dataPoints.length < 2) return 0.0;
    
    final first = dataPoints.first.value;
    final last = dataPoints.last.value;
    
    if (first == 0) return last > 0 ? 100.0 : 0.0;
    
    return ((last - first) / first) * 100;
  }
}