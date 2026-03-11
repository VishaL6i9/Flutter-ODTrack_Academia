import asyncio
from sqlalchemy import select, func
from app.core.database import AsyncSessionLocal
from app.models.user import User
from app.models.od_request import ODRequest

async def verify_data():
    async with AsyncSessionLocal() as db:
        # Count users
        result = await db.execute(select(func.count(User.id)))
        user_count = result.scalar()
        
        # Count OD requests
        result = await db.execute(select(func.count(ODRequest.id)))
        od_count = result.scalar()
        
        # Count Subjects
        result = await db.execute(select(func.count(Subject.id)))
        subj_count = result.scalar()
        
        # Count Timetables
        result = await db.execute(select(func.count(Timetable.id)))
        tt_count = result.scalar()
        
        print(f"Total Users: {user_count}")
        print(f"Total OD Requests: {od_count}")
        print(f"Total Subjects: {subj_count}")
        print(f"Total Timetable Entries: {tt_count}")
        
        # List some users
        result = await db.execute(select(User).limit(5))
        users = result.scalars().all()
        print("\nSample Users:")
        for u in users:
            print(f"- {u.full_name} ({u.role})")
            
if __name__ == "__main__":
    asyncio.run(verify_data())
