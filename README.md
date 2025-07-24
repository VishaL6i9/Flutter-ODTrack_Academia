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
│   ├── constants/       # App constants
│   ├── router/          # Navigation configuration
│   └── theme/           # App theming
├── features/            # Feature modules
│   ├── auth/           # Authentication
│   ├── dashboard/      # Main dashboard
│   ├── od_request/     # OD request management
│   ├── timetable/      # Timetable viewing
│   ├── staff_directory/ # Staff directory
│   └── staff_inbox/    # Staff OD inbox
├── models/             # Data models
├── services/           # API services
├── providers/          # Riverpod providers
├── shared/             # Shared widgets
└── utils/              # Utility functions
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

### Student Features
- Login with Register Number + DOB
- Dashboard with OD request status
- Create new OD requests with attachments
- View timetable
- Browse staff directory
- Offline support for cached data

### Staff Features
- Login with Email + Password
- OD request inbox with filtering
- Approve/reject OD requests
- View personal schedule
- Digital signature integration

## Development Milestones

- [x] M1: Project setup and basic structure
- [ ] M2: Login + dashboard skeleton
- [ ] M3: OD full flow integrated with backend
- [ ] M4: Staff screens + timetable
- [ ] M5: Security audit & penetration test
- [ ] M6: Store submissions & rollout

## Contributing

1. Follow Flutter/Dart style guidelines
2. Use conventional commit messages
3. Write tests for new features
4. Update documentation as needed

## License

Copyright © 2025 Office of Academic Affairs. All rights reserved.