# ODTrack Academia Backend

![Python](https://img.shields.io/badge/python-3.14%2B-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.109%2B-009688)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-336791)
![Code Style](https://img.shields.io/badge/code%20style-black-000000.svg)

A high-performance, asynchronous REST API service designed to power the [ODTrack Academia](../README.md) mobile application. Built with modern Python functionality, type safety, and scalability in mind.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Database Setup](#database-setup)
- [Usage](#usage)
- [Testing](#testing)
- [Project Structure](#project-structure)

## 🔭 Overview

The ODTrack Academia Backend serves as the central source of truth for student On-Duty (OD) requests, staff approvals, and institutional analytics. It leverages **FastAPI** for high-throughput request handling and **PostgreSQL** for robust data integrity.

Key design principles:
*   **Async-First**: Fully asynchronous request processing using `asyncpg` and `AsyncIO`.
*   **Type Safety**: Comprehensive use of Python type hints and Pydantic models.
*   **Observability**: Structured logging and request auditing for production readiness.

## 🏗 Architecture

The application follows a layered **Service-Repository** pattern to ensure separation of concerns:

```mermaid
graph TD
    Client[Mobile Client] -->|HTTP/JSON| API[FastAPI Router]
    API -->|Pydantic| Service[Service Layer]
    Service -->|SQLAlchemy| DB[(PostgreSQL)]
    Service -.->|Pandas| Analytics[Analytics Engine]
    Service -.->|ReportLab| PDF[PDF Generator]
```

## ✨ Features

*   **Authentication & Authorization**: OAuth2 with Password Flow, handling JWT issuance and role-based access control (RBAC) for Students, Staff, and Admins.
*   **OD Request Management**: Complete lifecycle management for On-Duty requests (Creation -> Approval/Rejection -> History).
*   **Analytics Engine**: High-performance data aggregation using Pandas to generate dashboard metrics and insights.
*   **Reporting**: Native PDF generation for official OD summary reports.
*   **Database Migrations**: Version-controlled database schema changes using Alembic.

## 🚀 Getting Started

### Prerequisites

*   [Python 3.14+](https://www.python.org/downloads/)
*   [PostgreSQL 17+](https://www.postgresql.org/download/)

### Installation

1.  **Navigate to the backend directory:**
    ```bash
    cd backend
    ```

2.  **Create and activate a virtual environment:**
    ```bash
    # Windows
    py -m venv venv
    venv\Scripts\activate

    # Linux/macOS
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

### Configuration

The application uses **12-Factor App** principles for configuration.

1.  Copy the example configuration file:
    ```bash
    copy .env.example .env
    ```

2.  Edit `.env` and populate the following variables:
    ```ini
    DATABASE_URL=postgresql+asyncpg://user:password@localhost/dbname
    SECRET_KEY=your_secure_generated_key
    DEBUG=True
    ```

### Database Setup

1.  **Initialize the Database:**
    We provide a helper script to safely create the database if it doesn't exist.
    ```bash
    python create_db.py
    ```

2.  **Apply Migrations:**
    Deploy the schema to the database.
    ```bash
    alembic upgrade head
    ```

## ⚡ Usage

Start the development server with auto-reload enabled:

```bash
python -m uvicorn app.main:app --reload
```

The API will be available at:
*   **Root**: [http://127.0.0.1:8000](http://127.0.0.1:8000)
*   **Swagger UI**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
*   **ReDoc**: [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

## 🧪 Testing

We use **Pytest** for running integration tests. Ensure your test database environment is configured (or use the default local instance).

```bash
pytest tests/test_main_flow.py -v
```

## 📂 Project Structure

```
backend/
├── app/
│   ├── api/            # Route controllers (v1 endpoints)
│   ├── core/           # App configuration, security, logging
│   ├── models/         # SQLAlchemy database models
│   ├── schemas/        # Pydantic data transfer objects (DTOs)
│   └── services/       # Business logic layer
├── alembic/            # Database migration scripts
├── logs/               # Structured log storage
├── tests/              # Integration and unit tests
├── create_db.py        # Database initialization utility
└── requirements.txt    # Project dependencies
```

---

_Maintained by the Office of Academic Affairs. © 2026._
