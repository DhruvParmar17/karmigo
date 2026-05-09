from app.db.database import get_session
from app.db.models import JobBilling
from sqlmodel import select
import asyncio
import uuid


from sqlalchemy import inspect, text
import logging

# Disable SQLAlchemy INFO logs
logging.basicConfig()
logging.getLogger('sqlalchemy.engine').setLevel(logging.ERROR)

async def debug():
    print("Starting Debug...", flush=True)
    gen = get_session()
    session = await anext(gen)
    
    # Check if table exists and list columns
    try:
        def get_columns(connection):
            inspector = inspect(connection)
            if inspector.has_table("job_billing"):
                print("Table 'job_billing' exists.")
                for col in inspector.get_columns("job_billing"):
                    print(f" - {col['name']} ({col['type']})")
            else:
                print("Table 'job_billing' DOES NOT EXIST.")
        
        await session.connection(execution_options={"isolation_level": "AUTOCOMMIT"})
        await session.run_sync(get_columns)
        
    except Exception as e:
        print(f"SCHEMA_CHECK_ERROR: {e}")

    job_id_str = "4ff9510c-6af0-4f7d-8053-4e46911fa26d"
    job_id = uuid.UUID(job_id_str)
    print(f"Querying for {job_id}")
    try:
        stmt = select(JobBilling).where(JobBilling.job_id == job_id)
        res = await session.execute(stmt)
        print("Result:", res.scalars().first())
    except Exception as e:
        print(f"QUERY_ERROR: {e}")
        # print type
        print(f"Error Type: {type(e)}")
    finally:
        await session.close()

if __name__ == "__main__":
    asyncio.run(debug())
