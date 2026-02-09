# ODTrack Academia - Backend API

The high-performance, asynchronous REST API powering the ODTrack Academia mobile application. Built with **FastAPI**, **PostgreSQL**, and **Python 3.14**.

## Features

- 🚀 **FastAPI**: High performance, easy to learn, fast to code, ready for production.
- 🐘 **PostgreSQL**: Robust relational database with `asyncpg` for high concurrency.
- 🔐 **JWT Auth**: Secure authentication with role-based access control (Student/Staff/Admin).
- 📊 **Analytics**: Real-time dashboard statistics using **Pandas**.
- 📄 **PDF Reporting**: Professional OD summary reports using **ReportLab**.
- 🧪 **Testing**: End-to-End integration tests with **Pytest**.

## Prerequisites

- **Python 3.14+**
- **PostgreSQL 17+**

## Quick Start

### 1. Environment Setup

```bash
# Navigate to backend directory
cd backend

# Create virtual environment (Windows)
py -m venv venv

# Activate virtual environment
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Database Configuration

1. Ensure PostgreSQL is running.
2. Create the project database (if manual creation is needed):
   ```sql
   CREATE DATABASE odtrack_academia_fastapi;
   ```
   *(Or run the provided script)*: `python create_db.py`

3. Configure environment:
   - Copy `.env.example` to `.env`
   - Update credentials in `.env`:
     ```ini
     DATABASE_URL=postgresql+asyncpg://postgres:YOUR_PASSWORD@localhost/odtrack_academia_fastapi
     ```

### 3. Database Migrations

Apply the schema to the database:

```bash
alembic upgrade head
```

### 4. Run Server

Start the development server with hot reload:

```bash
python -m uvicorn app.main:app --reload
```

- **API Root**: [http://127.0.0.1:8000/](http://127.0.0.1:8000/)
- **Swagger Docs**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **ReDoc**: [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

## Testing

Run the full integration test suite:

```bash
pytest tests/test_main_flow.py -v
```

## Project Structure

```
backend/
├── app/
│   ├── api/            # Route handlers (v1)
│   ├── core/           # Configuration & Security
│   ├── models/         # SQLAlchemy Models
│   ├── schemas/        # Pydantic Schemas
│   └── services/       # Business Logic (OD, Analytics, PDF)
├── alembic/            # Database Migrations
├── tests/              # Test Suite
└── requirements.txt    # Python Dependencies
```
