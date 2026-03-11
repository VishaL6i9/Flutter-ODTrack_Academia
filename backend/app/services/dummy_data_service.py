"""
Dummy data service for staff, timetables, and other reference data.
Now fetches from the real database populated by the data loader.
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, time
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from app.models.user import User
from app.models.subject import Subject
from app.models.timetable import Timetable
from app.core.enums import UserRole

class DummyDataService:
    """Service to provide comprehensive data for the system from DB"""
    
    async def get_staff_list(self, db: AsyncSession) -> List[Dict[str, Any]]:
        """Get list of active staff users from DB"""
        result = await db.execute(select(User).where(User.role == UserRole.STAFF, User.is_active == True))
        staff_users = result.scalars().all()
        result_list = []
        for user in staff_users:
            result_list.append({
                "id": str(user.id),
                "name": user.full_name,
                "email": user.email,
                "department": user.department or "General",
                "designation": user.designation or "Staff",
                "phone": user.phone,
                "office": user.office,
                "specialization": user.specialization,
                "experience_years": user.experience_years,
                "qualification": user.qualification,
                "subjects": ["General"],
                "available_hours": ["9:00 - 17:00"]
            })
        return result_list

    async def get_staff_timetable(self, db: AsyncSession, staff_id: str) -> Dict[str, Any]:
        """Get personal timetable for a specific staff member across all classes"""
        from app.models.timetable import Timetable as TimetableModel
        from sqlalchemy.orm import selectinload
        
        # Get all timetable entries for this staff member
        try:
            db_staff_id = int(staff_id)
        except ValueError:
            return {day: [{"subject": "Free", "staffId": None, "type": "lecture"} for _ in range(5)] for day in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]}

        result = await db.execute(
            select(TimetableModel)
            .options(selectinload(TimetableModel.subject))
            .where(TimetableModel.staff_id == db_staff_id)
        )
        staff_entries = result.scalars().all()
        
        days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        staff_schedule = {day: [{"subject": "Free", "staffId": None, "type": "lecture"} for _ in range(5)] for day in days}
        
        for tt in staff_entries:
            if tt.day in staff_schedule and 1 <= tt.period_number <= 5:
                # Find subject info
                subject_code = tt.subject.code if tt.subject else "GEN"
                staff_schedule[tt.day][tt.period_number - 1] = {
                    "subject": subject_code,
                    "staffId": f"{tt.year} - {tt.section}", 
                    "type": "lecture"
                }
        
        return staff_schedule
    
    async def get_timetable(self, db: AsyncSession, section: str = "A", year: int = 2) -> Dict[str, Any]:
        """Get timetable for a specific section and year from DB"""
        # Mapping year integer to string format used in data_loader
        year_str = f"{year}nd Year" if year == 2 else f"{year}rd Year"
        if year == 1: year_str = "1st Year"
        if year == 4: year_str = "4th Year"
        
        result = await db.execute(
            select(Timetable)
            .options(selectinload(Timetable.subject), selectinload(Timetable.staff))
            .where(Timetable.section == section, Timetable.year == year_str)
        )
        timetable_entries = result.scalars().all()
        
        # Group by day - Initialize with 5 slots per day to match frontend header count
        days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        # period_number is 1-indexed (1 to 5)
        day_slots = {day: [None] * 5 for day in days}
        
        for entry in timetable_entries:
            if entry.day in day_slots and 1 <= entry.period_number <= 5:
                day_slots[entry.day][entry.period_number - 1] = {
                    "subject": entry.subject.code if entry.subject else "GEN",
                    "staffId": entry.staff.full_name if entry.staff else "Professor",
                    "type": "lecture"
                }
        
        # Fill missing slots with "Free"
        formatted_schedule = {}
        for day in days:
            formatted_schedule[day] = [
                slot if slot else {"subject": "Free", "staffId": None, "type": "lecture"}
                for slot in day_slots[day]
            ]
            
        return {
            "section": section,
            "year": str(year), # Must be String
            "semester": (year * 2) - 1,
            "academic_year": "2025-2026",
            "department": "Computer Science",
            "schedule": formatted_schedule
        }
    
    @staticmethod
    def get_departments() -> List[Dict[str, Any]]:
        """Get static list of departments (keeping this static for now)"""
        return [
            {
                "id": "dept_cs",
                "name": "Computer Science",
                "code": "CS",
                "hod": "Dr. Rajesh Kumar",
                "hod_email": "rajesh.kumar@odtrack.edu",
                "building": "CS Block",
                "total_staff": 5,
            },
            {
                "id": "dept_it",
                "name": "Information Technology",
                "code": "IT",
                "hod": "Dr. Meena Reddy",
                "hod_email": "meena.reddy@odtrack.edu",
                "building": "IT Block",
                "total_staff": 4,
            },
            # ... other departments truncated for simplicity in this implementation
        ]
    
    async def get_subjects(self, db: AsyncSession, department: str = "CS", year: int = 3) -> List[Dict[str, Any]]:
        """Get subjects from DB"""
        result = await db.execute(select(Subject))
        subjects = result.scalars().all()
        return [
            {
                "code": s.code,
                "name": s.name,
                "credits": s.credits,
                "type": s.type,
                "staff": "Various"
            }
            for s in subjects
        ]
    
    @staticmethod
    def get_academic_calendar() -> Dict[str, Any]:
        """Get academic calendar (keeping static for now)"""
        return {
            "academic_year": "2025-2026",
            "events": [
                {"date": "2025-07-15", "event": "Semester Start", "type": "academic"},
                {"date": "2025-08-15", "event": "Independence Day", "type": "holiday"},
            ]
        }
    
    async def get_students_list(self, db: AsyncSession) -> List[Dict[str, Any]]:
        """Get list of students from DB"""
        result = await db.execute(select(User).where(User.role == UserRole.STUDENT))
        students = result.scalars().all()
        return [
            {
                "id": str(s.id),
                "register_number": s.register_number,
                "name": s.full_name,
                "email": s.email,
                "department": s.department,
                "year": s.year or "N/A",
                "section": s.section or "N/A",
            }
            for s in students
        ]

dummy_data_service = DummyDataService()



dummy_data_service = DummyDataService()
