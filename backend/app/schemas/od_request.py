from pydantic import BaseModel, Field
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

class ODRequestCreate(ODRequestBase):
    pass

class ODRequestUpdate(BaseModel):
    status: Optional[str] = None
    rejection_reason: Optional[str] = None

class ODRequestInDBBase(ODRequestBase):
    id: int
    student_id: int
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    approved_at: Optional[datetime] = None
    approved_by_id: Optional[int] = None
    rejection_reason: Optional[str] = None

    class Config:
        from_attributes = True

class ODRequest(ODRequestInDBBase):
    student: Optional[User] = None
    approved_by: Optional[User] = None
