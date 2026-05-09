import asyncio
from sqlmodel import select
from app.db.database import async_session
from app.db.models import User

async def make_admin():
    async with async_session() as session:
        # Target common developer emails
        emails = ["dhurvparmar8@gmail.com", "dhruvparmar8@gmail.com", "admin@karmigo.com"]
        result = await session.execute(select(User).where(User.email.in_(emails)))
        users = result.scalars().all()
        
        if not users:
            # If specified users don't exist, list all users to see what's available
            print("No matching users found for admin elevation. Trying to find any user.")
            result = await session.execute(select(User).limit(5))
            users = result.scalars().all()
            
        for u in users:
            u.is_superuser = True
            session.add(u)
            print(f"Set {u.email} as Superuser")
            
        await session.commit()

if __name__ == "__main__":
    asyncio.run(make_admin())
