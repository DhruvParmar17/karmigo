import asyncio
from sqlmodel import select
from app.db.database import get_session
from app.db.models import Order, JobBilling

async def diagnose():
    print("Writing to diagnosis.txt...")
    with open("diagnosis.txt", "w") as f:
        async for session in get_session():
            f.write("--- DIAGNOSTICS START ---\n")
            
            # Check Orders
            f.write("Checking recent orders:\n")
            result = await session.execute(select(Order).order_by(Order.created_at.desc()).limit(10))
            orders = result.scalars().all()
            for o in orders:
                f.write(f"Order ID: {o.id}, Title: {o.title}, Status: {o.order_status}\n")
                f.write(f"  > total_amount: {o.total_amount}\n")
                f.write(f"  > required_labours: {o.required_labours}\n")
                
                # Check Billing
                b_res = await session.execute(select(JobBilling).where(JobBilling.job_id == o.id))
                billing = b_res.scalars().first()
                if billing:
                    f.write(f"  > Billing: total_estimated: {billing.total_estimated_amount}, labour_count: {billing.labour_count}\n")
                else:
                    f.write(f"  > Billing: NONE\n")
                f.write("-" * 20 + "\n")

            f.write("--- DIAGNOSTICS END ---\n")
            break


if __name__ == "__main__":
    asyncio.run(diagnose())
