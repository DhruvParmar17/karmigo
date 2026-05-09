import asyncio
from sqlmodel import select
from app.db.database import get_session
from app.db.models import Order, JobBilling

async def sync_data():
    print("Starting Sync...")
    async for session in get_session():
        # Get all orders
        result = await session.execute(select(Order))
        orders = result.scalars().all()
        
        updated_count = 0
        
        for o in orders:
            # Check Billing
            b_res = await session.execute(select(JobBilling).where(JobBilling.job_id == o.id))
            billing = b_res.scalars().first()
            
            if billing:
                needs_update = False
                
                # Update Total Amount if 0
                if not o.total_amount or o.total_amount == 0:
                    if billing.total_estimated_amount > 0:
                        o.total_amount = billing.total_estimated_amount
                        needs_update = True
                        
                # Update Required Labours if 1 (default) and billing has more
                # OR just trust billing if it exists? 
                # Let's say if billing > 1, update it. 
                # If billing is 1 and order is 1, no change.
                if billing.labour_count and billing.labour_count > 0:
                     if o.required_labours != billing.labour_count:
                        o.required_labours = billing.labour_count
                        needs_update = True
                
                if needs_update:
                    session.add(o)
                    updated_count += 1
                    print(f"Updating Order {o.id}: Amount {o.total_amount}, Labours {o.required_labours}")

        await session.commit()
        print(f"Sync Complete. Updated {updated_count} orders.")
        break

if __name__ == "__main__":
    asyncio.run(sync_data())
