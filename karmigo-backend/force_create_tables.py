import asyncio
from app.db.database import engine
# Import all models to ensure they are registered with SQLModel.metadata
from app.db.models import User, Labour, Product, Order, OrderItem, JobBilling, LabourWalletTransaction
from sqlmodel import SQLModel

async def init_db():
    print("Creating tables...")
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    print("Tables created successfully.")

if __name__ == "__main__":
    asyncio.run(init_db())
