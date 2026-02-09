from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import get_settings
from app.core.logging import logger

settings = get_settings()

try:
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=settings.DEBUG, # Configurable
        future=True,
    )
    logger.info("Database engine created successfully.")
except Exception as e:
    logger.error(f"Failed to create database engine: {e}")
    raise e

AsyncSessionLocal = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
