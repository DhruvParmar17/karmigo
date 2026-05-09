
import asyncio
from sqlalchemy import text
from app.db.database import get_session, engine

async def add_column():
    async with engine.begin() as conn:
        try:
            await conn.execute(text("ALTER TABLE labour ADD COLUMN is_verified BOOLEAN DEFAULT FALSE"))
            print("Added column is_verified")
        except Exception as e:
            print(f"Column might already exist or error: {e}")

if __name__ == "__main__":
    asyncio.run(add_column())
