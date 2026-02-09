from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from app.models.od_request import ODRequest
from app.models.user import User
from app.schemas.od_request import ODRequestCreate, ODRequestUpdate
from datetime import datetime, timezone

class ODService:
    async def get(self, db: AsyncSession, id: int) -> ODRequest | None:
        result = await db.execute(
            select(ODRequest)
            .options(selectinload(ODRequest.student), selectinload(ODRequest.approved_by))
            .where(ODRequest.id == id)
        )
        return result.scalars().first()

    async def get_multi_by_student(self, db: AsyncSession, student_id: int, skip: int = 0, limit: int = 100) -> list[ODRequest]:
        result = await db.execute(
            select(ODRequest)
            .where(ODRequest.student_id == student_id)
            .offset(skip)
            .limit(limit)
            .order_by(ODRequest.created_at.desc())
        )
        return result.scalars().all()
    
    async def get_all_pending(self, db: AsyncSession, skip: int = 0, limit: int = 100) -> list[ODRequest]:
        # For staff/admin to review
        result = await db.execute(
            select(ODRequest)
            .options(selectinload(ODRequest.student))
            .where(ODRequest.status == "pending")
            .offset(skip)
            .limit(limit)
            .order_by(ODRequest.created_at.desc())
        )
        return result.scalars().all()

    async def get_all(self, db: AsyncSession, skip: int = 0, limit: int = 100) -> list[ODRequest]:
        # For analytics/reports
        result = await db.execute(
            select(ODRequest)
            .options(selectinload(ODRequest.student))
            .offset(skip)
            .limit(limit)
            .order_by(ODRequest.created_at.desc())
        )
        return result.scalars().all()

    async def create(self, db: AsyncSession, obj_in: ODRequestCreate, student_id: int) -> ODRequest:
        db_obj = ODRequest(
            **obj_in.model_dump(),
            student_id=student_id,
            status="pending"
        )
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        return db_obj

    async def update_status(
        self, db: AsyncSession, db_obj: ODRequest, obj_in: ODRequestUpdate, approver_id: int
    ) -> ODRequest:
        update_data = obj_in.model_dump(exclude_unset=True)
        if update_data.get("status") in ["approved", "rejected"]:
            db_obj.approved_by_id = approver_id
            db_obj.approved_at = datetime.now(timezone.utc)
        
        for field, value in update_data.items():
            setattr(db_obj, field, value)
            
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        return db_obj

od_service = ODService()
