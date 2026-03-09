from typing import Any, Annotated
from fastapi import APIRouter, Body, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.schemas.user import User, UserCreate
from app.services.user_service import user_service
from app.core.logging import logger

router = APIRouter()

@router.post("/", response_model=User)
async def create_user(
    *,
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    user_in: UserCreate,
) -> Any:
    """
    Create new user.
    """
    user = await user_service.get_by_email(db, email=user_in.email)
    if user:
        logger.warning(f"Registration attempt with existing email: {user_in.email}")
        raise HTTPException(
            status_code=400,
            detail="The user with this email already exists in the system.",
        )
    user = await user_service.create(db, user_in=user_in)
    logger.info(f"New user registered: {user.email} with role {user.role}")
    return user

@router.get("/me", response_model=User)
async def read_user_me(
    current_user: Annotated[User, Depends(deps.get_current_active_user)]
) -> Any:
    """
    Get current user.
    """
    return current_user

@router.put("/me/signature", response_model=User)
async def update_signature(
    *,
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    current_user: Annotated[User, Depends(deps.get_current_active_user)],
    signature_url: Annotated[str, Body(embed=True)]
) -> Any:
    """
    Update signature URL for staff.
    """
    if current_user.role not in [UserRole.STAFF, UserRole.ADMIN, UserRole.SUPERUSER]:
         raise HTTPException(status_code=403, detail="Only staff can add signatures")
         
    updated_user = await user_service.update_signature(db, user_obj=current_user, signature_url=signature_url)
    return updated_user
