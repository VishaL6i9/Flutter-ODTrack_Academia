from datetime import timedelta
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from app.core import security
from app.api import deps
from app.schemas.token import Token
from app.services.user_service import user_service
from app.core.config import get_settings
from app.core.logging import logger

router = APIRouter()
settings = get_settings()

@router.post("/login", response_model=Token)
async def login_access_token(
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()]
) -> Any:
    """
    OAuth2 compatible token login, get an access token for future requests
    """
    user = await user_service.authenticate(
        db, email=form_data.username, password=form_data.password
    )
    if not user:
        logger.warning(f"Failed login attempt for email: {form_data.username}")
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    elif not user.is_active:
        logger.warning(f"Inactive user login attempt: {form_data.username}")
        raise HTTPException(status_code=400, detail="Inactive user")
    
    logger.info(f"User logged in: {user.email}")
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return {
        "access_token": security.create_access_token(
            user.id, expires_delta=access_token_expires
        ),
        "token_type": "bearer",
    }
