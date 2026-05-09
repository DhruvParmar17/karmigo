
import asyncio
import logging
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.db.database import DATABASE_URL

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def update_schema():
    logger.info(f"Connecting to DB: {DATABASE_URL}")
    engine = create_async_engine(DATABASE_URL, echo=True)

    async with engine.begin() as conn:
        logger.info("Updating 'job_billing' table schema...")
        
        # List of new columns to add if they don't exist
        # col_name: type definition
        new_columns = {
            "labour_count": "INTEGER DEFAULT 1",
            "base_price": "FLOAT DEFAULT 0.0",
            "labour_cost_time_estimate": "FLOAT DEFAULT 0.0",
            "floor_charges_estimate": "FLOAT DEFAULT 0.0",
            "walking_charges_estimate": "FLOAT DEFAULT 0.0",
            "heavy_item_charges": "FLOAT DEFAULT 0.0",
            "total_estimated_amount": "FLOAT DEFAULT 0.0",
            
            "actual_duration_minutes": "INTEGER DEFAULT 0",
            "waiting_time_minutes": "INTEGER DEFAULT 0",
            "labour_cost_time_final": "FLOAT DEFAULT 0.0",
            "waiting_charges_final": "FLOAT DEFAULT 0.0",
            "floor_charges_final": "FLOAT DEFAULT 0.0",
            "walking_charges_final": "FLOAT DEFAULT 0.0",
            "total_final_amount": "FLOAT DEFAULT 0.0",
            "is_locked": "BOOLEAN DEFAULT FALSE"
        }

        for col, col_type in new_columns.items():
            try:
                await conn.execute(text(f"SELECT {col} FROM job_billing LIMIT 1"))
                logger.info(f"'{col}' column already exists.")
            except Exception:
                logger.info(f"Adding '{col}' column...")
                # We need to use a separate transaction or ensure the previous failed select doesn't block (?)
                # In sqlalchemy async begin(), the transaction might be invalid after error? 
                # Actually, usually 'except' catches it but the transaction might be rolled back.
                # It's safer to restart transaction or ignore error if the command allows.
                # But PG usually aborts transaction on error.
                pass
        
    # Re-connect for ALTERS since previous transaction might be aborted due to exceptions
    # A cleaner way is to check information_schema, but let's try a brute force "ADD COLUMN IF NOT EXISTS" approach if supported 
    # OR just try to add and catch error.
    # Postgres doesn't support "ADD COLUMN IF NOT EXISTS" in older versions? 
    # It does in 9.6+.
    
    async with engine.begin() as conn:
        for col, col_type in new_columns.items():
             try:
                 await conn.execute(text(f"ALTER TABLE job_billing ADD COLUMN IF NOT EXISTS {col} {col_type}"))
                 logger.info(f"Ensured column '{col}' exists.")
             except Exception as e:
                 logger.error(f"Error adding {col}: {e}")

    # Create labour_wallet_transactions table
    # Since we can rely on SQLModel.metadata.create_all for new tables if we run it,
    # or we can manually create it here.
    # Let's manually create it to be sure.
    async with engine.begin() as conn:
        logger.info("Creating 'labour_wallet_transactions' table if not exists...")
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS labour_wallet_transactions (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                labour_id UUID NOT NULL,
                job_id UUID,
                amount FLOAT NOT NULL,
                description VARCHAR,
                transaction_type VARCHAR DEFAULT 'credit',
                created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT (now() at time zone 'utc'),
                FOREIGN KEY (labour_id) REFERENCES labour(id),
                FOREIGN KEY (job_id) REFERENCES orders(id)
            )
        """))
        logger.info("Table 'labour_wallet_transactions' checked/created.")

    await engine.dispose()
    logger.info("Schema update complete.")

if __name__ == "__main__":
    import platform
    if platform.system() == 'Windows':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(update_schema())
