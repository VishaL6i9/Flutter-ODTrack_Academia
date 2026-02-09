from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
from app.core.enums import ODStatus

class ODRequest(Base):
    __tablename__ = "od_requests"

    id = Column(Integer, primary_key=True, index=True)
    
    # Relationships
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    student = relationship("User", foreign_keys=[student_id], backref="od_requests")
    
    # Request Details
    register_number = Column(String, index=True) # Redundant but useful for quick lookup
    student_name = Column(String) # Redundant but useful snapshot
    date = Column(DateTime(timezone=True), nullable=False)
    periods = Column(JSON, nullable=False) # List of period numbers [1, 2, 3]
    reason = Column(Text, nullable=False)
    attachment_url = Column(String, nullable=True)
    
    # Status & Approval
    status = Column(String, default=ODStatus.PENDING, index=True) # pending, approved, rejected
    
    approved_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    approved_by = relationship("User", foreign_keys=[approved_by_id])
    
    approved_at = Column(DateTime(timezone=True), nullable=True)
    rejection_reason = Column(Text, nullable=True)
    
    # Audit
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
