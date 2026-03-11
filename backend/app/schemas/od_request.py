from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import List, Optional
from app.schemas.user import User

class ODRequestBase(BaseModel):
    date: datetime
    periods: List[int]
    reason: str
    attachment_url: Optional[str] = None
    register_number: str
    student_name: str
    staff_id: Optional[int] = None

class ODRequestCreate(ODRequestBase):
    pass

from app.core.enums import ODStatus

class ODRequestUpdate(BaseModel):
    status: Optional[ODStatus] = None
    rejection_reason: Optional[str] = None
    staff_id: Optional[int] = None
    date: Optional[datetime] = None
    periods: Optional[List[int]] = None
    reason: Optional[str] = None

class ODRequestInDBBase(ODRequestBase):
    id: int
    student_id: int
    status: ODStatus
    created_at: datetime
    updated_at: Optional[datetime] = None
    approved_at: Optional[datetime] = None
    approved_by_id: Optional[int] = None
    rejection_reason: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class ODRequest(ODRequestInDBBase):
    student: Optional[User] = None
    approved_by: Optional[User] = None
    staff: Optional[User] = None

class ODRequestList(BaseModel):
    requests: List[ODRequest]
