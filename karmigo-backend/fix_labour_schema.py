
import asyncio
import logging
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.db.database import DATABASE_URL

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def fix_labour_schema():
    logger.info(f"Connecting to DB: {DATABASE_URL}")
    engine = create_async_engine(DATABASE_URL, echo=True)

    async with engine.begin() as conn:
        logger.info("Checking for 'wallet_balance' column in 'labour' table...")
        try:
            # Try selecting the column to see if it exists
            await conn.execute(text("SELECT wallet_balance FROM labour LIMIT 1"))
            logger.info("'wallet_balance' column already exists.")
        except Exception:
            # If it fails, likely column is missing. Note: This might rollback the transaction block.
            # So we perform the alter in a separate block or relying on clean start.
            logger.info("Column likely missing (captured exception).")
            
    # Re-connect to apply changes if needed (to avoid aborted transaction issues)
    async with engine.begin() as conn:
        try:
            logger.info("Attempting to add 'wallet_balance' column...")
            await conn.execute(text("ALTER TABLE labour ADD COLUMN IF NOT EXISTS wallet_balance FLOAT DEFAULT 0.0"))
            logger.info("Successfully added (or ensured) 'wallet_balance' column.")
        except Exception as e:
            logger.error(f"Error adding column: {e}")

    await engine.dispose()
    logger.info("Schema fix complete.")

if __name__ == "__main__":
    import platform
    if platform.system() == 'Windows':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(fix_labour_schema())
