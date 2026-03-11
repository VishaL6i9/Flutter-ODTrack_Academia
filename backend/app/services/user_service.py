from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.models.user import User
from app.schemas.user import UserCreate
from app.core.security import get_password_hash, verify_password

class UserService:
    async def get_by_email(self, db: AsyncSession, email: str) -> User | None:
        result = await db.execute(select(User).where(User.email == email))
        return result.scalars().first()

    async def get_by_register_number(self, db: AsyncSession, reg_num: str) -> User | None:
        result = await db.execute(select(User).where(User.register_number == reg_num))
        return result.scalars().first()

    async def get(self, db: AsyncSession, id: int) -> User | None:
        result = await db.execute(select(User).where(User.id == id))
        return result.scalars().first()

    async def authenticate(self, db: AsyncSession, email: str, password: str) -> User | None:
        # Check by email first
        user = await self.get_by_email(db, email)
        
        # If not found, check by register number
        if not user:
            user = await self.get_by_register_number(db, email)
            
        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user

    async def create(self, db: AsyncSession, user_in: UserCreate) -> User:
        db_user = User(
            email=user_in.email,
            hashed_password=get_password_hash(user_in.password),
            full_name=user_in.full_name,
            role=user_in.role,
            is_active=user_in.is_active,
            register_number=user_in.register_number,
            year=user_in.year,
            section=user_in.section,
            department=user_in.department,
            designation=user_in.designation,
            phone=user_in.phone,
        )
        db.add(db_user)
        await db.commit()
        await db.refresh(db_user)
        return db_user

    async def update_signature(self, db: AsyncSession, user_obj: User, signature_url: str) -> User:
        user_obj.signature_url = signature_url
        db.add(user_obj)
        await db.commit()
        await db.refresh(user_obj)
        return user_obj

    async def update_fcm_token(self, db: AsyncSession, user_obj: User, fcm_token: str) -> User:
        user_obj.fcm_token = fcm_token
        db.add(user_obj)
        await db.commit()
        await db.refresh(user_obj)
        return user_obj

user_service = UserService()
