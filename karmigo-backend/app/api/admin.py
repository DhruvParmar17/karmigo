from fastapi import APIRouter, Depends
from sqlmodel import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.db.database import get_session
from datetime import datetime, date, timedelta
from app.db.models import User, Labour, Order, JobBilling, JobAssignment
from app.api.deps import get_current_admin

router = APIRouter(prefix="/admin", tags=["admin"])

@router.get("/stats")
async def get_admin_stats(
    current_user: User = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session)
):
    # --- DATE SETUP ---
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    
    # --- USERS ---
    user_count = (await session.execute(select(func.count(User.id)))).scalar() or 0
    
    # --- LABOUR ---
    labour_total = (await session.execute(select(func.count(Labour.id)))).scalar() or 0
    labour_verified = (await session.execute(select(func.count(Labour.id)).where(Labour.is_verified == True))).scalar() or 0
    
    # Available = Verified - Currently Busy
    # Busy means they have an active assignment (assigned, on_the_way, reached, started)
    # query active assignments
    active_assignments_stmt = select(func.count(JobAssignment.labour_id.distinct())).where(
        JobAssignment.status.in_(["assigned", "on_the_way", "reached", "started"])
    )
    busy_labour_count = (await session.execute(active_assignments_stmt)).scalar() or 0
    labour_available = max(0, labour_verified - busy_labour_count)

    # --- JOBS ---
    total_jobs = (await session.execute(select(func.count(Order.id)))).scalar() or 0
    jobs_today = (await session.execute(select(func.count(Order.id)).where(Order.created_at >= today_start))).scalar() or 0
    
    pending_jobs = (await session.execute(select(func.count(Order.id)).where(Order.order_status == "pending"))).scalar() or 0
    active_jobs = (await session.execute(select(func.count(Order.id)).where(Order.order_status.in_(["assigned", "in_progress"])))).scalar() or 0
    completed_jobs = (await session.execute(select(func.count(Order.id)).where(Order.order_status == "completed"))).scalar() or 0
    cancelled_jobs = (await session.execute(select(func.count(Order.id)).where(Order.order_status == "cancelled"))).scalar() or 0

    # --- FINANCIALS ---
    # Total Collected (from paid/completed jobs in billing)
    earnings_stmt = select(func.sum(JobBilling.total_final_amount)).where(JobBilling.payment_status == "paid")
    total_collected = (await session.execute(earnings_stmt)).scalar() or 0.0
    
    # Platform Commission
    commission_stmt = select(func.sum(JobBilling.platform_fee_final)).where(JobBilling.payment_status == "paid")
    platform_commission = (await session.execute(commission_stmt)).scalar() or 0.0
    
    # Pending Payouts
    payouts_stmt = select(func.sum(Labour.wallet_balance)).where(Labour.wallet_balance > 0)
    pending_payouts = (await session.execute(payouts_stmt)).scalar() or 0.0

    return {
        "users": user_count,
        "labour": {
            "total": labour_total,
            "verified": labour_verified,
            "available": labour_available
        },
        "jobs": {
            "total": total_jobs,
            "today": jobs_today,
            "pending": pending_jobs,
            "active": active_jobs,
            "completed": completed_jobs,
            "cancelled": cancelled_jobs
        },
        "financials": {
            "total_collected": total_collected,
            "platform_commission": platform_commission,
            "pending_payouts": pending_payouts
        }
    }

@router.get("/dashboard")
async def get_admin_dashboard(
    current_user: User = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session)
):
    """
    Get real-time operational metrics for the admin dashboard.
    """
    # --- DATE SETUP ---
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)

    # --- FINANCIAL OVERVIEW ---
    # Total Collected = SUM(JobBilling.total_final_amount where payment_status='paid')
    total_collected_stmt = select(func.sum(JobBilling.total_final_amount)).where(JobBilling.payment_status == "paid")
    total_collected = (await session.execute(total_collected_stmt)).scalar() or 0.0

    # Platform Earnings = SUM(JobBilling.platform_fee_final)
    platform_earnings_stmt = select(func.sum(JobBilling.platform_fee_final)).where(JobBilling.payment_status == "paid")
    platform_earnings = (await session.execute(platform_earnings_stmt)).scalar() or 0.0

    # Pending Labour Payouts = SUM(JobBilling.per_labour_earning_final where payout not yet processed)
    # Using wallet balance as proxy for pending payouts as per implementation plan.
    pending_payouts_stmt = select(func.sum(Labour.wallet_balance)).where(Labour.wallet_balance > 0)
    pending_payouts = (await session.execute(pending_payouts_stmt)).scalar() or 0.0

    # --- JOB LIFECYCLE ---
    # Total Jobs = COUNT(orders)
    total_jobs = (await session.execute(select(func.count(Order.id)))).scalar() or 0

    # Jobs Today = COUNT(orders where created_at = today)
    jobs_today = (await session.execute(select(func.count(Order.id)).where(Order.created_at >= today_start))).scalar() or 0

    # Pending Jobs = COUNT(orders where order_status='pending')
    pending_jobs = (await session.execute(select(func.count(Order.id)).where(Order.order_status == "pending"))).scalar() or 0

    # Active Jobs = COUNT(orders where order_status in ['assigned', 'in_progress'])
    active_jobs = (await session.execute(select(func.count(Order.id)).where(Order.order_status.in_(["assigned", "in_progress", "on_the_way", "reached", "started"])))).scalar() or 0

    # Completed Jobs = COUNT(orders where order_status='completed')
    completed_jobs = (await session.execute(select(func.count(Order.id)).where(Order.order_status == "completed"))).scalar() or 0

    # Cancelled Jobs = COUNT(orders where order_status='cancelled')
    cancelled_jobs = (await session.execute(select(func.count(Order.id)).where(Order.order_status == "cancelled"))).scalar() or 0

    # --- LABOUR AVAILABILITY ---
    # Registered Labour = COUNT(labour)
    registered_labour = (await session.execute(select(func.count(Labour.id)))).scalar() or 0

    # Verified Labour = COUNT(labour where is_verified=true)
    verified_labour = (await session.execute(select(func.count(Labour.id)).where(Labour.is_verified == True))).scalar() or 0

    # Available Labour Now = COUNT(labour where availability_status='available' or active)
    # Using Verified - Busy logic from existing stats.
    active_assignments_stmt = select(func.count(JobAssignment.labour_id.distinct())).where(
        JobAssignment.status.in_(["assigned", "on_the_way", "reached", "started"])
    )
    busy_labour_count = (await session.execute(active_assignments_stmt)).scalar() or 0
    available_now = max(0, verified_labour - busy_labour_count)

    # --- CUSTOMER ACTIVITY ---
    # Total Customers = COUNT(users)
    total_customers = (await session.execute(select(func.count(User.id)))).scalar() or 0

    return {
        "financial_overview": {
            "total_collected": total_collected,
            "platform_earnings": platform_earnings,
            "pending_payouts": pending_payouts
        },
        "job_lifecycle": {
            "total_jobs": total_jobs,
            "jobs_today": jobs_today,
            "pending_jobs": pending_jobs,
            "active_jobs": active_jobs,
            "completed_jobs": completed_jobs,
            "cancelled_jobs": cancelled_jobs
        },
        "labour_availability": {
            "registered": registered_labour,
            "verified": verified_labour,
            "available_now": available_now
        },
        "customer_activity": {
            "total_customers": total_customers
        }
    }

@router.get("/jobs")
async def get_all_jobs(
    status: str = None,
    current_user: User = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session)
):
    query = select(
        Order,
        func.count(JobAssignment.id).label("accepted_count"),
        User.full_name,
        User.phone,
        JobBilling.payment_status,
        JobBilling.payment_method
    ).outerjoin(JobAssignment, JobAssignment.job_id == Order.id) \
     .outerjoin(User, User.id == Order.user_id) \
     .outerjoin(JobBilling, JobBilling.job_id == Order.id) \
     .group_by(Order.id, User.full_name, User.phone, JobBilling.payment_status, JobBilling.payment_method)

    if status and status.lower() != "all":
        query = query.where(Order.order_status == status.lower())
    
    query = query.order_by(Order.created_at.desc())

    result = await session.execute(query)
    rows = result.all()
    
    response = []
    for order, accepted_count, u_name, u_phone, pay_status, pay_method in rows:
        order_dict = order.dict()
        order_dict['accepted_labour_count'] = accepted_count
        if order_dict.get('required_labours') is None:
             order_dict['required_labours'] = 1

        order_dict['customer_name'] = u_name or "Unknown"
        order_dict['customer_phone'] = u_phone or "No Phone"
        order_dict['payment_status'] = pay_status or "pending"
        order_dict['payment_method'] = pay_method or "online"
        
        response.append(order_dict)
        
    return response

@router.get("/alerts")
async def get_admin_alerts(
    current_user: User = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session)
):
    alerts = []
    now = datetime.utcnow()

    # 1. Verification > 24H pending
    yesterday = now - timedelta(hours=24)
    v_query = select(Labour).where(Labour.verification_status == "pending", Labour.created_at <= yesterday)
    v_result = await session.execute(v_query)
    for l in v_result.scalars().all():
        alerts.append({
            "type": "verification_pending",
            "title": "Verification Overdue",
            "subtitle": f"Labour {l.full_name or l.email} waiting > 24hrs",
            "icon": "verified_user",
            "color": "blue",
            "data": l.dict()
        })

    # 2. Active Job > 3 hrs not completed
    three_hours_ago = now - timedelta(hours=3)
    j_query = select(Order).where(Order.order_status.in_(["assigned", "in_progress", "started"]), Order.created_at <= three_hours_ago)
    j_result = await session.execute(j_query)
    for job in j_result.scalars().all():
        alerts.append({
            "type": "job_delayed",
            "title": "Delayed Active Job",
            "subtitle": f"Job {job.title} active for > 3hrs",
            "icon": "watch_later",
            "color": "orange",
            "data": job.dict()
        })
        
    # 3. Emergency SOS Tickets
    sos_query = select(Order).where(Order.order_status == "sos")
    sos_result = await session.execute(sos_query)
    for sos in sos_result.scalars().all():
        alerts.append({
            "type": "emergency_sos",
            "title": "🚨 EMERGENCY SOS REPORT 🚨",
            "subtitle": f"Customer flagged SOS on {sos.title}!",
            "icon": "warning_amber_rounded",
            "color": "red",
            "data": sos.dict()
        })
        
    return alerts

@router.get("/users")
async def get_all_users(
    current_user: User = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session)
):
    query = select(
        User,
        func.count(Order.id).label("total_jobs"),
        func.sum(
            func.cast(Order.order_status == 'cancelled', type_=Integer)
        ).label("cancelled_jobs")
    ).outerjoin(Order, Order.user_id == User.id).group_by(User.id)
    
    result = await session.execute(query)
    
    response = []
    from sqlalchemy import Integer
    
    for user, total, cancelled in result.all():
       udict = user.dict()
       udict['total_jobs'] = total or 0
       udict['cancelled_jobs'] = cancelled or 0
       response.append(udict)
       
    return response

@router.post("/users/{user_id}/toggle-block")
async def toggle_user_block(
    user_id: str,
    action: str, # 'block' or 'unblock'
    current_user: User = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session)
):
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.is_active = (action == 'unblock')
    session.add(user)
    await session.commit()
    return {"message": f"User {action}ed successfully", "is_active": user.is_active}

@router.get("/labours")
async def get_all_labours(
    current_user: User = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session)
):
    # Fetch all labours joined with assignments to calculate states!
    query = select(Labour)
    result = await session.execute(query)
    labours = result.scalars().all()
    
    # Simple explicit dict conversion
    response = []
    for l in labours:
       ldict = l.dict()
       # Active vs Completed jobs dynamically via python 
       # To avoid complex sqlalchemy group_by assignments mapping
       j_res = await session.execute(select(JobAssignment.status).where(JobAssignment.labour_id == l.id))
       stats = j_res.scalars().all()
       
       ldict['active_jobs'] = len([s for s in stats if s in ["assigned", "on_the_way", "reached", "started"]])
       ldict['completed_jobs'] = len([s for s in stats if s == "completed"])
       response.append(ldict)
       
    return response

@router.put("/jobs/{job_id}/assign")
async def assign_job_by_admin(
    job_id: str,
    labour_id: str,
    current_user: User = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session)
):
    job = await session.get(Order, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    # In a real app we would verify labour_id exists too
    # Assuming UUID string is valid
    import uuid
    job.labour_id = uuid.UUID(labour_id)
    job.order_status = "assigned"

    session.add(job)
    await session.commit()
    await session.refresh(job)
    session.add(job)
    await session.commit()
    await session.refresh(job)
    return job


# ----------------------
# VERIFICATION REVIEW
# ----------------------
@router.get("/verifications/pending")
async def get_pending_verifications(
    current_user: User = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session)
):
    # Fetch all labour with verification_status = 'pending'
    query = select(Labour).where(Labour.verification_status == "pending")
    result = await session.execute(query)
    labours = result.scalars().all()
    
    # Return masked Aadhaar for list view security
    response = []
    for l in labours:
        masked = f"XXXX-XXXX-{l.aadhaar_number[-4:] if l.aadhaar_number and len(l.aadhaar_number) >= 4 else 'XXXX'}"
        data = l.dict()
        data["aadhaar_number_masked"] = masked
        # In detailed view, admin might see full number, but let's be safe by default
        response.append(data)
        
    return response


@router.post("/verifications/{labour_id}/approve")
async def approve_verification(
    labour_id: str,
    current_user: User = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session)
):
    labour = await session.get(Labour, labour_id)
    if not labour:
        raise HTTPException(status_code=404, detail="Labour not found")
        
    labour.verification_status = "verified"
    labour.is_verified = True
    labour.rejection_reason = None
    
    session.add(labour)
    await session.commit()
    
    return {"message": "Labour verified successfully", "labour_id": labour_id}


@router.post("/verifications/{labour_id}/reject")
async def reject_verification(
    labour_id: str,
    reason: str,
    current_user: User = Depends(get_current_admin),
    session: AsyncSession = Depends(get_session)
):
    labour = await session.get(Labour, labour_id)
    if not labour:
        raise HTTPException(status_code=404, detail="Labour not found")
        
    labour.verification_status = "rejected"
    labour.is_verified = False
    labour.rejection_reason = reason
    
    session.add(labour)
    await session.commit()
    
    return {"message": "Labour verification rejected", "labour_id": labour_id}
