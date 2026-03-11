import asyncio
import asyncpg
from app.core.config import get_settings

async def test_conn():
    settings = get_settings()
    print(f"Attempting to connect to: {settings.DATABASE_URL}")
    try:
        # Extract connection details from DATABASE_URL
        # postgresql+asyncpg://postgres:6190@localhost/odtrack_academia_fastapi
        url = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
        conn = await asyncpg.connect(url)
        print("Successfully connected!")
        await conn.close()
    except Exception as e:
        print(f"Connection failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_conn())
