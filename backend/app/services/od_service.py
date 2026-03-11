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
            .options(
                selectinload(ODRequest.student), 
                selectinload(ODRequest.approved_by),
                selectinload(ODRequest.staff)
            )
            .where(ODRequest.id == id)
        )
        return result.scalars().first()

    async def get_multi_by_student(self, db: AsyncSession, student_id: int, skip: int = 0, limit: int = 100) -> list[ODRequest]:
        result = await db.execute(
            select(ODRequest)
            .options(
                selectinload(ODRequest.student), 
                selectinload(ODRequest.approved_by),
                selectinload(ODRequest.staff)
            )
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
            .options(
                selectinload(ODRequest.student), 
                selectinload(ODRequest.approved_by),
                selectinload(ODRequest.staff)
            )
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
        
        # Re-fetch with all relationships loaded to avoid async serialization errors
        db_obj = await self.get(db, db_obj.id)
        
        if db_obj and db_obj.student:
            student_obj = db_obj.student
            
            # Get appropriate staff to notify
            staff_query = await db.execute(select(User).where(User.role.in_([UserRole.STAFF, UserRole.ADMIN, UserRole.SUPERUSER])))
            staff_list = staff_query.scalars().all()
            
            try:
                await email_service.send_od_submission_email(student=student_obj, od_request=db_obj, staff=staff_list)
            except Exception as e:
                pass  # Notification failure should not fail the request
             
            for staff_member in staff_list:
                if staff_member.fcm_token:
                    try:
                        await fcm_service.send_notification(
                            token=staff_member.fcm_token,
                            title="New OD Request Submitted",
                            body=f"{student_obj.full_name} ({db_obj.register_number}) submitted an OD request for {db_obj.date.strftime('%Y-%m-%d') if db_obj.date else 'N/A'}.",
                            data={"type": "new_request", "id": str(db_obj.id)}
                        )
                    except Exception as e:
                        pass  # Notification failure should not fail the request
        
        return db_obj

    async def update(
        self, db: AsyncSession, *, db_obj: ODRequest, obj_in: ODRequestUpdate
    ) -> ODRequest:
        update_data = obj_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_obj, field, value)
            
        db.add(db_obj)
        await db.commit()
        return await self.get(db, db_obj.id)

    async def update_status(
        self, db: AsyncSession, db_obj: ODRequest, obj_in: ODRequestUpdate, approver_id: int
    ) -> ODRequest:
        update_data = obj_in.model_dump(exclude_unset=True)
        # Assuming status is passed as Enum in update_data
        if update_data.get("status") in [ODStatus.APPROVED, ODStatus.REJECTED]:
            db_obj.approved_by_id = approver_id
            db_obj.approved_at = datetime.now(timezone.utc)
        
        db_obj = await self.update(db=db, db_obj=db_obj, obj_in=obj_in)
        
        # Reload relation if needed for notifications
        full_obj = await self.get(db, db_obj.id)
        
        if full_obj and full_obj.student:
            try:
                await email_service.send_od_status_update_email(student=full_obj.student, od_request=full_obj)
            except Exception as e:
                pass  # Notification failure should not fail the status update
            
            if full_obj.student.fcm_token:
                try:
                    status_str = "Approved" if full_obj.status == ODStatus.APPROVED else "Rejected"
                    await fcm_service.send_notification(
                        token=full_obj.student.fcm_token,
                        title=f"OD Request {status_str}",
                        body=f"Your On-Duty request from {full_obj.date.strftime('%Y-%m-%d') if full_obj.date else 'N/A'} has been {status_str.lower()}.",
                        data={"type": "status_update", "id": str(full_obj.id)}
                    )
                except Exception as e:
                    pass  # Notification failure should not fail the status update
            
        return db_obj

    async def get_all(self, db: AsyncSession, skip: int = 0, limit: int = 100) -> list[ODRequest]:
        # For analytics/reports
        result = await db.execute(
            select(ODRequest)
            .options(
                selectinload(ODRequest.student), 
                selectinload(ODRequest.approved_by),
                selectinload(ODRequest.staff)
            )
            .offset(skip)
            .limit(limit)
            .order_by(ODRequest.created_at.desc())
        )
        return result.scalars().all()

    async def get_stats_by_student(self, db: AsyncSession, student_id: int) -> dict:
        """Get OD request counts grouped by status for a specific student."""
        from sqlalchemy import func
        result = await db.execute(
            select(ODRequest.status, func.count(ODRequest.id).label("count"))
            .where(ODRequest.student_id == student_id)
            .group_by(ODRequest.status)
        )
        rows = result.all()
        counts = {"pending": 0, "approved": 0, "rejected": 0}
        for row in rows:
            counts[row.status.value] = row.count
        counts["total"] = sum(counts.values())
        return counts

    async def get_stats_for_staff(self, db: AsyncSession, staff_id: int) -> dict:
        """Get OD request counts grouped by status for requests assigned to a staff member."""
        from sqlalchemy import func
        result = await db.execute(
            select(ODRequest.status, func.count(ODRequest.id).label("count"))
            .where(ODRequest.staff_id == staff_id)
            .group_by(ODRequest.status)
        )
        rows = result.all()
        counts = {"pending": 0, "approved": 0, "rejected": 0}
        for row in rows:
            counts[row.status.value] = row.count
        counts["total"] = sum(counts.values())
        return counts

od_service = ODService()
