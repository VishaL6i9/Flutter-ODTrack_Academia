from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import get_settings
from app.api.api_v1.api import api_router
from app.core.logging import logger

settings = get_settings()

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Backend API for ODTrack Academia Mobile App",
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)

@app.on_event("startup")
async def startup_event():
    logger.info("Starting up ODTrack Academia API...")

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Shutting down ODTrack Academia API...")

@app.get("/")
async def root():
    logger.info("Root endpoint accessed")
    return {"message": "Welcome to ODTrack Academia API", "status": "running"}

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "ODTrack Academia Backend"}
