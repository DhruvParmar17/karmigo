# app/schemas.py
from typing import Optional
from sqlmodel import SQLModel, Field
from datetime import datetime

class UserCreate(SQLModel):
    email: str
    password: str
    full_name: Optional[str] = None
    phone: Optional[str] = None

class UserRead(SQLModel):
    id: str
    email: str
    full_name: Optional[str] = None
    phone: Optional[str] = None
    is_active: bool
    is_superuser: bool
    created_at: datetime
