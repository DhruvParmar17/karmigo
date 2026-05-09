import asyncio
from sqlmodel import select
from app.db.database import async_session
from app.db.models import User

async def check_admin_exists():
    async with async_session() as session:
        result = await session.execute(select(User).where(User.is_superuser == True))
        admins = result.scalars().all()
        print(f"Total Admins: {len(admins)}")
        for admin in admins:
            print(f"Admin: {admin.email} (ID: {admin.id})")

if __name__ == "__main__":
    asyncio.run(check_admin_exists())
