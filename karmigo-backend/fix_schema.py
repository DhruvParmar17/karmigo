import asyncio
from app.db.database import engine
from sqlmodel import text, SQLModel
# Import models to register them
from app.db.models import JobBilling 

async def fix():
    print("Starting Schema Reset for JobBilling...")
    async with engine.begin() as conn:
        print("Dropping job_billing Table...")
        try:
             await conn.execute(text("DROP TABLE IF EXISTS job_billing CASCADE;"))
        except Exception as e:
            print(f"Drop failed: {e}")
        
        print("Re-creating Tables from Models...")
        await conn.run_sync(SQLModel.metadata.create_all)
    print("Schema Reset Complete.")

if __name__ == "__main__":
    asyncio.run(fix())
