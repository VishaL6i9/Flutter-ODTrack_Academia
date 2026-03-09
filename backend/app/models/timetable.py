from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class Timetable(Base):
    __tablename__ = "timetables"

    id = Column(Integer, primary_key=True, index=True)
    year = Column(String, nullable=False) # 1st Year, 2nd Year, etc.
    section = Column(String, nullable=False)
    day = Column(String, nullable=False) # Monday, Tuesday, etc.
    period_number = Column(Integer, nullable=False)
    time_slot = Column(String, nullable=False) # 9:00-10:00
    
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=True)
    staff_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    room = Column(String, nullable=True)

    subject = relationship("Subject")
    staff = relationship("User")
