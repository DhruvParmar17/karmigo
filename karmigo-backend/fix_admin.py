import asyncio
import logging
from sqlalchemy.future import select
from app.db.database import async_session
from app.db.models import User

# Squelch SQL logs
logging.getLogger('sqlalchemy.engine').setLevel(logging.WARNING)

async def fix_admin(email: str):
    print(f"fixing admin for: {email}")
    async with async_session() as session:
        query = select(User).where(User.email == email)
        result = await session.execute(query)
        user = result.scalar_one_or_none()
        
        if user:
            print(f"User Found: {user.email}")
            print(f"Current Superuser Status: {user.is_superuser}")
            
            if not user.is_superuser:
                print("Promoting to Superuser...")
                user.is_superuser = True
                session.add(user)
                await session.commit()
                print("Promoted.")
            else:
                print("User is already Superuser.")
                
            # Double check
            await session.refresh(user)
            print(f"Final Superuser Status: {user.is_superuser}")
        else:
            print(f"❌ User {email} not found.")

if __name__ == "__main__":
    asyncio.run(fix_admin("1234@gmail.com"))
