"""
Dummy data service for staff, timetables, and other reference data.
Now fetches from the real database populated by the data loader.
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, time
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.subject import Subject
from app.models.timetable import Timetable

class DummyDataService:
    """Service to provide comprehensive data for the system from DB"""
    
    def get_staff_list(self, db: Session) -> List[Dict[str, Any]]:
        """Get list of active staff users from DB"""
        staff_users = db.query(User).filter(User.role == "staff", User.is_active == True).all()
        result = []
        for user in staff_users:
            result.append({
                "id": str(user.id),
                "name": user.full_name or user.username,
                "email": user.email,
                "department": user.department or "General",
                "designation": user.designation or "Staff",
                "phone": user.phone_number,
                "office": user.office_location,
                "specialization": user.specialization,
                "experience_years": user.experience_years,
                "qualification": user.qualification,
                "subjects": user.subjects or [],
                "available_hours": user.available_hours or []
            })
        return result

    def get_staff_timetable(self, db: Session, staff_id: str) -> Dict[str, Any]:
        """Get personal timetable for a specific staff member across all classes"""
        from app.models.timetable import Timetable as TimetableModel
        from app.models.subject import Subject
        
        # Get all timetables from DB
        all_timetables = db.query(TimetableModel).all()
        
        days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        staff_schedule = {day: [{"subject": "Free", "staffId": None, "type": "lecture"} for _ in range(5)] for day in days}
        
        for tt in all_timetables:
            schedule_data = tt.schedule_data
            for day, slots in schedule_data.items():
                if day not in staff_schedule:
                    continue
                for i, slot in enumerate(slots):
                    if i >= 5: continue
                    if slot.get("staff_id") == staff_id:
                        # Find subject info
                        subject_code = slot.get("subject_code", "GEN")
                        staff_schedule[day][i] = {
                            "subject": subject_code,
                            "staffId": f"Year {tt.year} Section {tt.section}", # Showing context in staffId field as per frontend expectation
                            "type": slot.get("type", "lecture")
                        }
        
        return staff_schedule
    
    @staticmethod
    def get_timetable(db: Session, section: str = "A", year: int = 3) -> Dict[str, Any]:
        """Get timetable for a specific section and year from DB"""
        # In a real app, we'd filter by section/year. For now, get all for the dept.
        # This is a simplified mapping for the demo.
        schedule_data = db.query(Timetable).all()
        
        # Group by day
        days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        result_schedule = {day: [] for day in days}
        
        for entry in schedule_data:
            if entry.day in result_schedule:
                result_schedule[entry.day].append({
                    "period": entry.period,
                    "time": entry.time_slot,
                    "subject": entry.subject.name if entry.subject else "Unknown",
                    "staff": entry.staff.full_name if entry.staff else "Unknown",
                    "room": entry.room_number
                })
        
        # Sort periods for each day
        for day in days:
            result_schedule[day].sort(key=lambda x: x["period"])
            
        return {
            "section": section,
            "year": year,
            "semester": (year * 2) - 1,
            "academic_year": "2025-2026",
            "department": "Computer Science",
            "schedule": result_schedule
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
    
    @staticmethod
    def get_subjects(db: Session, department: str = "CS", year: int = 3) -> List[Dict[str, Any]]:
        """Get subjects from DB"""
        subjects = db.query(Subject).all()
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
    
    @staticmethod
    def get_students_list(db: Session) -> List[Dict[str, Any]]:
        """Get list of students from DB"""
        students = db.query(User).filter(User.role == "student").all()
        return [
            {
                "id": str(s.id),
                "register_number": getattr(s, 'register_number', 'N/A'),
                "name": s.full_name,
                "email": s.email,
                "department": s.department,
                "year": 3, # Placeholder
                "section": "A", # Placeholder
            }
            for s in students
        ]

dummy_data_service = DummyDataService()



dummy_data_service = DummyDataService()
