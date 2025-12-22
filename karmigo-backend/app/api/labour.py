# app/api/labour.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.db.database import get_session
from app.db.models import Labour

router = APIRouter(prefix="/labour", tags=["labour"])


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
