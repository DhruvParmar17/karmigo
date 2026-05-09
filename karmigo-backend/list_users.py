import asyncio
from sqlmodel import select
from app.db.database import async_session
from app.db.models import User

async def list_users():
    async with async_session() as session:
        result = await session.execute(select(User))
        users = result.scalars().all()
        for u in users:
            print(f"User: {u.email} (Is Superuser: {u.is_superuser})")

if __name__ == "__main__":
    asyncio.run(list_users())
