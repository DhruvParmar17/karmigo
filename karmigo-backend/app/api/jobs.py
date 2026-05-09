# app/api/jobs.py

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from sqlmodel import select, func
from sqlalchemy.ext.asyncio import AsyncSession
import uuid
from datetime import datetime

from app.db.database import get_session
from app.db.models import Order, OrderBase, Labour, JobBilling, User, JobAssignment
from app.api.deps import get_current_labour, get_current_user
from app.schemas import JobCreate

router = APIRouter(prefix="/jobs", tags=["jobs"])

# -----------------------------
# RESPONSE MODEL
# -----------------------------

# -----------------------------
# RESPONSE MODEL
# -----------------------------
class JobWithDetails(OrderBase):
    id: uuid.UUID
    created_at: datetime
    
    required_labours: int = 1
    accepted_labours_count: int = 0
    
    total_amount: float = 0.0 # Override if needed, though Order has it.
    
    # New Standard Fields
    total_estimated_amount: float = 0.0
    net_amount_after_fee: float = 0.0
    per_labour_earning: float = 0.0
    
    per_labour_gross: float = 0.0
    platform_fee_percent: float = 15.0
    per_labour_net: float = 0.0 # Legacy alias for per_labour_earning
    
    # Aliases/Legacy support
    filled_labours: int = 0 
    
    your_status: Optional[str] = None # For labour specific view
    customer_phone: Optional[str] = None
    assigned_labours: List[dict] = []

# HELPER: Calculate Payment Details
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

# -----------------------------
# CREATE JOB
# -----------------------------
@router.post("/", response_model=Order, status_code=status.HTTP_201_CREATED)
async def create_job(job_in: JobCreate, current_user: User = Depends(get_current_user), session: AsyncSession = Depends(get_session)):
    # Map Schema to Model
    job = Order(
        title=job_in.title,
        description=job_in.description,
        location=job_in.location,
        latitude=job_in.latitude,
        longitude=job_in.longitude,
        # Default or calculated fields could go here
        required_labours=job_in.labour_count,
        total_amount=job_in.total_amount,
        order_status="pending"
    )
    session.add(job)
    await session.commit()
    await session.refresh(job)
    return job


# -----------------------------
# LIST ALL JOBS
# -----------------------------
@router.get("/", response_model=List[JobWithDetails])
async def list_jobs(
    limit: int = 1000, 
    labour_id: str = None, 
    order_status: str = None, 
    current_user: User = Depends(get_current_user), 
    session: AsyncSession = Depends(get_session)
):
    query = select(Order).limit(limit)
    
    # FILTERING
    if labour_id:
        # Complex join: Join JobAssignment where labour_id matches
        query = select(Order).join(JobAssignment, Order.id == JobAssignment.job_id).where(JobAssignment.labour_id == labour_id)

    if order_status:
        query = query.where(Order.order_status == order_status)
        
    result = await session.execute(query)
    orders = result.scalars().all()
    
    # Enrich with Details
    enriched_jobs = []
    
    for job in orders:
        # Get Billing Info
        billing_res = await session.execute(select(JobBilling).where(JobBilling.job_id == job.id))
        billing = billing_res.scalars().first()
        
        # Count Assignments
        assign_res = await session.execute(select(func.count()).select_from(JobAssignment).where(JobAssignment.job_id == job.id))
        filled = assign_res.scalar() or 0
        
        # Calculate Payment
        payment_info = calculate_job_payment_details(job, billing, filled)

        # Check 'your_status' if labour_id passed
        your_stat = None
        if labour_id:
             assign_query = select(JobAssignment).where(JobAssignment.job_id == job.id, JobAssignment.labour_id == labour_id)
             assign_rec = (await session.execute(assign_query)).scalar_one_or_none()
             if assign_rec:
                 your_stat = assign_rec.status

        # Create enriched object
        job_dict = job.dict()
        job_dict.update(payment_info)
        
        # Fetch assigned labours
        assign_query_all = select(JobAssignment).where(JobAssignment.job_id == job.id)
        all_assignments = (await session.execute(assign_query_all)).scalars().all()
        assigned_labours = []
        for ass in all_assignments:
            lab = await session.get(Labour, ass.labour_id)
            if lab:
                assigned_labours.append({
                    "id": str(lab.id),
                    "full_name": lab.full_name,
                    "phone": lab.phone,
                    "photo": lab.selfie_photo,
                    "rating": lab.rating
                })

        # Map to legacy fields if needed or simply include them
        job_dict.update({
            "filled_labours": payment_info["accepted_labours_count"],
            "per_labour_earning": payment_info["per_labour_net"],
            "your_status": your_stat,
            "customer_phone": None, # List doesn't return phone
            "assigned_labours": assigned_labours
        })
        enriched_jobs.append(JobWithDetails(**job_dict))
        
    return enriched_jobs


# -----------------------------
# GET SINGLE JOB BY ID
# -----------------------------
@router.get("/{job_id}", response_model=JobWithDetails)
async def get_job(job_id: str, labour_id: Optional[str] = None, session: AsyncSession = Depends(get_session)):
    job = await session.get(Order, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    # Reuse enrichment logic
    billing_res = await session.execute(select(JobBilling).where(JobBilling.job_id == job.id))
    billing = billing_res.scalars().first()
    
    assign_res = await session.execute(select(func.count()).select_from(JobAssignment).where(JobAssignment.job_id == job.id))
    filled = assign_res.scalar() or 0
    
    payment_info = calculate_job_payment_details(job, billing, filled)

    your_stat = None
    if labour_id:
            assign_query = select(JobAssignment).where(JobAssignment.job_id == job.id, JobAssignment.labour_id == labour_id)
            assign_rec = (await session.execute(assign_query)).scalar_one_or_none()
            if assign_rec:
                your_stat = assign_rec.status
    
    # Fetch Customer Phone
    customer_phone = None
    if job.user_id:
        user = await session.get(User, job.user_id)
        if user:
            customer_phone = user.phone

    # Fetch assigned labours
    assign_query_all = select(JobAssignment).where(JobAssignment.job_id == job.id)
    all_assignments = (await session.execute(assign_query_all)).scalars().all()
    assigned_labours = []
    for ass in all_assignments:
        lab = await session.get(Labour, ass.labour_id)
        if lab:
            assigned_labours.append({
                "id": str(lab.id),
                "full_name": lab.full_name,
                "phone": lab.phone,
                "photo": lab.selfie_photo,
                "rating": lab.rating
            })

    job_dict = job.dict()
    job_dict.update(payment_info)
    job_dict.update({
        "filled_labours": payment_info["accepted_labours_count"],
        "per_labour_earning": payment_info["per_labour_net"],
        "your_status": your_stat,
        "customer_phone": customer_phone,
        "assigned_labours": assigned_labours
    })
    
    return JobWithDetails(**job_dict)


# -----------------------------
# UPDATE JOB STATUS (Legacy / Admin)
# -----------------------------
@router.put("/{job_id}/status", response_model=Order)
async def update_job_status(job_id: str, status_value: str, session: AsyncSession = Depends(get_session)):
    job = await session.get(Order, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    # Payment Check for completion
    if status_value.lower() == "completed":
        # Check JobBilling
        billing_query = select(JobBilling).where(JobBilling.job_id == job_id)
        billing_res = await session.execute(billing_query)
        billing_rec = billing_res.scalars().first()
        
        if not billing_rec or billing_rec.payment_status != "paid":
             raise HTTPException(
                status_code=400, 
                detail="Payment required before completing the job."
            )

    job.order_status = status_value
    
    # Sync JobAssignment statuses too to free up Labour
    assignments_res = await session.execute(select(JobAssignment).where(JobAssignment.job_id == job_id))
    for assignment in assignments_res.scalars().all():
        assignment.status = status_value
        session.add(assignment)

    await session.commit()
    await session.refresh(job)
    return job


# -----------------------------
# ASSIGN LABOUR TO JOB (Multi-Labour)
# -----------------------------
@router.put("/{job_id}/assign", response_model=Order)
async def assign_labour(
    job_id: str, 
    labour_id: str = None, 
    current_labour: Labour = Depends(get_current_labour),
    session: AsyncSession = Depends(get_session)
):
    job = await session.get(Order, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    # 0. Check Verification
    # TEMP DEMO OVERRIDE – REMOVE BEFORE PRODUCTION
    is_demo_account = (
        current_labour.phone == "9892593525" or 
        current_labour.email == "dhurvparmar8@gmail.com"
    )
    
    if not current_labour.is_verified and not is_demo_account:
        raise HTTPException(status_code=403, detail="You must complete verification to accept jobs.")

    # 1. Check if already assigned
    existing = await session.execute(select(JobAssignment).where(
        JobAssignment.job_id == job_id, 
        JobAssignment.labour_id == current_labour.id
    ))
    if existing.scalar_one_or_none():
         raise HTTPException(status_code=400, detail="You have already accepted this job.")

    # 2. Check Capacity
    billing_res = await session.execute(select(JobBilling).where(JobBilling.job_id == job_id))
    billing = billing_res.scalars().first()
    max_labours = job.required_labours if job.required_labours and job.required_labours > 0 else (billing.labour_count if billing else 1)
    
    current_count_res = await session.execute(select(func.count()).select_from(JobAssignment).where(JobAssignment.job_id == job_id))
    current_count = current_count_res.scalar() or 0
    
    if current_count >= max_labours:
        raise HTTPException(status_code=400, detail="Job is full.")

    # 3. Create Assignment
    total_amt = job.total_amount or 0.0
    gross = total_amt / max_labours if max_labours > 0 else 0
    fee = gross * 0.15
    net = gross - fee

    assignment = JobAssignment(
        job_id=job.id,
        labour_id=current_labour.id,
        status="assigned",
        gross_amount=gross,
        platform_fee=fee,
        net_amount=net
    )
    session.add(assignment)
    
    # 4. Check if we need to update Main Job Status
    # If this fills the last slot, mark Main Job as ASSIGNED (if it was pending)
    if current_count + 1 >= max_labours:
        job.order_status = "assigned"
    
    # Legacy: Update labour_id field just in case (stores last one? or None?)
    # better leave it or store "multiple"
    # existing code might depend on it. Let's set it to current_labour.id but rely on Assignments.
    job.labour_id = current_labour.id 

    await session.commit()
    await session.refresh(job)
    return job


# -----------------------------
# DELETE JOB (Admin/Customer history)
# -----------------------------
@router.delete("/{job_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_job(
    job_id: str, 
    current_user: User = Depends(get_current_user), 
    session: AsyncSession = Depends(get_session)
):
    job = await session.get(Order, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    await session.delete(job)
    await session.commit()
    return None


# -----------------------------
# CANCEL JOB
# -----------------------------
@router.post("/{job_id}/cancel")
async def cancel_job(
    job_id: str, 
    current_user: User = Depends(get_current_user), 
    session: AsyncSession = Depends(get_session)
):
    job = await session.get(Order, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    if job.order_status not in ["pending", "assigned"]:
        raise HTTPException(status_code=400, detail="Cannot cancel job in current status")
        
    job.order_status = "cancelled"
    
    await session.commit()
    await session.refresh(job)
    return job

