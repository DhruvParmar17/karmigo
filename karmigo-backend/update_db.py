
import asyncio
from sqlalchemy import text
from app.db.database import get_session

async def apply_migration():
    print("Starting Schema Update...")
    async for session in get_session():
        # List of new columns to add to 'job_billing'
        # hours_requested, house_size, special_items_count, service_charge_type
        # service_charge_estimate, special_items_charge_estimate, house_size_charge, distance_charge_estimate
        # gst_amount, platform_fee, per_labour_earning
        
        # Breakdown finals
        # service_charge_final, special_items_charge_final, house_size_charge_final, gst_amount_final, platform_fee_final, per_labour_earning_final
        
        columns = [
            # Inputs
            ("hours_requested", "FLOAT DEFAULT 1.0"),
            ("house_size", "VARCHAR DEFAULT '1RK'"),
            ("special_items_count", "INTEGER DEFAULT 0"),
            ("service_charge_type", "VARCHAR DEFAULT 'normal'"),
            ("service_type_charge", "FLOAT DEFAULT 0.0"),
            
            # Estimates
            ("service_charge_estimate", "FLOAT DEFAULT 0.0"),
            ("special_items_charge_estimate", "FLOAT DEFAULT 0.0"),
            ("house_size_charge", "FLOAT DEFAULT 0.0"),
            ("distance_charge_estimate", "FLOAT DEFAULT 0.0"),
            ("gst_amount", "FLOAT DEFAULT 0.0"),
            ("platform_fee", "FLOAT DEFAULT 0.0"),
            ("per_labour_earning", "FLOAT DEFAULT 0.0"),
            
            # Finals
            ("service_charge_final", "FLOAT DEFAULT 0.0"),
            ("special_items_charge_final", "FLOAT DEFAULT 0.0"),
            ("house_size_charge_final", "FLOAT DEFAULT 0.0"),
            ("gst_amount_final", "FLOAT DEFAULT 0.0"),
            ("platform_fee_final", "FLOAT DEFAULT 0.0"),
            ("per_labour_earning_final", "FLOAT DEFAULT 0.0"),
            
            # Legacy/Aliased
            # walking_charges_estimate usually exists? Check model.
        ]
        
        for col, dtype in columns:
            try:
                print(f"Adding column {col}...")
                await session.execute(text(f"ALTER TABLE job_billing ADD COLUMN IF NOT EXISTS {col} {dtype}"))
            except Exception as e:
                print(f"Error adding {col}: {e}")
                
        await session.commit()
        print("Schema Update Complete.")
        break

if __name__ == "__main__":
    asyncio.run(apply_migration())
