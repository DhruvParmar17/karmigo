
import asyncio
import logging
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.db.database import DATABASE_URL
from app.db.models import User, Labour
from sqlmodel import select

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

EMAIL = "sansritidubey49@gmail.com"

async def manual_fix():
    logger.info(f"Connecting to DB: {DATABASE_URL}")
    engine = create_async_engine(DATABASE_URL, echo=True)

    async with engine.begin() as conn:
        # 1. Get User
        result = await conn.execute(text(f"SELECT * FROM users WHERE email = '{EMAIL}'"))
        user = result.fetchone()
        
        if not user:
            logger.error("User not found!")
            return

        logger.info(f"Found user: {user.email} {user.id}")

        # 2. Check Labour
        result = await conn.execute(text(f"SELECT * FROM labour WHERE email = '{EMAIL}'"))
        labour = result.fetchone()
        
        if labour:
            logger.info(f"Labour record exists: {labour.id}")
            # Ensure wallet_balance is not null?
            # It might be None if created before.
            # await conn.execute(text(f"UPDATE labour SET wallet_balance = 0.0 WHERE email = '{EMAIL}' AND wallet_balance IS NULL"))
        else:
            logger.info("Creating Labour record manually...")
            # Insert
            await conn.execute(text(f"""
                INSERT INTO labour (id, full_name, email, phone, wallet_balance, created_at)
                VALUES (gen_random_uuid(), '{user.full_name or "Labour"}', '{user.email}', '{user.phone}', 0.0, now())
            """))
            logger.info("Created Labour record.")

    await engine.dispose()

if __name__ == "__main__":
    import platform
    if platform.system() == 'Windows':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(manual_fix())
