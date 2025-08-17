class AppConstants {
  // App Info
  static const String appName = 'ODTrack Academia™';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String userBox = 'user_box';
  static const String cacheBox = 'cache_box';
  static const String authTokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';
  static const String userDataKey = 'user_data';
  
  // API Configuration
  static const String baseUrl = 'https://api.odtrack.edu';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // File Upload Limits
  static const int maxFileSize = 2 * 1024 * 1024; // 2MB
  static const List<String> allowedFileTypes = ['pdf', 'jpg', 'jpeg', 'png'];
  
  // Cache Settings
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const Duration cacheExpiry = Duration(hours: 24);
  
  // User Roles
  static const String studentRole = 'student';
  static const String staffRole = 'staff';
  
  // Routes
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String newOdRoute = '/new-od';
  static const String timetableRoute = '/timetable';
  static const String staffDirectoryRoute = '/staff-directory';
  static const String staffInboxRoute = '/staff-inbox';
  static const String staffAnalyticsRoute = '/staff-analytics';
}
