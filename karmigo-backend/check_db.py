import asyncio
from sqlmodel import select, func
from app.db.database import async_session
from app.db.models import User, Labour, Order, JobBilling, JobAssignment

async def check_db_counts():
    async with async_session() as session:
        user_count = (await session.execute(select(func.count(User.id)))).scalar()
        labour_count = (await session.execute(select(func.count(Labour.id)))).scalar()
        order_count = (await session.execute(select(func.count(Order.id)))).scalar()
        billing_count = (await session.execute(select(func.count(JobBilling.id)))).scalar()
        assignment_count = (await session.execute(select(func.count(JobAssignment.id)))).scalar()
        
        paid_billing_count = (await session.execute(select(func.count(JobBilling.id)).where(JobBilling.payment_status == 'paid'))).scalar()
        verified_labour_count = (await session.execute(select(func.count(Labour.id)).where(Labour.is_verified == True))).scalar()

        print(f"Users: {user_count}")
        print(f"Labour: {labour_count} (Verified: {verified_labour_count})")
        print(f"Orders: {order_count}")
        print(f"Billing: {billing_count} (Paid: {paid_billing_count})")
        print(f"Assignments: {assignment_count}")

if __name__ == "__main__":
    asyncio.run(check_db_counts())
