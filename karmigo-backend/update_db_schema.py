import asyncio
import logging
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.db.database import DATABASE_URL

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def add_columns():
    logger.info(f"Connecting to DB: {DATABASE_URL}")
    engine = create_async_engine(DATABASE_URL, echo=True)

    async with engine.begin() as conn:
        logger.info("Checking for 'latitude' column in 'orders' table...")
        # Check if column exists
        try:
            await conn.execute(text("SELECT latitude FROM orders LIMIT 1"))
            logger.info("'latitude' column already exists.")
        except Exception:
            logger.info("Adding 'latitude' column...")
            await conn.execute(text("ALTER TABLE orders ADD COLUMN latitude FLOAT DEFAULT NULL"))
            logger.info("Added 'latitude'.")

        logger.info("Checking for 'longitude' column in 'orders' table...")
        try:
            await conn.execute(text("SELECT longitude FROM orders LIMIT 1"))
            logger.info("'longitude' column already exists.")
        except Exception:
            logger.info("Adding 'longitude' column...")
            await conn.execute(text("ALTER TABLE orders ADD COLUMN longitude FLOAT DEFAULT NULL"))
            logger.info("Added 'longitude'.")

    await engine.dispose()
    logger.info("Schema update complete.")

if __name__ == "__main__":
    import platform
    if platform.system() == 'Windows':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(add_columns())
