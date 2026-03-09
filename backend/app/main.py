import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.core.config import get_settings
from app.api.api_v1.api import api_router
from app.core.logging import logger

settings = get_settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting up ODTrack Academia API...")
    logger.info(f"Debug mode: {settings.DEBUG}")
    logger.info(f"CORS origins: {settings.BACKEND_CORS_ORIGINS}")
    yield
    # Shutdown
    logger.info("Shutting down ODTrack Academia API...")

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Backend API for ODTrack Academia Mobile App",
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create UPLOAD_DIR if missing
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
# Mount UPLOAD_DIR for static file access
app.mount("/static/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
async def root():
    logger.info("Root endpoint accessed")
    return {"message": "Welcome to ODTrack Academia API", "status": "running"}

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "ODTrack Academia Backend"}
