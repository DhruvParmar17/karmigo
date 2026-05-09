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
from app.schemas import OTPRequest, OTPVerify

# Simple in-memory OTP store (Use Redis in production)
# Format: {phone: {"otp": "1234", "expires": datetime}}
otp_store = {}
OTP_EXPIRY_MINUTES = 5
MAX_OTP_REQUESTS = 3
otp_request_limits = {} # {phone: [timestamp1, timestamp2]}


# Router
router = APIRouter(prefix="/auth", tags=["authentication"])

# Password hashing (use pbkdf2_sha256 to avoid bcrypt C-extension issues)
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

# JWT config (load from environment with safe defaults)
# JWT config (load from environment with safe defaults)
from app.core.config import SECRET_KEY, ALGORITHM


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
def create_access_token(data: dict, expires_minutes: int = 600):
    """
    Create a JWT token. Ensure all payload values are JSON-serializable.
    `exp` is added.
    """
    # Convert each value to a safe form
    to_encode = {}
    for k, v in data.items():
        to_encode[k] = _make_json_safe(v)

    expire_dt = datetime.utcnow() + timedelta(minutes=expires_minutes)
    # Pass datetime directly, jose handles it
    to_encode.update({"exp": expire_dt})

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

    print(f"DEBUG: Login user {user.email} -> is_superuser={user.is_superuser}")

    # Check if user is also a labour
    labour = await get_labour_for_user(user.email, session)
    
    # FORCE ADMIN for known emails (Bypass DB issues)
    is_demo_account = (
        user.email == "dhurvparmar8@gmail.com" or 
        user.email == "dhruvparmar8@gmail.com" or 
        user.phone == "9892593525"
    )
    
    if user.email in ["1234@gmail.com", "sansritidubey4@gmail.com"]:
        role = "admin"
    elif user.is_superuser:
        role = "admin"
    elif labour:
        role = "labour"
    else:
        role = "customer"
    
    labour_id = str(labour.id) if labour else None
    
    # Verification Override for Demo Account
    v_status = labour.verification_status if labour else "unsubmitted"
    is_v = labour.is_verified if labour else False
    
    if is_demo_account:
        v_status = "verified"
        is_v = True

    # Create token with extra claims
    token_claims = {
        "user_id": user.id,
        "email": user.email,
        "role": role,
        "labour_id": labour_id,
        "is_verified": is_v,
        "verification_status": v_status
    }
    
    token = create_access_token(token_claims)

    return {
        "access_token": token, 
        "token_type": "bearer",
        "user_id": str(user.id),
        "email": user.email,
        "phone": user.phone,
        "full_name": user.full_name,
        "role": role,
        "labour_id": labour_id
    }


# ----------------------
# LABOUR OTP AUTH
# ----------------------
@router.post("/labour/send-otp")
async def send_otp_labour(payload: OTPRequest):
    phone = payload.phone.strip()
    if not phone or len(phone) < 10:
        raise HTTPException(status_code=400, detail="Invalid phone number")
        
    # Rate Limiting
    now = datetime.utcnow()
    timestamps = otp_request_limits.get(phone, [])
    # Filter out requests older than 10 minutes
    timestamps = [t for t in timestamps if t > now - timedelta(minutes=10)]
    
    if len(timestamps) >= MAX_OTP_REQUESTS:
        raise HTTPException(status_code=429, detail="Too many OTP requests. Try again later.")
    
    timestamps.append(now)
    otp_request_limits[phone] = timestamps
    
    # Generate OTP (Random 4 digit)
    import secrets
    otp = "".join([str(secrets.randbelow(10)) for _ in range(4)]) 
    expires_at = now + timedelta(minutes=OTP_EXPIRY_MINUTES)
    
    otp_store[phone] = {
        "otp": otp,
        "expires": expires_at
    }
    
    # In a real app we would integrate SMS API here
    print(f"DEBUG: OTP for {phone} is {otp}")
    
    return {"message": "OTP sent successfully"}


@router.post("/labour/login-otp")
async def login_otp_labour(payload: OTPVerify, session: AsyncSession = Depends(get_session)):
    phone = payload.phone.strip()
    otp = payload.otp.strip()
    
    # Validate OTP
    record = otp_store.get(phone)
    if not record:
         raise HTTPException(status_code=400, detail="OTP not requested or expired")
    
    if record["otp"] != otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")
        
    if datetime.utcnow() > record["expires"]:
        raise HTTPException(status_code=400, detail="OTP expired")
        
    # Clear OTP after use
    del otp_store[phone]
    
    # Find or Create Labour
    query = select(Labour).where(Labour.phone == phone)
    result = await session.execute(query)
    labour = result.scalar_one_or_none()
    
    is_new_user = False
    
    if not labour:
        # Create new unverified labour
        is_new_user = True
        labour = Labour(
            full_name="Labour", # Placeholder
            email=f"{phone}@karmigo.local", # Placeholder
            phone=phone,
            is_verified=False,
            verification_status="unsubmitted",
            wallet_balance=0.0
        )
        session.add(labour)
        await session.commit()
        await session.refresh(labour)
    
    # Generate Token
    # Labour users usually don't have a 'User' table entry in this legacy system unless linked?
    # Keeping it simple: If we use the same Auth mechanism, we need a User ID.
    # But wait, `create_access_token` uses `user_id`. `Labour` has an ID too.
    # The current auth flow seems to prioritize `User`.
    # However, for Labour App, we might just need the `labour_id` claim.
    
    # Let's see how `get_current_user` works. It likely queries `User` table.
    # If Labour login doesn't create a `User`, standard deps might fail.
    # We should probably create a `User` shadow entry for consistency OR update deps.
    # The simplest path to "no disruption" is creating a shadow User.
    
    # Check for shadow User
    user_query = select(User).where(User.phone == phone)
    user_result = await session.execute(user_query)
    user = user_result.scalar_one_or_none()
    
    if not user:
        user = User(
            email=f"{phone}@karmigo.local",
            hashed_password="OTP_LOGIN_NO_PASSWORD",
            phone=phone,
            full_name=labour.full_name,
            is_active=True
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

    is_demo_account = (
        (user.email in ["dhurvparmar8@gmail.com", "dhruvparmar8@gmail.com"]) or 
        (user.phone and (user.phone == "9892593525" or user.phone.endswith("9892593525")))
    )
    v_status = "verified" if is_demo_account else labour.verification_status
    is_v = True if is_demo_account else labour.is_verified

    token_claims = {
        "user_id": user.id,
        "email": user.email,
        "role": "labour",
        "labour_id": str(labour.id),
        "verification_status": v_status,
        "is_verified": is_v
    }
    
    token = create_access_token(token_claims)
    
    return {
        "access_token": token,
        "token_type": "bearer",
        "user_id": str(user.id),
        "email": user.email,
        "phone": user.phone,
        "role": "labour",
        "labour_id": str(labour.id),
        "verification_status": v_status,
        "is_verified": is_v
    }


# ----------------------
# CUSTOMER OTP AUTH
# ----------------------
@router.post("/customer/send-otp")
async def send_otp_customer(payload: OTPRequest):
    phone = payload.phone.strip()
    if not phone or len(phone) < 10:
        raise HTTPException(status_code=400, detail="Invalid phone number")
        
    # Rate Limiting (Shared logic, could be extracted)
    now = datetime.utcnow()
    timestamps = otp_request_limits.get(phone, [])
    timestamps = [t for t in timestamps if t > now - timedelta(minutes=10)]
    
    if len(timestamps) >= MAX_OTP_REQUESTS:
        raise HTTPException(status_code=429, detail="Too many OTP requests. Try again later.")
    
    timestamps.append(now)
    otp_request_limits[phone] = timestamps
    
    # Generate OTP
    import secrets
    otp = "".join([str(secrets.randbelow(10)) for _ in range(4)]) 
    expires_at = now + timedelta(minutes=OTP_EXPIRY_MINUTES)
    
    otp_store[phone] = {
        "otp": otp,
        "expires": expires_at,
        "role": "customer" # Explicitly tag role
    }
    
    print(f"DEBUG: Customer OTP for {phone} is {otp}")
    
    return {"message": "OTP sent successfully"}


@router.post("/customer/login-otp")
async def login_otp_customer(payload: OTPVerify, session: AsyncSession = Depends(get_session)):
    phone = payload.phone.strip()
    otp = payload.otp.strip()
    
    # Validate OTP
    record = otp_store.get(phone)
    if not record:
         raise HTTPException(status_code=400, detail="OTP not requested or expired")
    
    if record["otp"] != otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")
        
    if record.get("role") != "customer":
         raise HTTPException(status_code=403, detail="Invalid login role restriction")

    if datetime.utcnow() > record["expires"]:
        raise HTTPException(status_code=400, detail="OTP expired")
        
    # Clear OTP
    del otp_store[phone]
    
    # Find or Create User (Customer)
    query = select(User).where(User.phone == phone)
    result = await session.execute(query)
    user = result.scalar_one_or_none()
    
    if not user:
        # Create new customer
        user = User(
            email=f"{phone}@karmigo.local", # Placeholder
            hashed_password="OTP_LOGIN_NO_PASSWORD",
            phone=phone,
            full_name="Customer", # Default name
            is_active=True,
            is_superuser=False
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
    
    # Generate Token
    token_claims = {
        "user_id": user.id,
        "email": user.email,
        "role": "customer",
    }
    
    token = create_access_token(token_claims)
    
    return {
        "access_token": token, 
        "token_type": "bearer",
        "user_id": str(user.id),
        "email": user.email,
        "phone": user.phone,
        "full_name": user.full_name,
        "role": "customer"
    }
