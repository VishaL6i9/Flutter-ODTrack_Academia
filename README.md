# ODTrack Academia™ - Mobile Client

A comprehensive Flutter-based mobile application for On-Duty (OD) request management in academic institutions. Built with a focus on offline-first architecture, accessibility compliance, and enhanced user experience.

## Project Overview

ODTrack Academia™ is a production-ready mobile application that provides students and staff with a seamless interface to:
- **Submit & Track OD Requests**: Create, manage, and track OD requests with real-time status updates
- **Smart Staff Assignment**: Automatic staff member assignment based on timetable data
- **Dual Coordinator System**: Optional Class and Year Coordinator sections with confirmation workflow
- **Timetable Management**: View and manage class and personal timetables with advanced filtering
- **Staff Directory**: Browse faculty contacts with search and pre-filtering capabilities
- **Analytics & Reporting**: Interactive charts and professional PDF report generation
- **Calendar Integration**: Sync approved OD requests with device calendar
- **Staff Analytics**: Comprehensive workload tracking, teaching analytics, and efficiency metrics
- **Offline Support**: Full functionality without internet connection with automatic sync
- **Accessibility**: WCAG 2.1 compliant with screen reader support and keyboard navigation
- **Dark Mode**: Complete dark theme implementation across all screens
- **Push Notifications**: Real-time alerts for request status changes
- **Bulk Operations**: Efficient batch processing for staff actions

## Technology Stack

- **Framework**: Flutter 3.19+ with Dart 3
- **State Management**: Riverpod + Hive for local cache
- **Network**: Dio + Retrofit-Flutter for REST calls
- **Security**: flutter_secure_storage (AES-256) for JWT
- **Navigation**: GoRouter for declarative routing
- **Analytics & Charting**: fl_chart
- **Push Notifications**: firebase_messaging, flutter_local_notifications
- **Offline Storage**: hive_flutter (enhanced for sync queue & caching)
- **PDF Generation**: pdf, printing
- **Calendar Integration**: device_calendar
- **Accessibility**: Built-in accessibility services, keyboard navigation, screen reader support
- **File Operations**: file_picker, image_picker, share_plus, open_file

## Project Structure

```
lib/
├── core/                 # Core application files
│   ├── app.dart         # Main app widget
│   ├── constants/       # App constants & routes
│   ├── router/          # GoRouter navigation configuration
│   ├── theme/           # Material Design theming
│   ├── accessibility/   # Accessibility services and focus management
│   ├── navigation/      # Navigation services and breadcrumb system
│   └── storage/         # Enhanced storage configuration
├── features/            # Feature modules (Clean Architecture)
│   ├── analytics/      # Analytics and reporting
│   ├── auth/           # Authentication (login/logout)
│   ├── calendar_settings/ # Calendar integration settings
│   ├── dashboard/      # Main dashboard for students & staff
│   ├── debug/          # Debugging utilities
│   ├── export_demo/    # Demo for export functionality
│   ├── od_request/     # OD request management
│   ├── staff_directory/ # Staff directory & search
│   ├── staff_inbox/    # Staff OD request inbox
│   ├── staff_profile/  # Staff profile management
│   ├── staff_analytics/ # Staff analytics and workload management
│   ├── bulk_operations/ # Bulk operations for staff
│   ├── accessibility_demo/ # Accessibility demonstration screen
│   └── timetable/      # Timetable viewing
├── models/             # Data models
├── providers/          # Riverpod state management
├── services/           # API and other services
├── shared/             # Shared widgets
├── utils/              # Utility functions
└── main.dart           # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.19 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- Android SDK (for Android development)
- Xcode (for iOS development, macOS only)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd odtrack_academia
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code (for models and providers):
   ```bash
   flutter packages pub run build_runner build
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Build Instructions

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release
```

## Features

### 🎓 Student Features
- **Secure Authentication**: Login with Register Number + Date of Birth
- **Personalized Dashboard**: Quick stats on OD requests (pending, approved, rejected) with quick actions
- **OD Request Management**:
  - Create new OD requests with date/period selection
  - Automatic staff assignment based on timetable data
  - Optional Class and Year Coordinator sections with dual selection confirmation
  - 30-second undo buffer after submission for safety
  - Real-time status tracking with visual indicators
  - Request history with detailed status information
  - Toast notifications for staff information
- **Timetable Access**: View class timetables with color-coded subjects and advanced filtering
- **Staff Directory**: Browse faculty contacts with search functionality and department filtering
- **Smart Navigation**: Context-aware navigation to relevant staff profiles
- **Push Notifications**: Real-time alerts for OD request status changes
- **Calendar Integration**: Automatically sync approved OD requests with device calendar
- **Offline Support**: Full app functionality without internet connection with automatic sync when online

### 👨‍🏫 Staff Features
- **Secure Authentication**: Login with Email + Password
- **Staff Dashboard**: Quick stats and action buttons for efficient workflow
- **OD Request Inbox**:
  - Filter requests by status (All/Pending/Approved/Rejected)
  - Approve/reject with confirmation dialogs and reason tracking
  - Real-time status updates with visual feedback
  - Bulk operations for efficient batch processing
- **Timetable Management**:
  - Personal timetable with color-coded subjects
  - Browse any class timetable with advanced filtering
  - Search functionality across all timetables
- **Staff Directory**:
  - Browse all faculty with department filtering
  - Pre-filtering capabilities for contextual navigation
  - Direct access to colleague timetables
- **Profile Management**:
  - Edit personal information and contact details
  - Change password with validation
  - Quick access to help and support
- **Analytics Dashboard**:
  - Interactive charts for OD request trends and patterns
  - Request status distribution visualization
  - Monthly request volume tracking
  - Top rejection reasons analysis
  - Department-wise comparison
  - Generate and share professional PDF reports
- **Staff Analytics & Workload Management**:
  - Comprehensive workload tracking with weekly/monthly breakdown
  - Teaching analytics with subject-wise period allocation
  - Time allocation tracking by activity type
  - Efficiency metrics and performance tracking
  - Comparative analytics (semester-over-semester)
  - Department benchmarking and peer comparison
  - Proactive alerts for workload imbalances
  - Dark mode support for all analytics widgets
- **Calendar Integration**: Sync approved OD requests with device calendar
- **Push Notifications**: Real-time alerts for new OD requests and status updates
- **Bulk Operations**: 
  - Approve/reject multiple requests simultaneously
  - Export multiple requests to PDF
  - Progress tracking with real-time updates
  - Undo functionality for bulk operations
- **Offline Support**: Full functionality without internet connection with automatic sync

### 🔧 Technical Features
- **Offline-First Architecture**: 
  - Local data caching with Hive
  - Intelligent sync queue for offline operations
  - Conflict resolution for data synchronization
  - Background sync worker for automatic synchronization
- **Push Notifications**: FCM integration for cross-platform real-time alerts
- **Intelligent Caching**: 
  - Smart cache management with TTL strategies
  - Priority-based cleanup mechanism
  - Efficient memory management
- **Bulk Operations System**: 
  - Multi-select UI with checkboxes
  - Real-time progress tracking
  - Detailed error reporting
  - Undo functionality with time window
- **Staff Analytics & Workload Management**: 
  - Comprehensive tracking and visualization
  - Dark mode support across all components
  - Performance metrics and benchmarking
- **PDF Export System**: 
  - Professional report generation
  - Institutional branding
  - Multiple template types
  - Background processing for large exports
- **Calendar Integration**: 
  - Native device calendar integration
  - Complete event lifecycle management
  - Customizable sync settings
- **Accessibility (WCAG 2.1 Compliant)**:
  - Screen reader support with semantic labeling
  - Keyboard navigation throughout the app
  - High contrast mode compatibility
  - Text scaling support (1.0x to 2.0x)
  - Focus management and visual indicators
  - Accessible form components
- **Responsive Design**: Optimized for various screen sizes and orientations
- **Material Design 3**: Modern UI with comprehensive dark mode support
- **State Management**: Efficient state handling with Riverpod
- **Navigation**: Declarative routing with GoRouter, breadcrumbs, and context preservation
- **Performance Optimization**: 
  - Tree-shaking for smaller builds
  - Background processing for heavy operations
  - Skeleton loading screens for better perceived performance
  - Smooth animations and transitions
- **Enhanced User Experience**:
  - Real-time form validation with helpful error messages
  - Contextual error messages with suggested actions
  - Smooth page transitions
  - Micro-interactions for better feedback
  - Skeleton loading screens instead of blank states

## Development Milestones

### Completed ✅
- [x] **M1: Project Foundation** (Dec 2024)
  - Project setup with Flutter 3.19+
  - Riverpod state management configuration
  - Hive local storage setup
  - GoRouter navigation configuration
  - Material Design 3 theming with dark mode support

- [x] **M2: Authentication & Dashboard** (Jan 2025)
  - Dual authentication system (students & staff)
  - Role-based dashboards
  - JWT token management with secure storage
  - Session management and logout functionality

- [x] **M4: Staff Management System** (Jan 2025)
  - Staff directory with search and filtering
  - Staff profile management
  - Timetable system with color coding
  - Staff inbox for OD request management
  - Approval/rejection workflow with reason tracking

- [x] **M5: Enhanced Features** (Jan 2025)
  - **Analytics & Reporting**:
    - Interactive charts using fl_chart
    - Request status distribution visualization
    - Monthly request volume tracking
    - Top rejection reasons analysis
    - Department-wise comparison
    - PDF report generation with institutional branding
  
  - **Calendar Integration**:
    - Device calendar permission management
    - Automatic event creation for approved ODs
    - Event lifecycle management
    - Customizable sync settings
  
  - **Offline Support & Synchronization**:
    - Hive-based local caching
    - Sync queue for offline operations
    - Conflict resolution mechanism
    - Background sync worker with connectivity monitoring
    - Exponential backoff retry mechanism
  
  - **Push Notifications**:
    - FCM integration for cross-platform notifications
    - Local notifications for offline scenarios
    - Deep linking to relevant screens
    - Notification grouping and badge management
  
  - **Bulk Operations**:
    - Multi-select UI with checkboxes
    - Batch approval/rejection/export
    - Real-time progress tracking
    - Error handling and reporting
    - Undo functionality with time window
  
  - **Staff Analytics & Workload Management**:
    - Workload tracking with weekly/monthly breakdown
    - Teaching analytics with subject allocation
    - Time allocation tracking by activity type
    - Efficiency metrics and performance tracking
    - Comparative analytics (semester-over-semester)
    - Department benchmarking
    - Dark mode support for all components
  
  - **Enhanced User Experience**:
    - Skeleton loading screens
    - Smooth page transitions and animations
    - Real-time form validation
    - Contextual error messages
    - Improved navigation with breadcrumbs
  
  - **Accessibility (WCAG 2.1 Compliant)**:
    - Screen reader support with semantic labeling
    - Keyboard navigation throughout the app
    - High contrast mode compatibility
    - Text scaling support (1.0x to 2.0x)
    - Focus management and visual indicators
    - Accessible form components
  
  - **Dark Mode**:
    - Complete dark theme implementation
    - Theme-aware colors across all screens
    - Proper contrast ratios for accessibility
    - Consistent styling across components

- [x] **Permissions System** (Jan 2025)
  - Automatic permission checking on app launch
  - SDK 24-36 compatibility for storage permissions
  - Permissions screen with request UI
  - Router integration for permission flow
  - Debug logging for permission checking

### In Progress 🚧
- [ ] **M3: Complete OD Request Flow**
  - Backend API integration
  - Real-time status updates
  - File attachment support
  - Email notifications
  - Digital signature integration

### Planned 📋
- [ ] **M6: Security & Performance**
  - Security audit & penetration testing
  - JWT token refresh mechanism
  - Data encryption at rest
  - Performance optimization
  - Memory leak detection
  - Accessibility compliance verification (WCAG 2.1)

- [ ] **M7: Advanced Features**
  - Multi-language support (i18n)
  - Biometric authentication
  - QR code scanning for quick actions

- [ ] **M8: Production Deployment**
  - Play Store & App Store submissions
  - CI/CD pipeline setup
  - Monitoring & crash reporting
  - User feedback system
  - Beta testing program

## Current Implementation Status

### ✅ Fully Implemented
- **Authentication System**:
  - Dual authentication for students (Register Number + DOB) and staff (Email + Password)
  - JWT token management with secure storage (AES-256 encryption)
  - Session management and logout functionality
  - Role-based access control

- **Student Features**:
  - Personalized dashboard with OD request statistics
  - Complete OD request creation flow with smart staff assignment
  - Optional Class and Year Coordinator sections with dual selection confirmation
  - 30-second undo buffer after request submission
  - Student OD request management screen to track submitted requests
  - Timetable viewing with color-coded subjects
  - Staff directory with search functionality
  - Context-aware navigation to staff profiles

- **Staff Features**:
  - Staff dashboard with quick stats and actions
  - Comprehensive OD request inbox with filtering
  - Approval/rejection workflow with reason tracking
  - Personal and class timetable management
  - Staff directory with department filtering
  - Staff profile management with edit capabilities
  - Bulk operations for efficient batch processing

- **Analytics & Reporting**:
  - Interactive charts using fl_chart (pie, bar, line charts)
  - Request status distribution visualization
  - Monthly request volume tracking
  - Top rejection reasons analysis
  - Department-wise comparison
  - Professional PDF report generation with institutional branding
  - Multiple template types for different reports

- **Offline Support & Synchronization**:
  - Hive-based local caching with intelligent TTL strategies
  - Sync queue for offline operations
  - Conflict resolution mechanism
  - Background sync worker with connectivity monitoring
  - Exponential backoff retry mechanism
  - Automatic synchronization when online

- **Push Notifications**:
  - FCM integration for cross-platform notifications
  - Local notifications for offline scenarios
  - Deep linking to relevant screens
  - Notification grouping and badge management
  - Real-time alerts for OD request status changes

- **Bulk Operations**:
  - Multi-select UI with checkboxes and selection indicators
  - Batch approval, rejection, and export operations
  - Real-time progress tracking with visual indicators
  - Detailed error reporting for failed operations
  - Undo functionality with configurable time window

- **Calendar Integration**:
  - Device calendar permission management
  - Automatic event creation for approved ODs
  - Complete event lifecycle management (CRUD)
  - Customizable sync settings
  - Proper cleanup of created events

- **Staff Analytics & Workload Management**:
  - Workload tracking with weekly/monthly breakdown
  - Teaching analytics with subject-wise period allocation
  - Time allocation tracking by activity type
  - Efficiency metrics and performance tracking
  - Comparative analytics (semester-over-semester)
  - Department benchmarking and peer comparison
  - Proactive alerts for workload imbalances
  - Dark mode support for all analytics components

- **Enhanced User Experience**:
  - Skeleton loading screens for better perceived performance
  - Smooth page transitions and micro-interactions
  - Real-time form validation with helpful error messages
  - Contextual error messages with suggested actions
  - Improved navigation with breadcrumbs
  - Context preservation across navigation

- **Accessibility (WCAG 2.1 Compliant)**:
  - Screen reader support with semantic labeling
  - Keyboard navigation throughout the app
  - High contrast mode compatibility
  - Text scaling support (1.0x to 2.0x)
  - Focus management with visual indicators
  - Accessible form components
  - Semantic HTML-like structure in Flutter

- **Dark Mode**:
  - Complete dark theme implementation
  - Theme-aware colors across all screens
  - Proper contrast ratios for accessibility
  - Consistent styling across all components
  - Automatic theme switching based on system settings

- **Permissions System**:
  - Automatic permission checking on app launch
  - SDK 24-36 compatibility for storage permissions
  - Permissions screen with request UI
  - Router integration for permission flow
  - Debug logging for permission checking

### 🔄 In Progress
- Backend API integration for real-time data
- File attachment support for OD requests
- Email notifications system
- Digital signature integration

### 📋 Planned
- Security audit & penetration testing
- JWT token refresh mechanism
- Data encryption at rest
- Performance optimization and memory leak detection
- Multi-language support (i18n)
- Biometric authentication
- QR code scanning for quick actions
- Play Store & App Store submissions
- CI/CD pipeline setup
- Monitoring & crash reporting

## Recent Updates (January 2025)

### Permissions System Implementation
- **Automatic Permission Checking**: Permissions are now checked automatically on app launch
- **SDK Compatibility**: Full support for Android SDK 24-36 with appropriate permission handling:
  - SDK 24-28: Uses `WRITE_EXTERNAL_STORAGE`
  - SDK 29: No special permissions required (scoped storage)
  - SDK 30+: Uses `MANAGE_EXTERNAL_STORAGE`
- **Permissions Screen**: New dedicated screen for requesting and managing permissions
- **Router Integration**: Automatic redirect to permissions screen if permissions not granted
- **Debug Logging**: Comprehensive logging for permission checking flow

### Theme & UI Improvements
- **Global Button Styling**: All buttons now inherit 8px border radius from theme definition
- **Consistent Design**: Removed redundant button shape definitions across all screens
- **Code Quality**: Fixed lint issues and improved code maintainability

### Code Quality Improvements
- Replaced `print()` with `debugPrint()` for production code
- Fixed const constructor issues in theme definitions
- Removed unused variables and improved code clarity
- All files pass Flutter analysis without warnings or errors

1. Follow Flutter/Dart style guidelines
2. Use conventional commit messages
3. Write tests for new features (aim for 100% coverage for critical services)
4. Update documentation as needed
5. Ensure backward compatibility
6. Test on multiple screen sizes and orientations
7. Maintain accessibility compliance with WCAG 2.1 standards
8. Follow the architecture patterns established in the project

## License

Copyright © 2025 Office of Academic Affairs. All rights reserved.