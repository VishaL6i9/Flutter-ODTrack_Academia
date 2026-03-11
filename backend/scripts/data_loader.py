import asyncio
import sys
import os
from datetime import datetime, timedelta
import random

# Add parent directory to path to import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import AsyncSessionLocal as SessionLocal
from app.models.user import User
from app.models.od_request import ODRequest
from app.models.subject import Subject
from app.models.timetable import Timetable
from app.core.security import get_password_hash
from app.core.enums import UserRole, ODStatus

# --- Frontend Data Structures ---

STAFF_DATA = [
    {"id": "S001", "name": "Dr. Alan Grant", "email": "alan.grant@example.com", "department": "Computer Science", "designation": "Professor", "phone": "123-456-7890", "office": "CS-101", "specialization": "Data Structures", "experience_years": 15, "qualification": "Ph.D."},
    {"id": "S002", "name": "Dr. Ellie Sattler", "email": "ellie.sattler@example.com", "department": "Computer Science", "designation": "Professor", "phone": "123-456-7891", "office": "CS-102", "specialization": "Database Management", "experience_years": 12, "qualification": "Ph.D."},
    {"id": "S003", "name": "Dr. Ian Malcolm", "email": "ian.malcolm@example.com", "department": "Computer Science", "designation": "Professor", "phone": "123-456-7892", "office": "CS-103", "specialization": "Computer Networks", "experience_years": 14, "qualification": "Ph.D."},
    {"id": "S004", "name": "John Hammond", "email": "john.hammond@example.com", "department": "Information Technology", "designation": "Associate Professor", "phone": "123-456-7893", "office": "IT-101", "specialization": "Cloud Computing", "experience_years": 20, "qualification": "M.Tech"},
    {"id": "S005", "name": "Dennis Nedry", "email": "dennis.nedry@example.com", "department": "Information Technology", "designation": "Assistant Professor", "phone": "123-456-7894", "office": "IT-102", "specialization": "DevOps", "experience_years": 8, "qualification": "M.Tech"},
]

SUBJECTS = {
    'DSA': 'Data Structures and Algorithms',
    'DBMS': 'Database Management Systems',
    'OS': 'Operating Systems',
    'CN': 'Computer Networks',
    'SE': 'Software Engineering',
    'AI': 'Artificial Intelligence',
    'ML': 'Machine Learning',
    'OOP': 'Object Oriented Programming',
    'Discrete': 'Discrete Mathematics',
    'Math': 'Mathematics',
    'Physics': 'Applied Physics',
    'Chem': 'Engineering Chemistry',
    'Eng': 'Professional English',
    'Drawing': 'Engineering Drawing',
    'Web': 'Web Development',
    'Cloud': 'Cloud Computing',
    'Cyber': 'Cyber Security',
    'Project': 'Final Year Project',
    'DevOps': 'Development Operations',
    'Lab': 'Laboratory Session',
}

TIMETABLE_SLOTS = ['9:00-10:00', '10:00-11:00', '11:15-12:15', '12:15-13:15', '14:15-15:15']
DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']

# Sample Timetable Data snippet (representing the structure from timetable_data.dart)
RAW_TIMETABLES = [
    {
        "year": "2nd Year",
        "section": "A",
        "schedule": {
            "Monday": [("DSA", "S001"), ("Math", None), ("Free", None), ("Physics", None), ("LUNCH", None)],
            "Tuesday": [("DSA", "S001"), ("OS", None), ("Free", None), ("Lab", None), ("LUNCH", None)],
            "Wednesday": [("Math", None), ("DSA", "S001"), ("Free", None), ("SE", None), ("LUNCH", None)],
            "Thursday": [("OS", None), ("DBMS", "S002"), ("Free", None), ("DSA", "S001"), ("LUNCH", None)],
            "Friday": [("Free", None), ("DSA", "S001"), ("Math", None), ("SE", None), ("LUNCH", None)],
        }
    },
    {
        "year": "3rd Year",
        "section": "A",
        "schedule": {
            "Monday": [("CN", "S003"), ("DBMS", "S002"), ("Free", None), ("AI", None), ("LUNCH", None)],
            "Tuesday": [("DBMS", "S002"), ("CN", "S003"), ("Free", None), ("ML", None), ("LUNCH", None)],
            "Wednesday": [("AI", None), ("DBMS", "S002"), ("Free", None), ("Cyber", None), ("LUNCH", None)],
            "Thursday": [("ML", None), ("Cyber", None), ("Free", None), ("CN", "S003"), ("LUNCH", None)],
            "Friday": [("Cyber", None), ("ML", None), ("Cloud", "S004"), ("DevOps", "S005"), ("LUNCH", None)],
        }
    }
]

STUDENT_FIRST_NAMES = ['Aarav', 'Vivaan', 'Aditya', 'Vihaan', 'Arjun', 'Sai', 'Reyansh', 'Ayaan', 'Krishna', 'Ishaan', 'Ananya', 'Diya', 'Priya', 'Kavya', 'Aanya', 'Ira', 'Pihu', 'Riya', 'Anvi', 'Tara']
STUDENT_LAST_NAMES = ['Sharma', 'Patel', 'Kumar', 'Singh', 'Reddy', 'Gupta', 'Agarwal', 'Jain', 'Mehta', 'Shah']

async def load_data():
    async with SessionLocal() as db:
        print("Starting CLEAN data loading...")
        
        # 0. Clear existing data
        await db.execute(delete(ODRequest))
        await db.execute(delete(Timetable))
        await db.execute(delete(Subject))
        await db.execute(delete(User))
        await db.commit()
        print("Existing data cleared.")

        test_password_hash = get_password_hash("password123")
        
        # 1. Load Subjects
        print(f"Loading {len(SUBJECTS)} subjects...")
        subject_map = {} # code -> ID
        for code, name in SUBJECTS.items():
            subj = Subject(code=code, name=name, type="Theory" if "Lab" not in name else "Lab")
            db.add(subj)
            await db.flush()
            subject_map[code] = subj.id
        
        # 2. Load Staff
        print(f"Syncing {len(STAFF_DATA)} staff members with full profiles...")
        staff_id_map = {} # S-ID -> DB-ID
        for s in STAFF_DATA:
            user = User(
                email=s["email"],
                hashed_password=test_password_hash,
                full_name=s["name"],
                role=UserRole.STAFF,
                is_active=True,
                department=s["department"],
                designation=s["designation"],
                phone=s["phone"],
                office=s["office"],
                specialization=s["specialization"],
                experience_years=s["experience_years"],
                qualification=s["qualification"]
            )
            db.add(user)
            await db.flush()
            staff_id_map[s["id"]] = user.id
            
        # 3. Load Students
        print("Generating student users...")
        student_users = []
        
        # Add SPECIFIC Test Student for the user
        test_student = User(
            email="test@student.com",
            hashed_password=test_password_hash,
            full_name="Test Student",
            role=UserRole.STUDENT,
            is_active=True,
            register_number="42110565",
            department="Computer Science",
            year="2nd Year",
            section="A"
        )
        db.add(test_student)
        await db.flush()
        student_users.append((test_student.id, "42110565", test_student.full_name))

        # Generate 29 more student users
        for i in range(29):
            email = f"student{i+1:03d}@college.edu"
            reg_num = f"20CS{100+i}"
            first = random.choice(STUDENT_FIRST_NAMES)
            last = random.choice(STUDENT_LAST_NAMES)
            year = random.choice(["2nd Year", "3rd Year"])
            section = "A"
            
            user = User(
                email=email,
                hashed_password=test_password_hash,
                full_name=f"{first} {last}",
                role=UserRole.STUDENT,
                is_active=True,
                register_number=reg_num,
                department="Computer Science",
                year=year,
                section=section
            )
            db.add(user)
            await db.flush()
            student_users.append((user.id, reg_num, user.full_name))
            
        # 4. Load Timetables
        print(f"Loading timetables for {len(RAW_TIMETABLES)} sections...")
        for tt_data in RAW_TIMETABLES:
            for day, slots in tt_data["schedule"].items():
                for i, slot_info in enumerate(slots):
                    subj_code, s_id = slot_info
                    if subj_code is None or subj_code == "LUNCH":
                        continue
                        
                    timetable_entry = Timetable(
                        year=tt_data["year"],
                        section=tt_data["section"],
                        day=day,
                        period_number=i + 1,
                        time_slot=TIMETABLE_SLOTS[i],
                        subject_id=subject_map.get(subj_code),
                        staff_id=staff_id_map.get(s_id),
                        room=f"Room {random.randint(101, 305)}"
                    )
                    db.add(timetable_entry)
        
        # 5. Load OD Requests
        print("Generating 50 sample OD requests...")
        reasons = [
            'Medical appointment', 'Family function', 'Personal work', 
            'Interview', 'Emergency', 'Travel', 'Conference', 'Workshop'
        ]
        statuses = [ODStatus.PENDING, ODStatus.APPROVED, ODStatus.REJECTED]
        
        for i in range(50):
            student_id, reg_num, s_name = random.choice(student_users)
            staff_s_id = random.choice(list(staff_id_map.keys()))
            staff_db_id = staff_id_map[staff_s_id]
            
            status = random.choice(statuses)
            created_at = datetime.now() - timedelta(days=random.randint(1, 180))
            
            od = ODRequest(
                student_id=student_id,
                register_number=reg_num,
                student_name=s_name,
                date=created_at + timedelta(days=random.randint(1, 30)),
                periods=[1, 2, 3],
                reason=random.choice(reasons),
                status=status,
                created_at=created_at,
                approved_by_id=staff_db_id if status != ODStatus.PENDING else None,
                approved_at=created_at + timedelta(hours=random.randint(1, 48)) if status != ODStatus.PENDING else None
            )
            db.add(od)

        await db.commit()
        print("CLEAN- [/] Final API Integration & Frontend Cleanup\n  - [/] Align Flutter models with backend schemas\n  - [ ] Implement `AuthService`, `ODApiService`, and `EducationalDataService` in Flutter\n  - [ ] Update `AuthNotifier` to use real backend authentication\n  - [ ] Update `ODRequestNotifier` to use real backend data\n  - [ ] Verify full project functionality (Login -> Fetch -> Create)\n")
        
        # Final Verification
        res_u = await db.execute(select(User))
        res_s = await db.execute(select(Subject))
        res_t = await db.execute(select(Timetable))
        res_od = await db.execute(select(ODRequest))
        
        print(f"\nFinal DB State:")
        print(f"- Users: {len(res_u.scalars().all())}")
        print(f"- Subjects: {len(res_s.scalars().all())}")
        print(f"- Timetables: {len(res_t.scalars().all())}")
        print(f"- OD Requests: {len(res_od.scalars().all())}")

if __name__ == "__main__":
    asyncio.run(load_data())
