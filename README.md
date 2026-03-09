# ODTrack Academia™

![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.8.1-0175C2?logo=dart)
![Python](https://img.shields.io/badge/Python-3.14+-3776AB?logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-009688?logo=fastapi)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-336791?logo=postgresql)

ODTrack Academia™ is a comprehensive, production-ready On-Duty (OD) request management system designed for academic institutions. Built using Flutter and FastAPI, the application delivers a seamless, cross-platform and offline-first experience for both students and staff.

## Features

### 🎓 For Students
- **Smart Requests**: Submit OD requests with intelligent timetable staff routing and a 30-second submission undo buffer.
- **Timetables & Directory**: Centralized access to visual weekly schedules and an interactive staff directory.
- **File Interfacing**: Attach supportive medical or event documents directly onto requests.
- **Notifications & Calendars**: Receive real-time FCM updates regarding request status changes with automatic event calendar synchronization. 

### 👨‍🏫 For Staff
- **OD Inbox**: A feature-rich dashboard for approving or rejecting requests in granular or massive bulk operations.
- **Actionable Analytics**: Deeply layered graphical insights tracking teaching workloads, peer comparisons, and historic rejection trends.
- **Secure Signatures**: Embed personalized digital signatures onto authenticated OD request printouts.
- **PDF Exporting**: Render and securely output institutional reports to PDF and CSV vectors on demand.

### 🔧 Architecture
- **Offline-First Resilience**: An intelligent `Hive` cache system and synchronous queue broker automatically caches writes offline and re-syncs seamlessly using Exponential Backoffs upon regaining connectivity.
- **Strict Accessibility**: Fully WCAG 2.1 Compliant incorporating structured screen reader tags, scaleable typography, high contrast dark mode structuring, and focused keyboard routing out of the box.
- **Role-Based Security**: Complete boundary isolation separating the Student (Reg # + DOB) and Staff (Email + Password) authentication schemas under a stateless JWT/AES-256 umbrella.

## Quickstart

Verify your environment meets the prerequisites before moving ahead.

### Prerequisites

| Toolkit | Minimum Version |
| :--- | :--- |
| **Flutter SDK** | 3.19+ |
| **Dart SDK** | 3.0+ |
| **Python** | 3.14+ |
| **PostgreSQL** | 17+ |

### Installing

1. **Clone the Source**: Include submodules if necessary.
   ```shell
   git clone <repository-url>
   cd Flutter-ODTrack_Academia
   ```
2. **Retrieve Packages**: 
   ```shell
   flutter pub get
   ```
3. **Generate Structs**: Build all Riverpod and Hive serialization adapters.
   ```shell
   dart run build_runner build -d
   ```
4. **Boot App**:
   ```shell
   flutter run
   ```

### Backend Sandbox

The Python server operates on Uvicorn. To attach a development backend instance to your local Android simulator (running on 10.0.2.2 usually):

```bash
cd backend

# Initialize Environment
python -m venv venv
.\venv\Scripts\activate  # Windows Environments

# Resolve Dependencies
pip install -r requirements.txt

# Migrate Empty DB
python create_db.py
alembic upgrade head

# Spin Uvicorn
python -m uvicorn app.main:app --reload
```

> **Note**: For production database credentials or SMTP targets, instantiate a local `.env` file leveraging `.env.example` inside the backend root.

## Testing and CI

The standard quality control pipelines integrate static analysis checks with deterministic mock configurations.
Run the complete unit test suite explicitly covering all edge conditions across the offline synchronization services:

```shell
flutter test
```

## Build Release

To strip debug payloads from Android systems and output a production AAB bundle:

```shell
flutter build appbundle --release
```

## Implementation Status

- [x] **M1: Architecture**: Riverpod setup, Hive Cache, and PostgreSQL
- [x] **M2: Identity Management**: JWT mapping, dual authentication routing
- [x] **M3: OD Connectivity**: FastAPI file uploads, SMTP Mocking, Digital Signatures
- [x] **M4 & M5: System Polishing**: Offline queues, Visual Analytics, Walkthroughs
- [x] **M6: Hardening**: Security Audits, AES-256 Storage Encyptions, Automatic JWT Tokens Refresh
- [x] **M7: Advanced Features**: FCM Push Notifications properly piped to Staff devices and Student tracking

## Support & Contributing
We welcome patches formatting under standard [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). Please submit feature branches mapped against active GitHub Issues. 

_Copyright © 2025-2026 Office of Academic Affairs. All rights reserved._
