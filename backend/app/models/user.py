from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func
from app.core.database import Base
from app.core.enums import UserRole

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, index=True)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    
    # Audit fields
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Role specific fields (can be expanded later or normalized)
    role = Column(String, default=UserRole.STUDENT) # student, staff, admin
    fcm_token = Column(String, nullable=True)

    # Profile Fields (New)
    department = Column(String, nullable=True)
    designation = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    office = Column(String, nullable=True)
    specialization = Column(String, nullable=True)
    experience_years = Column(Integer, nullable=True)
    qualification = Column(String, nullable=True)
