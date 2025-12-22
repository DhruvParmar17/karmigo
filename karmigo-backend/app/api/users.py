# app/api/users.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import select
from typing import List

from app.db.database import get_session
from app.db.models import User
from sqlalchemy.ext.asyncio import AsyncSession

# import the dependency that verifies the Bearer token
from app.api.deps import get_current_user

router = APIRouter(prefix="/users", tags=["users"])


@router.post("/", response_model=User, status_code=status.HTTP_201_CREATED)
async def create_user(user: User, session: AsyncSession = Depends(get_session)):
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


# NOTE: we add current_user: User = Depends(get_current_user) here.
# This will require a valid Bearer token for the endpoint and — important —
# will make the OpenAPI include the security scheme so the "Authorize"
# button appears in /docs.
@router.get("/", response_model=List[User])
async def list_users(
    limit: int = 50,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    q = select(User).limit(limit)
    result = await session.execute(q)
    return result.scalars().all()


@router.get("/{user_id}", response_model=User)
async def get_user(user_id: str, session: AsyncSession = Depends(get_session)):
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: str, session: AsyncSession = Depends(get_session)):
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    await session.delete(user)
    await session.commit()
    return None
