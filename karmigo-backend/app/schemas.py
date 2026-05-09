# app/schemas.py
from typing import Optional
from sqlmodel import SQLModel, Field
from datetime import datetime
from pydantic import BaseModel


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
    address: Optional[str] = None
    is_active: bool
    is_superuser: bool
    created_at: datetime

class UserUpdate(SQLModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None

class OTPRequest(BaseModel):
    phone: str
    
class OTPVerify(BaseModel):
    phone: str
    otp: str # Corrected from 'otp: strive: bool'

class LabourVerificationSubmit(BaseModel):
    aadhaar_number: str
    aadhaar_photo: Optional[str] = None
    selfie_photo: Optional[str] = None
    address_line1: str
    address_line2: Optional[str] = None
    city: str
    state: str
    zip_code: str
    emergency_contact_name: str
    emergency_contact_number: str
    bank_account_number: Optional[str] = None
    ifsc_code: Optional[str] = None
    upi_id: Optional[str] = None
    pan_number: Optional[str] = None

class JobCreate(SQLModel):
    title: str
    description: str
    location: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    work_type: Optional[str] = "shifting"
    labour_count: Optional[int] = 1
    total_amount: Optional[float] = 0.0

