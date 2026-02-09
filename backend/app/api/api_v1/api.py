from fastapi import APIRouter
from app.api.api_v1.endpoints import auth, users, od_requests, analytics

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(od_requests.router, prefix="/od-requests", tags=["od_requests"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
