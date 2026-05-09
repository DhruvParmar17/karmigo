import asyncio
from sqlalchemy import text
from app.db.database import get_session
from app.db.models import Labour
from sqlmodel import select

async def migrate_labour_table():
    print("Starting migration for Labour table...")
    async for session in get_session():
        try:
            # Add new columns if they don't exist
            # PostgreSQL syntax: ALTER TABLE labour ADD COLUMN IF NOT EXISTS ...
            columns = [
                ("aadhaar_number", "VARCHAR"),
                ("aadhaar_photo", "VARCHAR"),
                ("selfie_photo", "VARCHAR"),
                ("address_line1", "VARCHAR"),
                ("address_line2", "VARCHAR"),
                ("city", "VARCHAR"),
                ("state", "VARCHAR"),
                ("zip_code", "VARCHAR"),
                ("emergency_contact_name", "VARCHAR"),
                ("emergency_contact_number", "VARCHAR"),
                ("bank_account_number", "VARCHAR"),
                ("ifsc_code", "VARCHAR"),
                ("upi_id", "VARCHAR"),
                ("pan_number", "VARCHAR"),
                ("verification_status", "VARCHAR DEFAULT 'unsubmitted'"),
                ("rejection_reason", "VARCHAR"),
            ]

            for col_name, col_type in columns:
                try:
                    query = text(f"ALTER TABLE labour ADD COLUMN IF NOT EXISTS {col_name} {col_type}")
                    await session.execute(query)
                    print(f"Added column {col_name}")
                except Exception as e:
                    print(f"Error adding column {col_name}: {e}")

            await session.commit()
            print("Migration completed successfully.")
            return

        except Exception as e:
            print(f"Migration failed: {e}")
            await session.rollback()

if __name__ == "__main__":
    asyncio.run(migrate_labour_table())
