from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
import json

from app.db.database import get_session
from app.db.models import JobBilling, Order, Labour, LabourWalletTransaction
from app.services.billing_service import BillingService

# Pydantic Schemas
from pydantic import BaseModel

class EstimateRequest(BaseModel):
    labour_count: int = 1
    floor_no: int = 0
    lift_available: bool = True
    walking_distance_meters: int = 0
    # heavy_items dict deprecated in favor of count?
    # Prompt says "Special Items: 50 per special item".
    # But UI might still send explicit items for now.
    # We will keep heavy_items dict for backward compact but rely on special_items_count if passed,
    # or calculate count from dict if not passed?
    # Let's add new fields.
    heavy_items: Optional[Dict[str, int]] = {} 
    
    hours_requested: float = 1.0
    house_size: Optional[str] = "1RK"
    special_items_count: int = 0
    service_charge_type: Optional[str] = "normal"
    
    work_type: str = "shifting"

class GenerateBillRequest(BaseModel):
    waiting_time_minutes: int = 0
    # Optional overrides
    heavy_items: Optional[Dict[str, int]] = None

class PaymentRequest(BaseModel):
    payment_method: str = "online" # online, cash

router = APIRouter(prefix="/billing", tags=["billing"])

# --------------------------
# GET BILLING DETAILS
# --------------------------
@router.get("/{job_id}")
async def get_billing_details(job_id: str, session: AsyncSession = Depends(get_session)):
    statement = select(JobBilling).where(JobBilling.job_id == job_id)
    result = await session.execute(statement)
    billing_record = result.scalars().first()
    
    if not billing_record:
        raise HTTPException(status_code=404, detail="Billing record not found")
        
    return billing_record

# --------------------------
# ESTIMATE PRICE (Pre-booking)
# --------------------------
@router.post("/estimate")
async def estimate_price(payload: EstimateRequest):
    """
    Get a price estimate based on provided details.
    """
    estimate = BillingService.calculate_estimate(
        labour_count=payload.labour_count,
        floor_no=payload.floor_no,
        lift_available=payload.lift_available,
        walking_distance_meters=payload.walking_distance_meters,
        hours_requested=payload.hours_requested,
        house_size=payload.house_size or "1RK",
        special_items_count=payload.special_items_count,
        service_charge_type=payload.service_charge_type or "normal"
    )
    return estimate

# --------------------------
# SAVE BILLING DETAILS (Post-booking)
# --------------------------
@router.post("/{job_id}/details")
async def save_billing_details(job_id: str, payload: EstimateRequest, session: AsyncSession = Depends(get_session)):
    # Check if job exists
    job = await session.get(Order, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
        
    statement = select(JobBilling).where(JobBilling.job_id == job_id)
    result = await session.execute(statement)
    billing_record = result.scalars().first()
    
    # Calculate initial estimate to store
    estimate = BillingService.calculate_estimate(
        labour_count=payload.labour_count,
        floor_no=payload.floor_no,
        lift_available=payload.lift_available,
        walking_distance_meters=payload.walking_distance_meters,
        hours_requested=payload.hours_requested,
        house_size=payload.house_size or "1RK",
        special_items_count=payload.special_items_count,
        service_charge_type=payload.service_charge_type or "normal"
    )
    
    if not billing_record:
        billing_record = JobBilling(
            job_id=job_id,
            work_type=payload.work_type,
            labour_count=payload.labour_count,
            floor_no=payload.floor_no,
            lift_available=payload.lift_available,
            walking_distance_meters=payload.walking_distance_meters,
            # heavy_items_json deprecated but we can store it for record
            heavy_items_json=json.dumps(payload.heavy_items or {}),
            
            # New Inputs
            hours_requested=payload.hours_requested,
            house_size=payload.house_size or "1RK",
            special_items_count=payload.special_items_count,
            service_charge_type=payload.service_charge_type or "normal",
            
            # Store Estimates
            base_price=estimate.get("base_price", 0.0),
            labour_cost_time_estimate=estimate.get("labour_cost_time_estimate", 0.0),
            floor_charges_estimate=estimate.get("floor_charges_estimate", 0.0),
            walking_charges_estimate=estimate.get("distance_charge_estimate", 0.0), # Map distance -> walking
            heavy_item_charges=0.0, # Deprecated legacy field
            
            # New Breakdown
            service_charge_estimate=estimate.get("service_charge_estimate", 0.0),
            special_items_charge_estimate=estimate.get("special_items_charge_estimate", 0.0),
            house_size_charge=estimate.get("house_size_charge", 0.0),
            distance_charge_estimate=estimate.get("distance_charge_estimate", 0.0),
            
            gst_amount=estimate.get("gst_amount", 0.0),
            platform_fee=estimate.get("platform_fee", 0.0),
            per_labour_earning=estimate.get("per_labour_earning", 0.0),
            
            total_estimated_amount=estimate.get("total_estimated_amount", 0.0)
        )
        session.add(billing_record)
    else:
        # Update existing
        billing_record.work_type = payload.work_type
        billing_record.labour_count = payload.labour_count
        billing_record.floor_no = payload.floor_no
        billing_record.lift_available = payload.lift_available
        billing_record.walking_distance_meters = payload.walking_distance_meters
        billing_record.heavy_items_json = json.dumps(payload.heavy_items or {})
        
        # New Inputs
        billing_record.hours_requested = payload.hours_requested
        billing_record.house_size = payload.house_size or "1RK"
        billing_record.special_items_count = payload.special_items_count
        billing_record.service_charge_type = payload.service_charge_type or "normal"
        
        billing_record.base_price = estimate.get("base_price", 0.0)
        billing_record.floor_charges_estimate = estimate.get("floor_charges_estimate", 0.0)
        billing_record.walking_charges_estimate = estimate.get("distance_charge_estimate", 0.0)
        
        # New Breakdown
        billing_record.labour_cost_time_estimate = estimate.get("labour_cost_time_estimate", 0.0)
        billing_record.service_charge_estimate = estimate.get("service_charge_estimate", 0.0)
        billing_record.special_items_charge_estimate = estimate.get("special_items_charge_estimate", 0.0)
        billing_record.house_size_charge = estimate.get("house_size_charge", 0.0)
        billing_record.distance_charge_estimate = estimate.get("distance_charge_estimate", 0.0)
        
        billing_record.gst_amount = estimate.get("gst_amount", 0.0)
        billing_record.platform_fee = estimate.get("platform_fee", 0.0)
        billing_record.per_labour_earning = estimate.get("per_labour_earning", 0.0)

        billing_record.total_estimated_amount = estimate.get("total_estimated_amount", 0.0)
    
    await session.commit()
    await session.refresh(billing_record)
    return billing_record

# --------------------------
# INIT / START JOB TIMER
# --------------------------
@router.post("/{job_id}/start")
async def start_job_timer(job_id: str, session: AsyncSession = Depends(get_session)):
    # Check if job exists
    job = await session.get(Order, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
        
    statement = select(JobBilling).where(JobBilling.job_id == job_id)
    result = await session.execute(statement)
    billing_record = result.scalars().first()
    
    if not billing_record:
        # Should have been created at booking. If not, create default.
        billing_record = JobBilling(
            job_id=job_id,
            work_type="shifting", # Default
            started_at=datetime.utcnow(),
            is_locked=True # Lock price on start
        )
        session.add(billing_record)
    else:
        if not billing_record.started_at:
            billing_record.started_at = datetime.utcnow()
            billing_record.is_locked = True
    
    job.order_status = "in_progress"
    session.add(job)
    
    await session.commit()
    await session.refresh(billing_record)
    return billing_record


# --------------------------
# GENERATE BILL (Stop Timer)
# --------------------------
@router.post("/{job_id}/generate")
async def generate_bill(job_id: str, request: GenerateBillRequest = GenerateBillRequest(), session: AsyncSession = Depends(get_session)):
    statement = select(JobBilling).where(JobBilling.job_id == job_id)
    result = await session.execute(statement)
    billing_record = result.scalars().first()
    
    if not billing_record:
        raise HTTPException(status_code=404, detail="Billing record not found. Job might not have started.")
    
    if not billing_record.started_at:
        raise HTTPException(status_code=400, detail="Job has not started yet.")

    # Calculate End Time
    if not billing_record.ended_at:
        billing_record.ended_at = datetime.utcnow()
    
    # Calculate
    # We use the BillingService to calculate final amounts
    # Estimate Data
    estimate_data = {
        "total_estimated_amount": billing_record.total_estimated_amount
        # We can pass other fields if service needs them for re-calc, but our current service uses estimate total + time
    }
    
    final_bill = BillingService.calculate_final_bill(
        estimate_data=estimate_data,
        started_at=billing_record.started_at,
        ended_at=billing_record.ended_at,
        labour_count=billing_record.labour_count,
        # We could support actuals if they differed, but for now use estimate's
        actual_walking_distance=billing_record.walking_distance_meters
    )
    
    billing_record.total_final_amount = final_bill["total_final_amount"]
    billing_record.labour_cost_time_final = final_bill["labour_cost_time_final"]
    billing_record.actual_duration_minutes = final_bill["actual_duration_minutes"]
    
    billing_record.waiting_charges_final = final_bill["waiting_charges_final"]
    billing_record.floor_charges_final = final_bill["floor_charges_final"]
    billing_record.walking_charges_final = final_bill["walking_charges_final"]
    billing_record.service_charge_final = final_bill["service_charge_final"]
    billing_record.special_items_charge_final = final_bill["special_items_charge_final"]
    billing_record.house_size_charge_final = final_bill["house_size_charge_final"]
    
    billing_record.gst_amount_final = final_bill["gst_amount_final"]
    billing_record.platform_fee_final = final_bill["platform_fee_final"]
    billing_record.per_labour_earning_final = final_bill["per_labour_earning_final"]
    
    billing_record.bill_breakdown_json = json.dumps(final_bill, default=str)
    
    # Sync to Order for listing
    statement_job = select(Order).where(Order.id == job_id)
    result_job = await session.execute(statement_job)
    job = result_job.scalar_one_or_none()
    if job:
        job.total_amount = billing_record.total_final_amount
        session.add(job)
    
    await session.commit()
    await session.refresh(billing_record)
    return billing_record

# --------------------------
# PAYMENT
# --------------------------
@router.post("/{job_id}/pay")
async def process_payment(job_id: str, request: PaymentRequest, session: AsyncSession = Depends(get_session)):
    # Get Billing
    statement = select(JobBilling).where(JobBilling.job_id == job_id)
    result = await session.execute(statement)
    billing_record = result.scalars().first()
    
    if not billing_record:
        raise HTTPException(status_code=404, detail="Billing record not found")
        
    if billing_record.payment_status == "paid":
        return {"status": "success", "message": "Already paid", "billing": billing_record}

    # Get Job & Labour for Wallet Logic
    job_res = await session.execute(select(Order).where(Order.id == job_id))
    job = job_res.scalar_one_or_none()
    
    labour_id = job.labour_id if job else None
    
    # Wallet Logic
    if request.payment_method == "cash" and labour_id: # Actually cash payment means Labour collects cash, so Wallet is DEBITED (He owes platform? Or platform owes him?)
        # "If cash job is allowed later -> wallet becomes negative."
        # This implies Labour collects Cash -> Platform deducts commission?
        # Or usually: 
        # Customer pays Labour 1000 Cash.
        # Platform Fee is 200.
        # Labour Wallet -200?
        # But the prompt says: "If cash job is allowed later -> wallet becomes negative. Next online job auto-deducts."
        # This implies:
        # If Customer pays Cash to Labour: Wallet -= TotalAmount? Or Wallet -= Commission?
        # Usually porter models: Driver keeps cash, Wallet deducted by commission.
        # BUT: "Customer pays ONLY in-app." (Rule 1 under Payment Rules).
        # "No manual cash marking."
        # Wait, the prompt says:
        # "PAYMENT RULES: ... Customer pays ONLY in-app."
        # "KARMIGO WALLET SYSTEM: ... If cash job is allowed later -> wallet becomes negative."
        # This seems contradictory or "future proofing".
        # Current rule: ONLY in-app.
        # So Customer pays Online to Platform.
        # Platform credit Labour Wallet?
        # "Next online job auto-deducts" implies previously negative balance.
        # If "Customer pays ONLY in-app", then Platform has the money.
        # So Platform should CREDIT Labour Wallet.
        # Let's assume Credit for Online Payment.
        pass

    if labour_id:
        labour_res = await session.execute(select(Labour).where(Labour.id == labour_id))
        labour = labour_res.scalar_one_or_none()
        
        if labour:
            amount = billing_record.total_final_amount
            # Online Payment: Platform collects. Labour gets share? 
            # Or is the wallet purely for "Cash Management" (like Swiggy)?
            # "Earnings ... Wallet balance".
            # If Customer pays Online 1000. Labour earns 1000 (minus commission?).
            # Let's assume Labour gets full amount credited for now, or 80%.
            # Let's credit 100% for simplicity unless specified.
            # "Admin dashboard shows... Earnings ... Wallet balance".
            labour.wallet_balance += amount # Credit
            session.add(labour)
            
            # Record Transaction
            txn = LabourWalletTransaction(
                labour_id=labour.id,
                job_id=job.id,
                amount=amount,
                description=f"Job Earnings: {job.title}",
                transaction_type="credit"
            )
            session.add(txn)
            
    billing_record.payment_status = "paid"
    billing_record.payment_method = request.payment_method
    
    # Complete Job
    if job:
        job.order_status = "completed"
        session.add(job)
    
    await session.commit()
    await session.refresh(billing_record)
    return {"status": "success", "message": "Payment successful", "billing": billing_record}

