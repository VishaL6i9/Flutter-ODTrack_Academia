from sqlalchemy import Column, Integer, String
from app.core.database import Base

class Subject(Base):
    __tablename__ = "subjects"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    credits = Column(Integer, nullable=True)
    type = Column(String, nullable=True) # Theory, Lab, Project
