# app/api/labour.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func
from typing import List, Optional
import uuid

from app.db.database import get_session
from app.db.models import User, Labour, Order, JobAssignment, JobBilling, LabourWalletTransaction
from app.api.deps import get_current_labour, get_current_user, oauth2_scheme
from app.api.jobs import calculate_job_payment_details # Shared Logic
from app.schemas import LabourVerificationSubmit

router = APIRouter(prefix="/labour", tags=["labour"])

@router.post("/verification/submit")
async def submit_verification(
    data: LabourVerificationSubmit,
    current_labour: Labour = Depends(get_current_labour),
    session: AsyncSession = Depends(get_session)
):
    # Update properties
    current_labour.aadhaar_number = data.aadhaar_number
    current_labour.address_line1 = data.address_line1
    current_labour.city = data.city
    current_labour.state = data.state
    current_labour.zip_code = data.zip_code
    current_labour.emergency_contact_name = data.emergency_contact_name
    current_labour.emergency_contact_number = data.emergency_contact_number
    
    # Optional fields
    if data.aadhaar_photo: current_labour.aadhaar_photo = data.aadhaar_photo
    if data.selfie_photo: current_labour.selfie_photo = data.selfie_photo
    if data.address_line2: current_labour.address_line2 = data.address_line2
    if data.bank_account_number: current_labour.bank_account_number = data.bank_account_number
    if data.ifsc_code: current_labour.ifsc_code = data.ifsc_code
    if data.upi_id: current_labour.upi_id = data.upi_id
    if data.pan_number: current_labour.pan_number = data.pan_number

    # Set status to pending
    current_labour.verification_status = "pending"
    # Note: is_verified remains False until admin approves

    session.add(current_labour)
    await session.commit()
    await session.refresh(current_labour)

    return {"message": "Verification submitted successfully", "status": "pending"}
    
@router.get("/verification/status")
async def get_verification_status(
    current_labour: Labour = Depends(get_current_labour)
):
    # Secondary check just in case dependency override failed
    is_demo_account = (
        (current_labour.email in ["dhurvparmar8@gmail.com", "dhruvparmar8@gmail.com"]) or 
        (current_labour.phone and (current_labour.phone == "9892593525" or current_labour.phone.endswith("9892593525")))
    )
    
    status = "verified" if is_demo_account else current_labour.verification_status
    is_verified = True if is_demo_account else current_labour.is_verified

    return {
        "status": status,
        "is_verified": is_verified
    }


# ----------------------------------------
# 1. MY JOBS
# ----------------------------------------
@router.get("/jobs/my")
async def get_my_jobs(current_labour: Labour = Depends(get_current_labour), session: AsyncSession = Depends(get_session)):
    # 1. Get assignments
    query = select(JobAssignment).where(JobAssignment.labour_id == current_labour.id).order_by(JobAssignment.created_at.desc())
    result = await session.execute(query)
    assignments = result.scalars().all()
    
    # 2. Get Jobs and Enrich
    my_jobs = []
    for assign in assignments:
        job = await session.get(Order, assign.job_id)
        if not job: continue
        
        # Get Billing & Counts for fresh calculation
        billing_res = await session.execute(select(JobBilling).where(JobBilling.job_id == job.id))
        billing = billing_res.scalars().first()
        
        assign_count_res = await session.execute(select(func.count()).select_from(JobAssignment).where(JobAssignment.job_id == job.id))
        filled_count = assign_count_res.scalar() or 0
        
        payment_info = calculate_job_payment_details(job, billing, filled_count)
        
        job_data = job.dict()
        job_data.update(payment_info)
        job_data.update({
            "status": assign.status, 
            "assignment_id": str(assign.id),
            "expected_earning": payment_info["per_labour_net"], # Use calculated net
            "your_status": assign.status,
             # Legacy/Compat fields
            "filled_labours": payment_info["accepted_labours_count"],
            "per_labour_earning": payment_info["per_labour_net"],
        })
        my_jobs.append(job_data)
        
    return my_jobs

# ... (update_job_status remains) ...

# ----------------------------------------
# 3. GET PAYMENT INFO (Detailed)
# ----------------------------------------
@router.get("/jobs/{job_id}/payment")
async def get_job_payment(
    job_id: str,
    current_labour: Labour = Depends(get_current_labour),
    session: AsyncSession = Depends(get_session)
):
    # 1. Verify Assignment
    query = select(JobAssignment).where(
        JobAssignment.job_id == job_id,
        JobAssignment.labour_id == current_labour.id
    )
    assignment = (await session.execute(query)).scalar_one_or_none()
    
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
    
    # 2. Get Job Docs
    job = await session.get(Order, job_id)
    billing_res = await session.execute(select(JobBilling).where(JobBilling.job_id == job_id))
    billing = billing_res.scalars().first()
    
    assign_count_res = await session.execute(select(func.count()).select_from(JobAssignment).where(JobAssignment.job_id == job_id))
    filled_count = assign_count_res.scalar() or 0
    
    # 3. Calculate
    payment_info = calculate_job_payment_details(job, billing, filled_count)
    
    # Add Job ID
    payment_info["job_id"] = str(job_id)
             
    return payment_info


# ----------------------------------------
# Get single labour by ID
# ----------------------------------------
@router.get("/{labour_id}")
async def get_labour(labour_id: str, session: AsyncSession = Depends(get_session)):
    result = await session.execute(select(Labour).where(Labour.id == labour_id))
    labour = result.scalar_one_or_none()

    if not labour:
        raise HTTPException(status_code=404, detail="Labour not found")

    return labour


# ----------------------------------------
# Update labour
# ----------------------------------------
@router.put("/{labour_id}")
async def update_labour(labour_id: str, updated_data: Labour, session: AsyncSession = Depends(get_session)):
    result = await session.execute(select(Labour).where(Labour.id == labour_id))
    labour = result.scalar_one_or_none()

    if not labour:
        raise HTTPException(status_code=404, detail="Labour not found")

    update_data = updated_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(labour, key, value)

    session.add(labour)
    await session.commit()
    await session.refresh(labour)

    return {"message": "Labour updated successfully", "labour": labour}


# ----------------------------------------
# Delete labour
# ----------------------------------------
@router.delete("/{labour_id}")
async def delete_labour(labour_id: str, session: AsyncSession = Depends(get_session)):
    result = await session.execute(select(Labour).where(Labour.id == labour_id))
    labour = result.scalar_one_or_none()

    if not labour:
        raise HTTPException(status_code=404, detail="Labour not found")

    await session.delete(labour)
    await session.commit()

    return {"message": "Labour deleted successfully"}


# ----------------------------------------
# WALLET & TRANSACTIONS
# ----------------------------------------
from app.db.models import LabourWalletTransaction
# from app.api.deps import get_current_labour # Already imported

@router.get("/wallet/balance")
async def get_wallet_balance(
    current_labour: Labour = Depends(get_current_labour),
    session: AsyncSession = Depends(get_session)
):
    return {"balance": current_labour.wallet_balance}

@router.get("/wallet/transactions")
async def get_wallet_transactions(
    current_labour: Labour = Depends(get_current_labour),
    session: AsyncSession = Depends(get_session)
):
    query = select(LabourWalletTransaction).where(LabourWalletTransaction.labour_id == current_labour.id).order_by(LabourWalletTransaction.created_at.desc())
    result = await session.execute(query)
    transactions = result.scalars().all()
    return transactions


# ----------------------------------------
# Create a Labour
# ----------------------------------------
@router.post("/add")
async def add_labour(labour: Labour, session: AsyncSession = Depends(get_session)):
    session.add(labour)
    await session.commit()
    await session.refresh(labour)
    return {"message": "Labour added successfully", "labour": labour}


# ----------------------------------------
# Get all labour
# ----------------------------------------
@router.get("/all")
async def get_all_labour(session: AsyncSession = Depends(get_session)):
    result = await session.execute(select(Labour))
    labour_list = result.scalars().all()
    return {"total": len(labour_list), "labour": labour_list}
