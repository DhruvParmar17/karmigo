# app/api/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime, timedelta
from typing import Optional, Any
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, EmailStr

from passlib.context import CryptContext
from jose import jwt
import json
import uuid
import os   # <--- added

from app.db.database import get_session
from app.db.models import User, Labour
from app.api.deps import oauth2_scheme


# Router
router = APIRouter(prefix="/auth", tags=["authentication"])

# Password hashing (use pbkdf2_sha256 to avoid bcrypt C-extension issues)
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

# JWT config (load from environment with safe defaults)
SECRET_KEY = os.getenv("KARMIGO_SECRET_KEY", "karmigo-secret-key-change-this")
ALGORITHM = os.getenv("KARMIGO_ALGORITHM", "HS256")


# ----------------------
# Pydantic request models
# ----------------------
class SignupRequest(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None
    phone: Optional[str] = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# ----------------------
# helpers
# ----------------------
def hash_password(password: str) -> str:
    """
    Return hashed password string. Raises ValueError on failure.
    """
    try:
        hashed = pwd_context.hash(password)
        if not isinstance(hashed, str) or len(hashed) == 0:
            raise ValueError("Hashing returned invalid result")
        return hashed
    except Exception as e:
        raise ValueError(f"Password hashing failed: {e}") from e


def verify_password(password: str, hashed_password: str) -> bool:
    try:
        return pwd_context.verify(password, hashed_password)
    except Exception:
        return False


def _make_json_safe(value: Any) -> Any:
    """
    Convert common non-JSON-serializable types into JSON-safe representations.
    - UUID -> str
    - datetime -> ISO string
    - fallback -> str(value)
    If value is already JSON serializable, return as-is.
    """
    # Handle None and primitive types quickly
    if value is None or isinstance(value, (str, int, float, bool)):
        return value

    # UUID
    if isinstance(value, uuid.UUID):
        return str(value)

    # datetime -> ISO format
    if isinstance(value, datetime):
        return value.isoformat()

    # Try json.dumps to confirm serializability
    try:
        json.dumps(value)
        return value
    except TypeError:
        # Fallback to str representation
        return str(value)


# ----------------------
# FIXED FUNCTION
# ----------------------
def create_access_token(data: dict, expires_minutes: int = 60):
    """
    Create a JWT token. Ensure all payload values are JSON-serializable.
    `exp` is added as an integer UNIX timestamp (seconds).
    """
    # Convert each value to a safe form
    to_encode = {}
    for k, v in data.items():
        to_encode[k] = _make_json_safe(v)

    expire_dt = datetime.utcnow() + timedelta(minutes=expires_minutes)
    # Use integer timestamp for exp to avoid JSON/datetime issues in some jwt implementations
    to_encode.update({"exp": int(expire_dt.timestamp())})

    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


async def get_labour_for_user(email: str, session: AsyncSession) -> Optional[Labour]:
    """Check if a User email is also registered as Labour"""
    query = select(Labour).where(Labour.email == email)
    result = await session.execute(query)
    return result.scalar_one_or_none()


# ----------------------
# Signup
# ----------------------
@router.post("/signup")
async def signup(payload: SignupRequest, session: AsyncSession = Depends(get_session)):
    query = select(User).where(User.email == payload.email)
    result = await session.execute(query)
    existing_user = result.scalar_one_or_none()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    try:
        hashed_pw = hash_password(payload.password)
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))

    user = User(
        email=payload.email,
        hashed_password=hashed_pw,
        full_name=payload.full_name,
        phone=payload.phone,
        is_active=True,
        is_superuser=False,
    )

    session.add(user)
    await session.commit()
    await session.refresh(user)

    return {"message": "Signup successful", "user_id": user.id}


# ----------------------
# Login
# ----------------------
@router.post("/login")
async def login(payload: LoginRequest, session: AsyncSession = Depends(get_session)):
    query = select(User).where(User.email == payload.email)
    result = await session.execute(query)
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect password")

    # Check if user is also a labour
    labour = await get_labour_for_user(user.email, session)
    role = "labour" if labour else "customer"
    labour_id = str(labour.id) if labour else None

    # Create token with extra claims
    token_claims = {
        "user_id": user.id,
        "email": user.email,
        "role": role,
        "labour_id": labour_id
    }
    
    token = create_access_token(token_claims)

    return {
        "access_token": token, 
        "token_type": "bearer",
        "user_id": user.id,
        "email": user.email,
        "full_name": user.full_name,
        "role": role,
        "labour_id": labour_id
    }
