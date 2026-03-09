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
    {"id": "S001", "name": "Dr. Alan Grant", "email": "alan.grant@example.com", "department": "Computer Science", "designation": "Professor", "phone": "123-456-7890", "office": "CS-101", "specialization": "Data Structures & Algorithms", "experience_years": 15, "qualification": "Ph.D."},
    {"id": "S002", "name": "Dr. Ellie Sattler", "email": "ellie.sattler@example.com", "department": "Computer Science", "designation": "Professor", "phone": "123-456-7891", "office": "CS-102", "specialization": "Operating Systems", "experience_years": 12, "qualification": "Ph.D."},
    {"id": "S003", "name": "Dr. Ian Malcolm", "email": "ian.malcolm@example.com", "department": "Computer Science", "designation": "Professor", "phone": "123-456-7892", "office": "CS-103", "specialization": "Computer Networks", "experience_years": 14, "qualification": "Ph.D."},
    {"id": "S004", "name": "John Hammond", "email": "john.hammond@example.com", "department": "Information Technology", "designation": "Associate Professor", "phone": "123-456-7893", "office": "IT-101", "specialization": "Cloud Computing", "experience_years": 20, "qualification": "M.Tech"},
    {"id": "S005", "name": "Dennis Nedry", "email": "dennis.nedry@example.com", "department": "Information Technology", "designation": "Assistant Professor", "phone": "123-456-7894", "office": "IT-102", "specialization": "DevOps", "experience_years": 8, "qualification": "M.Tech"},
    {"id": "S006", "name": "Dr. Sarah Connor", "email": "sarah.connor@example.com", "department": "Mathematics", "designation": "Professor", "phone": "123-456-7895", "office": "MA-101", "specialization": "Engineering Mathematics", "experience_years": 18, "qualification": "Ph.D."},
    {"id": "S007", "name": "Dr. Kyle Reese", "email": "kyle.reese@example.com", "department": "Physics", "designation": "Associate Professor", "phone": "123-456-7896", "office": "PH-101", "specialization": "Engineering Physics", "experience_years": 10, "qualification": "Ph.D."},
    {"id": "S008", "name": "Prof. Ellen Ripley", "email": "ellen.ripley@example.com", "department": "English", "designation": "Professor", "phone": "123-456-7897", "office": "EN-101", "specialization": "Technical English", "experience_years": 15, "qualification": "M.A."},
    {"id": "S009", "name": "Mr. Dallas", "email": "dallas@example.com", "department": "Mechanical", "designation": "Assistant Professor", "phone": "123-456-7898", "office": "ME-101", "specialization": "Engineering Drawing", "experience_years": 7, "qualification": "M.Tech"},
    {"id": "S010", "name": "Dr. Ash", "email": "ash@example.com", "department": "Computer Science", "designation": "Assistant Professor", "phone": "123-456-7899", "office": "CS-104", "specialization": "Programming Lab", "experience_years": 6, "qualification": "Ph.D."},
    {"id": "S011", "name": "Dr. Lambert", "email": "lambert@example.com", "department": "Mathematics", "designation": "Associate Professor", "phone": "123-456-7900", "office": "MA-102", "specialization": "Advanced Mathematics", "experience_years": 11, "qualification": "Ph.D."},
    {"id": "S012", "name": "Prof. Parker", "email": "parker@example.com", "department": "English", "designation": "Professor", "phone": "123-456-7901", "office": "EN-102", "specialization": "Communication Skills", "experience_years": 13, "qualification": "M.A."},
    {"id": "S013", "name": "Dr. Neo Anderson", "email": "neo.anderson@example.com", "department": "Mathematics", "designation": "Associate Professor", "phone": "123-456-7902", "office": "MA-103", "specialization": "Discrete Mathematics", "experience_years": 12, "qualification": "Ph.D."},
    {"id": "S014", "name": "Dr. Trinity", "email": "trinity@example.com", "department": "Computer Science", "designation": "Assistant Professor", "phone": "123-456-7903", "office": "CS-105", "specialization": "Object Oriented Programming", "experience_years": 9, "qualification": "Ph.D."},
    {"id": "S015", "name": "Prof. Morpheus", "email": "morpheus@example.com", "department": "Computer Science", "designation": "Professor", "phone": "123-456-7904", "office": "CS-106", "specialization": "Discrete Mathematics", "experience_years": 16, "qualification": "M.Tech"},
    {"id": "S016", "name": "Mr. Agent Smith", "email": "agent.smith@example.com", "department": "Computer Science", "designation": "Assistant Professor", "phone": "123-456-7905", "office": "CS-107", "specialization": "Programming Lab", "experience_years": 8, "qualification": "M.Tech"},
    {"id": "S017", "name": "Dr. Oracle", "email": "oracle@example.com", "department": "Information Technology", "designation": "Professor", "phone": "123-456-7906", "office": "IT-103", "specialization": "Data Structures", "experience_years": 18, "qualification": "Ph.D."},
    {"id": "S018", "name": "Mr. Cypher", "email": "cypher@example.com", "department": "Information Technology", "designation": "Assistant Professor", "phone": "123-456-7907", "office": "IT-104", "specialization": "Web Development", "experience_years": 7, "qualification": "M.Tech"},
    {"id": "S019", "name": "Dr. Niobe", "email": "niobe@example.com", "department": "Information Technology", "designation": "Associate Professor", "phone": "123-456-7908", "office": "IT-105", "specialization": "Object Oriented Programming", "experience_years": 11, "qualification": "Ph.D."},
    {"id": "S020", "name": "Prof. Commander Lock", "email": "commander.lock@example.com", "department": "Mathematics", "designation": "Professor", "phone": "123-456-7909", "office": "MA-104", "specialization": "Applied Mathematics", "experience_years": 15, "qualification": "M.Tech"},
    {"id": "S021", "name": "Mr. Link", "email": "link@example.com", "department": "Information Technology", "designation": "Assistant Professor", "phone": "123-456-7910", "office": "IT-106", "specialization": "Web Lab", "experience_years": 6, "qualification": "M.Tech"},
    {"id": "S022", "name": "Dr. Bruce Wayne", "email": "bruce.wayne@example.com", "department": "Computer Science", "designation": "Professor", "phone": "123-456-7911", "office": "CS-201", "specialization": "Database Management Systems", "experience_years": 14, "qualification": "Ph.D."},
    {"id": "S023", "name": "Dr. Clark Kent", "email": "clark.kent@example.com", "department": "Computer Science", "designation": "Associate Professor", "phone": "123-456-7912", "office": "CS-202", "specialization": "Software Engineering", "experience_years": 11, "qualification": "Ph.D."},
    {"id": "S024", "name": "Dr. Diana Prince", "email": "diana.prince@example.com", "department": "Computer Science", "designation": "Professor", "phone": "123-456-7913", "office": "CS-203", "specialization": "Database Systems", "experience_years": 13, "qualification": "Ph.D."},
    {"id": "S025", "name": "Dr. Barry Allen", "email": "barry.allen@example.com", "department": "Computer Science", "designation": "Assistant Professor", "phone": "123-456-7914", "office": "CS-204", "specialization": "Computer Networks", "experience_years": 7, "qualification": "Ph.D."},
    {"id": "S026", "name": "Dr. Arthur Curry", "email": "arthur.curry@example.com", "department": "Computer Science", "designation": "Associate Professor", "phone": "123-456-7915", "office": "CS-205", "specialization": "Operating Systems", "experience_years": 10, "qualification": "Ph.D."},
    {"id": "S027", "name": "Dr. Victor Stone", "email": "victor.stone@example.com", "department": "Computer Science", "designation": "Assistant Professor", "phone": "123-456-7916", "office": "CS-206", "specialization": "Software Engineering", "experience_years": 6, "qualification": "M.Tech"},
    {"id": "S028", "name": "Dr. Tony Stark", "email": "tony.stark@example.com", "department": "Computer Science", "designation": "Professor", "phone": "123-456-7917", "office": "CS-301", "specialization": "Artificial Intelligence", "experience_years": 18, "qualification": "Ph.D."},
    {"id": "S029", "name": "Dr. Bruce Banner", "email": "bruce.banner@example.com", "department": "Computer Science", "designation": "Professor", "phone": "123-456-7918", "office": "CS-302", "specialization": "Machine Learning", "experience_years": 16, "qualification": "Ph.D."},
    {"id": "S030", "name": "Dr. Natasha Romanoff", "email": "natasha.romanoff@example.com", "department": "Computer Science", "designation": "Associate Professor", "phone": "123-456-7919", "office": "CS-303", "specialization": "Cybersecurity", "experience_years": 12, "qualification": "M.Tech"},
    {"id": "S031", "name": "Dr. Stephen Strange", "email": "stephen.strange@example.com", "department": "Information Technology", "designation": "Professor", "phone": "123-456-7920", "office": "IT-201", "specialization": "Artificial Intelligence", "experience_years": 15, "qualification": "Ph.D."},
    {"id": "S032", "name": "Dr. Wanda Maximoff", "email": "wanda.maximoff@example.com", "department": "Information Technology", "designation": "Associate Professor", "phone": "123-456-7921", "office": "IT-202", "specialization": "Machine Learning", "experience_years": 11, "qualification": "Ph.D."},
    {"id": "S033", "name": "Dr. Scott Lang", "email": "scott.lang@example.com", "department": "Information Technology", "designation": "Assistant Professor", "phone": "123-456-7922", "office": "IT-203", "specialization": "Cybersecurity", "experience_years": 8, "qualification": "M.Tech"},
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
        "year": "1st Year",
        "section": "Computer Science - Section A",
        "schedule": {
            "Monday": [("Math", "S006"), ("Physics", "S007"), ("Eng", "S008"), ("Drawing", "S009"), (None, None)],
            "Tuesday": [("Physics", "S007"), ("Math", "S006"), ("Drawing", "S009"), ("Eng", "S008"), (None, None)],
            "Wednesday": [("Eng", "S008"), ("Drawing", "S009"), ("Math", "S006"), ("Physics", "S007"), (None, None)],
            "Thursday": [("Drawing", "S009"), ("Eng", "S008"), ("Physics", "S007"), ("Math", "S006"), (None, None)],
            "Friday": [("Math", "S006"), ("Physics", "S007"), ("Eng", "S008"), ("Lab", "S010"), (None, None)],
        }
    },
    # (Adding more years simplified for the dataloader logic)
    {
        "year": "2nd Year",
        "section": "Computer Science - Section A",
        "schedule": {
            "Monday": [("DSA", "S001"), ("Math", "S013"), ("OOP", "S014"), ("Discrete", "S015"), (None, None)],
            "Tuesday": [("OOP", "S014"), ("DSA", "S001"), ("Discrete", "S015"), ("Math", "S013"), (None, None)],
            "Wednesday": [("Discrete", "S015"), ("OOP", "S014"), ("DSA", "S001"), ("Lab", "S016"), (None, None)],
            "Thursday": [("Math", "S013"), ("Discrete", "S015"), ("OOP", "S014"), ("DSA", "S001"), (None, None)],
            "Friday": [("Lab", "S016"), ("DSA", "S001"), ("OOP", "S014"), ("Math", "S013"), (None, None)],
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
        print("Generating 30 student users...")
        student_users = []
        for i in range(30):
            email = f"student{i+1:03d}@college.edu"
            reg_num = f"20CS{100+i}"
            first = random.choice(STUDENT_FIRST_NAMES)
            last = random.choice(STUDENT_LAST_NAMES)
            user = User(
                email=email,
                hashed_password=test_password_hash,
                full_name=f"{first} {last}",
                role=UserRole.STUDENT,
                is_active=True,
                department="Computer Science" if "CS" in reg_num else "Information Technology"
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
