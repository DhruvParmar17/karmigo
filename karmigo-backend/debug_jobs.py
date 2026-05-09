import asyncio
import sys
import os
from sqlmodel import select, func

sys.path.append(os.getcwd())

from app.db.database import get_session
from app.db.models import Order, JobBilling, JobAssignment

# Copied from app/api/jobs.py to avoid importing deps that might fail locally
def calculate_job_payment_details(job: Order, billing: JobBilling, filled_count: int):
    # 1. Total Amount
    # Prefer Billing Estimate if Order amount is not finalized or 0
    total = job.total_amount if job.total_amount and job.total_amount > 0 else 0.0
    if total == 0 and billing and billing.total_estimated_amount:
        total = billing.total_estimated_amount
    
    # 2. Required Labours
    # Safety: If Order says 1 (default) but Billing has > 1, trust Billing.
    req_labours = job.required_labours if job.required_labours and job.required_labours > 1 else 1
    if req_labours == 1 and billing and billing.labour_count > 1:
        req_labours = billing.labour_count
        
    # Ensure min 1 to avoid division by zero
    if req_labours < 1: req_labours = 1
    
    # 3. Calculation
    # Prefer stored values if available
    gross_pool = 0.0
    net_pool = 0.0
    per_labour_gross = 0.0
    per_labour_net = 0.0
    
    # Try using Final Billing Data if generated
    if billing and billing.per_labour_earning_final > 0:
        per_labour_net = billing.per_labour_earning_final
        # Gross? Total / Count
        per_labour_gross = (billing.total_final_amount or total) / req_labours
        net_pool = per_labour_net * req_labours
        
    # Else Try using Estimate Billing Data
    elif billing and billing.per_labour_earning > 0:
        per_labour_net = billing.per_labour_earning
        per_labour_gross = (billing.total_estimated_amount or total) / req_labours
        net_pool = per_labour_net * req_labours
        
    # Else Fallback to Formula
    elif total > 0:
        gross_pool = total
        # Fee is 15% on TOTAL.
        # Labour Pool = Total * 0.85
        net_pool = total * 0.85
        per_labour_gross = gross_pool / req_labours
        per_labour_net = net_pool / req_labours
        
    return {
        "total_amount": round(total, 2),
        "total_estimated_amount": round(billing.total_estimated_amount if billing else total, 2),
        
        "required_labours": req_labours,
        "accepted_labours_count": filled_count,
        
        "platform_fee_percent": 15.0, # Fixed
        "net_amount_after_fee": round(net_pool, 2),
        
        "per_labour_gross": round(per_labour_gross, 2),
        "per_labour_net": round(per_labour_net, 2),
        "per_labour_earning": round(per_labour_net, 2)
    }

async def debug_list_jobs():
    print("DEBUG: Starting List Jobs Logic...")
    async for session in get_session():
        try:
            # 1. Fetch Orders
            print("Fetching Orders...")
            query = select(Order).limit(10)
            result = await session.execute(query)
            orders = result.scalars().all()
            print(f"Fetched {len(orders)} orders.")
            
            for job in orders:
                print(f"Processing Job: {job.id}")
                
                # 2. Fetch Billing
                billing_res = await session.execute(select(JobBilling).where(JobBilling.job_id == job.id))
                billing = billing_res.scalars().first()
                print(f"  > Billing found: {billing is not None}")
                if billing:
                    # Print some fields to verify they exist
                    print(f"    > Estimate: {billing.total_estimated_amount}")
                
                # 3. Fetch Assignment Count
                assign_res = await session.execute(select(func.count()).select_from(JobAssignment).where(JobAssignment.job_id == job.id))
                filled = assign_res.scalar() or 0
                print(f"  > Filled: {filled}")
                
                # 4. Calculate Payment
                print("  > Calculating Payment...")
                payment_info = calculate_job_payment_details(job, billing, filled)
                print(f"  > Payment Info: {payment_info}")
                
        except Exception as e:
            print(f"❌ CRASHED: {e}")
            import traceback
            traceback.print_exc()
        finally:
            print("DEBUG: Finished.")
            # return to break loop
            return

if __name__ == "__main__":
    with open("debug_output.txt", "w", encoding="utf-8") as f:
        sys.stdout = f
        sys.stderr = f
        asyncio.run(debug_list_jobs())
