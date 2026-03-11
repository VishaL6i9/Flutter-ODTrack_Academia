import asyncio
import os
import sys

# Add parent directory to path to import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select
from app.core.database import AsyncSessionLocal as SessionLocal, engine
from app.models.user import User
from app.models.od_request import ODRequest

async def verify_db():
    async with SessionLocal() as db:
        # Check the user
        res_u = await db.execute(select(User).where(User.register_number == "42110565"))
        user = res_u.scalars().first()
        
        if not user:
            print("ERROR: User with register number 42110565 NOT FOUND in database!")
            return
            
        print(f"DIAGNOSTIC_USER: {user.full_name} (ID: {user.id}, Reg: {user.register_number})")
        
        # Test password
        try:
            from app.core.security import verify_password
            is_pwd_ok = verify_password("password123", user.hashed_password)
            print(f"DIAGNOSTIC_PWD: {'PASSED' if is_pwd_ok else 'FAILED'}")
        except Exception as e:
            print(f"DIAGNOSTIC_PWD_ERROR: {str(e)}")
        
        # Check their requests
        res_od = await db.execute(select(ODRequest).where(ODRequest.student_id == user.id))
        requests = res_od.scalars().all()
        
        print(f"Total Requests for this User ID: {len(requests)}")
        for r in requests:
            print(f"- Request ID {r.id}: {r.status} (Reason: {r.reason})")

if __name__ == "__main__":
    asyncio.run(verify_db())
