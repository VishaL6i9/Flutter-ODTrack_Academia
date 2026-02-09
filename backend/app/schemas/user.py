from pydantic import BaseModel, EmailStr
from datetime import datetime

from app.core.enums import UserRole

# Shared properties
class UserBase(BaseModel):
    email: EmailStr
    full_name: str | None = None
    role: UserRole = UserRole.STUDENT
    is_active: bool = True

# Properties to receive via API on creation
class UserCreate(UserBase):
    password: str

# Properties to receive via API on update
class UserUpdate(UserBase):
    password: str | None = None

class UserInDBBase(UserBase):
    id: int
    created_at: datetime
    updated_at: datetime | None = None

    class Config:
        from_attributes = True

# Additional properties to return via API
class User(UserInDBBase):
    pass

class UserInDB(UserInDBBase):
    hashed_password: str
