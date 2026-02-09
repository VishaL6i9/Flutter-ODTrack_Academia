from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    PROJECT_NAME: str = "ODTrack Academia"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    DEBUG: bool = True
    
    # Database
    # Defaulting to PostgreSQL
    DATABASE_URL: str = "postgresql+asyncpg://postgres:password@localhost/odtrack_academia_fastapi"
    
    # Security
    SECRET_KEY: str = "YOUR_SECRET_KEY_HERE_CHANGE_IN_PRODUCTION"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # CORS
    BACKEND_CORS_ORIGINS: list[str] = [
        "http://localhost",
        "http://localhost:8000",
        "http://127.0.0.1",
        "http://127.0.0.1:8000",
        "http://10.0.2.2:8000",
        "*"
    ]
    
    class Config:
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()
