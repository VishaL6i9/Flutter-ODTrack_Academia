import asyncio
import asyncpg
from app.core.config import get_settings

settings = get_settings()

async def create_database():
    # Extract connection info from settings.DATABASE_URL
    # Format: postgresql+asyncpg://user:password@host/dbname
    url = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
    
    # Parse URL to get user, password, host, and dbname
    from urllib.parse import urlparse
    parsed = urlparse(url)
    user = parsed.username
    password = parsed.password
    host = parsed.hostname
    port = parsed.port or 5432
    target_db = parsed.path.lstrip("/")
    
    # Connect to default 'postgres' database to create the new one
    sys_conn = await asyncpg.connect(
        user=user,
        password=password,
        host=host,
        port=port,
        database='postgres'
    )
    
    try:
        # Check if database exists
        exists = await sys_conn.fetchval(
            "SELECT 1 FROM pg_database WHERE datname = $1", target_db
        )
        if not exists:
            print(f"Creating database '{target_db}'...")
            await sys_conn.execute(f'CREATE DATABASE "{target_db}"')
            print("Database created successfully.")
        else:
            print(f"Database '{target_db}' already exists.")
    except Exception as e:
        print(f"Error creating database: {e}")
    finally:
        await sys_conn.close()

if __name__ == "__main__":
    asyncio.run(create_database())
