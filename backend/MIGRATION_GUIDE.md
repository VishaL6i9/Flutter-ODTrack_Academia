# Database Migration Guide 🐘

This guide explains how to manage database changes in the ODTrack Academia backend using **Alembic**.

## 🧐 What is a Migration?

When you modify your Python code (models in `app/models/`), the database doesn't automatically know about it. A **migration** is a script that tells the database how to change (e.g., "Add a `phone_number` column to `users` table") to match your code.

## 🛠️ Prerequisites

Ensure your virtual environment is activated and you are in the `backend` directory:

```powershell
cd backend
venv\Scripts\activate
```

## 🚀 The Workflow

### 1. Make Changes to Models
Edit your SQLAlchemy models in `app/models/`.
*Example: Adding a phone number to User.*

```python
# app/models/user.py
class User(Base):
    # ... existing fields
    phone_number = Column(String, nullable=True) # <--- New field
```

### 2. Generate Migration Script
Tell Alembic to compare your code with the current database and generate a script.

```powershell
alembic revision --autogenerate -m "add_phone_number_to_users"
```
*   `--autogenerate`: Automatically detects changes.
*   `-m "..."`: A short description of the change.

**✅ Verify**: Check the new file created in `alembic/versions/`. It should have `upgrade()` and `downgrade()` functions showing your changes.

### 3. Apply Changes
Execute the script to update the actual PostgreSQL database.

```powershell
alembic upgrade head
```
*   `head`: Refers to the latest migration version.

---

## ↩️ Undoing Changes

If you made a mistake or want to revert the last migration:

```powershell
alembic downgrade -1
```
*   `-1`: Go back one step.

---

## 📜 Common Commands

| Command | Description |
| :--- | :--- |
| `alembic current` | Shows the current revision of the database. |
| `alembic history` | Lists all migration scripts in order. |
| `alembic upgrade +1` | Move forward by one migration. |

## ⚠️ Troubleshooting

**"Target database is not up to date."**
*   **Cause**: You have migration scripts that haven't been applied yet.
*   **Fix**: Run `alembic upgrade head`.

**"DuplicateTable" or "AlreadyExists" error**
*   **Cause**: The database already has the table, but Alembic thinks it doesn't. This often happens if you manually created tables.
*   **Fix**: If you differ from the migration history, you might need to manually stamp the database version: `alembic stamp head` (Be careful! This assumes the DB structure strictly matches the `head` code).
