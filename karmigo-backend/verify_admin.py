import asyncio
from sqlalchemy.future import select
from app.db.database import async_session
from app.db.models import User, Labour

async def verify_user(email: str):
    print(f"Checking user: {email}")
    async with async_session() as session:
        # Check User
        query = select(User).where(User.email == email)
        result = await session.execute(query)
        user = result.scalar_one_or_none()
        
        if user:
            print(f"User Found: ID={user.id}")
            print(f"is_superuser: {user.is_superuser}")
            print(f"is_active: {user.is_active}")
            
            # Check Labour
            l_query = select(Labour).where(Labour.email == email)
            l_result = await session.execute(l_query)
            labour = l_result.scalar_one_or_none()
            if labour:
                print(f"User is ALSO a Labour: ID={labour.id}")
            else:
                print("User is NOT a Labour")
        else:
            print(f"❌ User {email} not found in DB.")

if __name__ == "__main__":
    asyncio.run(verify_user("1234@gmail.com"))
