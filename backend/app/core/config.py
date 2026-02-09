from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    PROJECT_NAME: str = "ODTrack Academia"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Database
    # Defaulting to SQLite for ease of setup, but compatible with PostgreSQL
    DATABASE_URL: str = "sqlite+aiosqlite:///./odtrack.db"
    
    # Security
    SECRET_KEY: str = "YOUR_SECRET_KEY_HERE_CHANGE_IN_PRODUCTION"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    class Config:
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()
