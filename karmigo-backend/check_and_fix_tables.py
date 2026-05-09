
import asyncio
import logging
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.db.database import DATABASE_URL
from app.db.models import SQLModel
# Import all models to ensure they are registered
from app.db import models 

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def check_and_create_tables():
    logger.info(f"Connecting to DB: {DATABASE_URL}")
    engine = create_async_engine(DATABASE_URL, echo=True)

    async with engine.begin() as conn:
        logger.info("Checking if 'job_billing' table exists...")
        try:
            await conn.execute(text("SELECT 1 FROM job_billing LIMIT 1"))
            logger.info("'job_billing' table exists.")
        except Exception as e:
            logger.info(f"Table check failed (likely missing): {e}")
            logger.info("Re-running create_all to create missing tables...")
            await conn.run_sync(SQLModel.metadata.create_all)
            logger.info("create_all executed.")

    await engine.dispose()
    logger.info("Check complete.")

if __name__ == "__main__":
    import platform
    if platform.system() == 'Windows':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(check_and_create_tables())
