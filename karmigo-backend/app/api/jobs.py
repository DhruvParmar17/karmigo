# app/api/jobs.py

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.database import get_session
from app.db.database import get_session
from app.db.models import Order, Labour
from app.api.deps import get_current_labour

router = APIRouter(prefix="/jobs", tags=["jobs"])

# -----------------------------
# CREATE JOB
# -----------------------------
@router.post("/", response_model=Order, status_code=status.HTTP_201_CREATED)
async def create_job(job: Order, session: AsyncSession = Depends(get_session)):
    session.add(job)
    await session.commit()
    await session.refresh(job)
    return job


# -----------------------------
# LIST ALL JOBS
# -----------------------------
@router.get("/", response_model=List[Order])
async def list_jobs(limit: int = 50, session: AsyncSession = Depends(get_session)):
    query = select(Order).limit(limit)
    result = await session.execute(query)
    return result.scalars().all()


# -----------------------------
# GET SINGLE JOB BY ID
# -----------------------------
@router.get("/{job_id}", response_model=Order)
async def get_job(job_id: str, session: AsyncSession = Depends(get_session)):
    job = await session.get(Order, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    return job


# -----------------------------
# UPDATE JOB STATUS
# -----------------------------
@router.put("/{job_id}/status", response_model=Order)
async def update_job_status(job_id: str, status_value: str, session: AsyncSession = Depends(get_session)):
    job = await session.get(Order, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    job.order_status = status_value
    await session.commit()
    await session.refresh(job)
    return job


# -----------------------------
# ASSIGN LABOUR TO JOB
# -----------------------------
@router.put("/{job_id}/assign", response_model=Order)
async def assign_labour(
    job_id: str, 
    labour_id: str = None, # Make optional so we don't break if frontend sends it, but we ignore it.
    current_labour: Labour = Depends(get_current_labour),
    session: AsyncSession = Depends(get_session)
):
    job = await session.get(Order, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    # Use the authenticated labour's ID, ignore what was sent in query param if any
    job.labour_id = current_labour.id
    job.order_status = "assigned"

    await session.commit()
    await session.refresh(job)
    return job
