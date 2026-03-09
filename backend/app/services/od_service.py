from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from app.models.od_request import ODRequest
from app.models.user import User
from app.schemas.od_request import ODRequestCreate, ODRequestUpdate
from datetime import datetime, timezone
from app.core.enums import ODStatus
from app.services.email_service import email_service
from app.services.fcm_service import fcm_service
from app.core.enums import UserRole

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
            .options(selectinload(ODRequest.student), selectinload(ODRequest.approved_by))
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
            .options(selectinload(ODRequest.student), selectinload(ODRequest.approved_by))
            .where(ODRequest.status == ODStatus.PENDING)
            .offset(skip)
            .limit(limit)
            .order_by(ODRequest.created_at.desc())
        )
        return result.scalars().all()

    async def create(self, db: AsyncSession, obj_in: ODRequestCreate, student_id: int) -> ODRequest:
        db_obj = ODRequest(
            **obj_in.model_dump(),
            student_id=student_id,
            status=ODStatus.PENDING
        )
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        
        # Load the student to get the name/details for email
        student = await db.execute(select(User).where(User.id == student_id))
        student_obj = student.scalars().first()
        
        # Get appropriate staff to notify (simplification: all staff/admins, this should be scoped in prod to coordinators/mentors)
        staff_query = await db.execute(select(User).where(User.role.in_([UserRole.STAFF, UserRole.ADMIN, UserRole.SUPERUSER])))
        staff_list = staff_query.scalars().all()
        
        if student_obj:
             await email_service.send_od_submission_email(student=student_obj, od_request=db_obj, staff=staff_list)
             
             for staff_member in staff_list:
                 if staff_member.fcm_token:
                     await fcm_service.send_notification(
                         token=staff_member.fcm_token,
                         title="New OD Request Submitted",
                         body=f"{student_obj.name} ({student_obj.register_number}) submitted an OD request for {db_obj.from_date.strftime('%Y-%m-%d')}.",
                         data={"type": "new_request", "id": str(db_obj.id)}
                     )
        
        return db_obj

    async def update_status(
        self, db: AsyncSession, db_obj: ODRequest, obj_in: ODRequestUpdate, approver_id: int
    ) -> ODRequest:
        update_data = obj_in.model_dump(exclude_unset=True)
        # Assuming status is passed as Enum in update_data
        if update_data.get("status") in [ODStatus.APPROVED, ODStatus.REJECTED]:
            db_obj.approved_by_id = approver_id
            db_obj.approved_at = datetime.now(timezone.utc)
        
        for field, value in update_data.items():
            setattr(db_obj, field, value)
            
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        
        # Reload relation if needed
        full_obj_result = await db.execute(select(ODRequest).options(selectinload(ODRequest.student)).where(ODRequest.id == db_obj.id))
        full_obj = full_obj_result.scalars().first()
        
        if full_obj.student:
            await email_service.send_od_status_update_email(student=full_obj.student, od_request=full_obj)
            
            if full_obj.student.fcm_token:
                status_str = "Approved" if full_obj.status == ODStatus.APPROVED else "Rejected"
                await fcm_service.send_notification(
                    token=full_obj.student.fcm_token,
                    title=f"OD Request {status_str}",
                    body=f"Your On-Duty request from {full_obj.from_date.strftime('%Y-%m-%d')} has been {status_str.lower()}.",
                    data={"type": "status_update", "id": str(full_obj.id)}
                )
            
        return db_obj

    async def get_all(self, db: AsyncSession, skip: int = 0, limit: int = 100) -> list[ODRequest]:
        # For analytics/reports
        result = await db.execute(
            select(ODRequest)
            .options(selectinload(ODRequest.student), selectinload(ODRequest.approved_by))
            .offset(skip)
            .limit(limit)
            .order_by(ODRequest.created_at.desc())
        )
        return result.scalars().all()

od_service = ODService()
