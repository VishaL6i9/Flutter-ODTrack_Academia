from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache
import secrets
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "ODTrack Academia"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    DEBUG: bool = False
    
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:password@localhost/odtrack_academia_fastapi"
    
    # Security
    SECRET_KEY: str = secrets.token_urlsafe(32)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # CORS - Specific origins only, no wildcards
    BACKEND_CORS_ORIGINS: list[str] = [
        "http://localhost",
        "http://localhost:8000",
        "http://127.0.0.1",
        "http://127.0.0.1:8000",
        "http://10.0.2.2:8000",
    ]
    
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Validate that SECRET_KEY is set properly in production
        if not self.DEBUG and self.SECRET_KEY == secrets.token_urlsafe(32):
            raise ValueError(
                "SECRET_KEY must be explicitly set in production environment. "
                "Generate one with: python -c 'import secrets; print(secrets.token_urlsafe(32))'"
            )

@lru_cache()
def get_settings():
    return Settings()
