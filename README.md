# ODTrack Academia™ - Mobile Client

A Flutter-based mobile application for OD (On Duty) request management in academic institutions.

## Project Overview

ODTrack Academia™ provides students and staff with a lightweight, offline-capable interface to:
- Submit & track OD requests
- View faculty timetables and Year-Hall assignments
- Browse the read-only Staff Directory

## Technology Stack

- **Framework**: Flutter 3.19+ with Dart 3
- **State Management**: Riverpod + Hive for local cache
- **Network**: Dio + Retrofit-Flutter for REST calls
- **Security**: flutter_secure_storage (AES-256) for JWT
- **Navigation**: GoRouter for declarative routing

## Project Structure

```
lib/
├── core/                 # Core application files
│   ├── app.dart         # Main app widget
│   ├── constants/       # App constants & routes
│   ├── router/          # GoRouter navigation configuration
│   └── theme/           # Material Design theming
├── features/            # Feature modules (Clean Architecture)
│   ├── auth/           # Authentication (login/logout)
│   │   └── presentation/
│   ├── dashboard/      # Main dashboard for students & staff
│   │   └── presentation/
│   ├── od_request/     # OD request management
│   │   └── presentation/
│   ├── staff_directory/ # Staff directory & search
│   │   ├── data/       # Staff data models
│   │   └── presentation/
│   ├── staff_inbox/    # Staff OD request inbox
│   │   └── presentation/
│   ├── staff_profile/  # Staff profile management
│   │   └── presentation/
│   └── timetable/      # Timetable viewing (class & staff)
│       ├── data/       # Timetable data & models
│       └── presentation/
├── models/             # Data models (User, ODRequest, etc.)
├── providers/          # Riverpod state management
├── services/           # API services (empty - for future backend)
├── shared/             # Shared widgets (empty - for future components)
├── utils/              # Utility functions (empty - for future helpers)
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
  - Toast notifications for staff information
  - View request history with status tracking
- **Timetable Access**: View class timetables with color-coded subjects
- **Staff Directory**: Browse faculty contacts with search functionality
- **Smart Navigation**: Context-aware navigation to relevant staff profiles

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

### 🔧 Technical Features
- **Offline-First**: Local data caching with Hive
- **Responsive Design**: Optimized for various screen sizes
- **Material Design**: Modern UI following Material Design 3
- **State Management**: Efficient state handling with Riverpod
- **Navigation**: Declarative routing with GoRouter
- **Performance**: Optimized builds with tree-shaking

## Development Milestones

### Completed ✅
- [x] **M1: Project Foundation** (Dec 2024)
  - Flutter project setup with clean architecture
  - Core navigation with GoRouter
  - Material Design theming
  - Riverpod state management setup

- [x] **M2: Authentication & Dashboard** (Jan 2025)
  - Student login (Register Number + DOB)
  - Staff login (Email + Password)
  - Role-based dashboard with quick stats
  - Basic navigation structure

- [x] **M4: Staff Management System** (Jan 2025)
  - Staff inbox with OD request filtering
  - Approve/reject functionality with confirmation dialogs
  - Staff personal timetable with color coding
  - Class timetable browser with search/filter
  - Staff directory with pre-filtering
  - Staff profile management with editable fields
  - Password change functionality

### In Progress 🚧
- [ ] **M3: Complete OD Request Flow**
  - Backend API integration
  - Real-time status updates
  - File attachment support
  - Email notifications
  - Digital signature integration

### Planned 📋
- [ ] **M5: Enhanced Features**
  - Push notifications for request updates
  - Offline data synchronization
  - Advanced reporting & analytics
  - Bulk operations for staff
  - Calendar integration
  - Export functionality (PDF reports)

- [ ] **M6: Security & Performance**
  - Security audit & penetration testing
  - JWT token refresh mechanism
  - Data encryption at rest
  - Performance optimization
  - Memory leak detection
  - Accessibility compliance (WCAG 2.1)

- [ ] **M7: Advanced Features**
  - Multi-language support (i18n)
  - Dark mode theme
  - Biometric authentication
  - QR code scanning for quick actions
  - Voice notes for OD reasons
  - Integration with academic calendar

- [ ] **M8: Production Deployment**
  - Play Store & App Store submissions
  - CI/CD pipeline setup
  - Monitoring & crash reporting
  - User feedback system
  - Beta testing program
  - Production rollout strategy

## Current Implementation Status

### ✅ Fully Implemented
- Complete authentication system for students and staff
- Role-based dashboards with dynamic content
- Full OD request creation flow with smart staff assignment
- Comprehensive staff inbox with approval/rejection workflow
- Advanced timetable system with color coding and filtering
- Staff directory with search and pre-filtering
- Staff profile management system

### 🔄 Demo Mode
- Currently uses hardcoded data for demonstration
- Mock API responses with simulated delays
- Local state management without backend persistence
- Sample timetables for 4 years across multiple departments
- 33+ staff members with realistic data distribution

### 🚀 Ready for Backend Integration
- Clean architecture with separated data layers
- Provider pattern ready for API integration
- Models with JSON serialization support
- Error handling structure in place
- Loading states and user feedback systems

## Contributing

1. Follow Flutter/Dart style guidelines
2. Use conventional commit messages
3. Write tests for new features
4. Update documentation as needed
5. Ensure backward compatibility
6. Test on multiple screen sizes and orientations

## License

Copyright © 2025 Office of Academic Affairs. All rights reserved.