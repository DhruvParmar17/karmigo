import asyncio
import os
import sys

# Add current directory to path so imports work
sys.path.append(os.getcwd())

from app.db.database import init_db, close_db
from app.db import models # Ensure models are loaded

async def main():
    print("Creating tables...")
    try:
        await init_db()
        print("Tables created successfully.")
    except Exception as e:
        print(f"Error creating tables: {e}")
    finally:
        await close_db()

if __name__ == "__main__":
    if sys.platform == 'win32':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(main())
