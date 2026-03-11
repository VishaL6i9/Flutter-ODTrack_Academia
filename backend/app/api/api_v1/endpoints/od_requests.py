from typing import Any, Annotated, List
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.models.user import User
from app.schemas.od_request import ODRequest, ODRequestCreate, ODRequestUpdate, ODRequestList
from app.services.od_service import od_service
from app.core.enums import UserRole

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
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Only students can create OD requests")
    
    od_request = await od_service.create(db=db, obj_in=od_in, student_id=current_user.id)
    return od_request

@router.get("/", response_model=ODRequestList)
async def read_od_requests(
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    current_user: Annotated[User, Depends(deps.get_current_active_user)],
    skip: int = 0,
    limit: int = 100,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
) -> Any:
    """
    Get OD requests based on user role.
    """
    if current_user.role == UserRole.STUDENT:
        requests = await od_service.get_multi_by_student(
            db=db, student_id=current_user.id, skip=skip, limit=limit, date_from=date_from, date_to=date_to
        )
    elif current_user.role in [UserRole.STAFF, UserRole.ADMIN, UserRole.SUPERUSER]:
        # Staff sees all pending requests by default for their inbox
        requests = await od_service.get_all_pending(
            db=db, skip=skip, limit=limit, date_from=date_from, date_to=date_to
        )
    else:
        requests = []
        
    return {"requests": requests}

@router.get("/archive", response_model=List[ODRequest])
async def read_archived_od_requests(
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    current_user: Annotated[User, Depends(deps.get_current_active_user)],
    skip: int = 0,
    limit: int = 100,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
) -> Any:
    """
    Get archived OD requests (past requests) for the current user.
    """
    if current_user.role not in [UserRole.STAFF, UserRole.ADMIN, UserRole.SUPERUSER]:
        raise HTTPException(status_code=403, detail="Not authorized to view archive")
        
    requests = await od_service.get_archived_for_staff(
        db=db, staff_id=current_user.id, skip=skip, limit=limit, date_from=date_from, date_to=date_to
    )
    return requests

@router.get("/stats")
async def read_od_stats(
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    current_user: Annotated[User, Depends(deps.get_current_active_user)],
) -> Any:
    """
    Get OD request counts by status for the current user.
    Students get their own counts; staff get counts of all requests they handle.
    """
    if current_user.role == UserRole.STUDENT:
        stats = await od_service.get_stats_by_student(db=db, student_id=current_user.id)
    elif current_user.role in [UserRole.STAFF, UserRole.ADMIN, UserRole.SUPERUSER]:
        stats = await od_service.get_stats_for_staff(db=db, staff_id=current_user.id)
    else:
        stats = {"pending": 0, "approved": 0, "rejected": 0, "total": 0}
    return stats

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
    if current_user.role not in [UserRole.STAFF, UserRole.ADMIN, UserRole.SUPERUSER]:
        raise HTTPException(status_code=403, detail="Not authorized to view pending requests")
        
    od_requests = await od_service.get_all_pending(db=db, skip=skip, limit=limit)
    return od_requests

@router.put("/{request_id}", response_model=ODRequest)
async def update_od_request(
    *,
    db: Annotated[AsyncSession, Depends(deps.get_db)],
    request_id: int,
    od_in: ODRequestUpdate,
    current_user: Annotated[User, Depends(deps.get_current_active_user)],
) -> Any:
    """
    Update OD Request (Owner only, only if pending).
    """
    from app.core.enums import ODStatus
    od_request = await od_service.get(db=db, id=request_id)
    if not od_request:
        raise HTTPException(status_code=404, detail="OD Request not found")
    
    if od_request.student_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this request")
    
    if od_request.status != ODStatus.PENDING:
        raise HTTPException(status_code=400, detail="Cannot update request that is no longer pending")
    
    # Don't allow students to change status via this endpoint
    od_in.status = None
    
    od_request = await od_service.update(db=db, db_obj=od_request, obj_in=od_in)
    return od_request

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
    if current_user.role not in [UserRole.STAFF, UserRole.ADMIN, UserRole.SUPERUSER]:
         raise HTTPException(status_code=403, detail="Not authorized to approve requests")
    
    od_request = await od_service.get(db=db, id=request_id)
    if not od_request:
        raise HTTPException(status_code=404, detail="OD Request not found")
        
    od_request = await od_service.update_status(
        db=db, db_obj=od_request, obj_in=status_update, approver_id=current_user.id
    )
    return od_request
