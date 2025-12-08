# ODTrack Academia™ - Mobile Client

A Flutter-based mobile application for OD (On Duty) request management in academic institutions.

## Project Overview

ODTrack Academia™ provides students and staff with a lightweight, offline-capable interface to:
- Submit & track OD requests
- View faculty timetables and Year-Hall assignments
- Browse the read-only Staff Directory
- Analyze OD request patterns with charts and generate PDF reports
- Integrate with device calendar for approved ODs
- Access comprehensive staff analytics and workload management
- Experience enhanced accessibility with WCAG-compliant features

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
- **Authentication**: Secure login with Register Number + Date of Birth
- **Dashboard**: Personalized dashboard with OD request statistics
- **OD Request Management**:
  - Create new OD requests with date/period selection
  - Real-time staff assignment based on timetable
  - Optional Class and Year Coordinator sections with confirmation when both selected
  - 30-second undo buffer after submission
  - Toast notifications for staff information
  - View request history with status tracking
  - Student OD request management screen to track submitted requests
- **Timetable Access**: View class timetables with color-coded subjects
- **Staff Directory**: Browse faculty contacts with search functionality
- **Smart Navigation**: Context-aware navigation to relevant staff profiles
- **Push Notifications**: Real-time alerts for OD request status changes
- **Offline Support**: Seamless app usage and request submission even without internet
- **Calendar Integration**: Sync approved OD requests with device calendar

### 👨‍🏫 Staff Features
- **Authentication**: Secure login with Email + Password
- **Dashboard**: Quick stats and action buttons for efficient workflow
- **OD Request Inbox**:
  - Filter requests by status (All/Pending/Approved/Rejected)
  - Approve/reject with confirmation dialogs and reason tracking
  - Real-time status updates with visual feedback
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
- **Analytics**:
  - View OD request trends with interactive charts
  - Generate and share PDF reports
- **Calendar Integration**:
  - Sync approved OD requests with the device calendar
- **Push Notifications**: Real-time alerts for new OD requests and status updates
- **Bulk Operations**: Efficiently approve, reject, or export multiple OD requests with progress tracking
- **Staff Analytics & Workload Management**: Detailed insights into workload, teaching assignments, time allocation, and performance metrics with dark mode support
- **Efficiency Metrics**: Performance tracking and comparative benchmarking with department-level comparisons

### 🔧 Technical Features
- **Offline-First**: Local data caching with Hive, intelligent sync queue, and conflict resolution
- **Push Notifications**: FCM integration for cross-platform notifications
- **Intelligent Caching**: Smart cache management with TTL and priority
- **Bulk Operations**: Efficient batch processing for staff actions with progress tracking and undo functionality
- **Staff Analytics & Workload Management**: Comprehensive tracking and visualization of staff performance with dark mode
- **PDF Export System**: Professional report generation with institutional branding
- **Calendar Integration**: Native device calendar integration for approved OD requests
- **Accessibility**: Full WCAG 2.1 compliance with screen reader support, keyboard navigation, high contrast mode, and semantic labeling
- **Responsive Design**: Optimized for various screen sizes
- **Material Design**: Modern UI following Material Design 3 with comprehensive dark mode support
- **State Management**: Efficient state handling with Riverpod
- **Navigation**: Declarative routing with GoRouter, breadcrumbs, and context preservation
- **Performance**: Optimized builds with tree-shaking and background processing

## Development Milestones

### Completed ✅
- [x] **M1: Project Foundation** (Dec 2024)
- [x] **M2: Authentication & Dashboard** (Jan 2025)
- [x] **M4: Staff Management System** (Jan 2025)
- [x] **M5: Enhanced Features**
  - Advanced reporting & analytics with interactive charts (May 2025)
  - Calendar integration (August 2025)
  - Export functionality (PDF reports) (October 2025)
  - Dark mode theme across all screens and components
  - Push notifications for request updates
  - Offline data synchronization with conflict resolution
  - Bulk operations for staff with progress tracking
  - Staff Analytics and Workload Management with comprehensive insights
  - Enhanced User Experience (skeleton loading, animations, form validation)
  - WCAG-compliant accessibility features (screen readers, keyboard navigation, high contrast mode)

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
  - Accessibility compliance (WCAG 2.1)

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
- Complete authentication system for students and staff
- Role-based dashboards with dynamic content
- Full OD request creation flow with smart staff assignment
- Optional Class and Year Coordinator sections with dual selection confirmation
- 30-second undo buffer after request submission
- Student OD request management screen to track submitted requests
- Comprehensive staff inbox with approval/rejection workflow
- Advanced timetable system with color coding and filtering
- Staff directory with search and pre-filtering
- Staff profile management system
- Analytics dashboard with interactive charts using fl_chart
- PDF report generation and sharing with institutional branding
- Device calendar integration for approved ODs
- Push notification system for real-time alerts
- Offline data synchronization with conflict resolution and background sync worker
- Bulk operations for efficient staff workflow with progress tracking and undo functionality
- Staff Analytics and Workload Management with comprehensive insights and dark mode support
- Enhanced User Experience (skeleton loading, animations, form validation)
- Comprehensive accessibility features (screen reader support, keyboard navigation, high contrast mode, semantic labeling)
- Dark mode theme applied across all screens and components
- Navigation improvements with breadcrumbs and context preservation

### 🔄 In Progress
- Backend API integration
- Real-time status updates
- File attachment support
- Email notifications
- Digital signature integration

## Contributing

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