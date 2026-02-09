from typing import Any, Annotated, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.models.user import User
from app.schemas.od_request import ODRequest, ODRequestCreate, ODRequestUpdate
from app.services.od_service import od_service

router = APIRouter()

@router.post("/", response_model=ODRequest)
async def create_od_request(
    *,
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    od_in: ODRequestCreate,
    current_user: Annotated[User, Depends(deps.get_current_active_user)],
) -> Any:
    """
    Create new OD Request (Student only).
    """
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="Only students can create OD requests")
    
    od_request = await od_service.create(db=db, obj_in=od_in, student_id=current_user.id)
    return od_request

@router.get("/me", response_model=List[ODRequest])
async def read_od_requests_me(
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    current_user: Annotated[User, Depends(deps.get_current_active_user)],
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Get current user's OD requests.
    """
    od_requests = await od_service.get_multi_by_student(
        db=db, student_id=current_user.id, skip=skip, limit=limit
    )
    return od_requests

@router.get("/pending", response_model=List[ODRequest])
async def read_pending_od_requests(
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    current_user: Annotated[User, Depends(deps.get_current_active_user)],
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Get all pending OD requests (Staff/Admin only).
    """
    if current_user.role not in ["staff", "admin", "superuser"]:
        raise HTTPException(status_code=403, detail="Not authorized to view pending requests")
        
    od_requests = await od_service.get_all_pending(db=db, skip=skip, limit=limit)
    return od_requests

@router.put("/{request_id}/status", response_model=ODRequest)
async def update_od_status(
    *,
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    request_id: int,
    status_update: ODRequestUpdate,
    current_user: Annotated[User, Depends(deps.get_current_active_user)],
) -> Any:
    """
    Update OD Request status (Approve/Reject) - Staff/Admin only.
    """
    if current_user.role not in ["staff", "admin", "superuser"]:
         raise HTTPException(status_code=403, detail="Not authorized to approve requests")
    
    od_request = await od_service.get(db=db, id=request_id)
    if not od_request:
        raise HTTPException(status_code=404, detail="OD Request not found")
        
    od_request = await od_service.update_status(
        db=db, db_obj=od_request, obj_in=status_update, approver_id=current_user.id
    )
    return od_request
