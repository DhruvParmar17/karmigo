import asyncio
from sqlmodel import select
from app.db.database import async_session
from app.db.models import User

async def make_everyone_admin():
    async with async_session() as session:
        result = await session.execute(select(User))
        users = result.scalars().all()
        
        for u in users:
            u.is_superuser = True
            session.add(u)
            print(f"Set {u.email} as Superuser")
            
        await session.commit()
        print(f"Total {len(users)} users are now admins.")

if __name__ == "__main__":
    asyncio.run(make_everyone_admin())
