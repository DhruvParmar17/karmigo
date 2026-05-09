# app/db/models.py
from typing import Optional
from datetime import datetime
import uuid

from sqlmodel import SQLModel, Field
from sqlalchemy import Column, text
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.sql import func


# ----------------
# USERS (customers)
# ----------------
class UserBase(SQLModel):
    email: str = Field(index=True)
    full_name: Optional[str] = None
    phone: Optional[str] = Field(None, index=True)
    address: Optional[str] = None

class User(UserBase, table=True):
    __tablename__ = "users"

    id: Optional[uuid.UUID] = Field(
        default=None,
        sa_column=Column(
            PG_UUID(as_uuid=True),
            primary_key=True,
            server_default=text("gen_random_uuid()"),
        ),
    )

    hashed_password: Optional[str] = None
    is_active: bool = Field(default=True)
    is_superuser: bool = Field(default=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)


# ----------------
# LABOUR (workers)
# ----------------
class LabourBase(SQLModel):
    full_name: str
    email: str = Field(index=True)
    phone: Optional[str] = Field(None, index=True)
    skills: Optional[str] = None
    rating: Optional[float] = 0.0
    wallet_balance: float = 0.0
    is_verified: bool = Field(default=False)
    
    # Verification Fields
    aadhaar_number: Optional[str] = None
    aadhaar_photo: Optional[str] = None
    selfie_photo: Optional[str] = None
    
    address_line1: Optional[str] = None
    address_line2: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    zip_code: Optional[str] = None
    
    emergency_contact_name: Optional[str] = None
    emergency_contact_number: Optional[str] = None
    
    bank_account_number: Optional[str] = None
    ifsc_code: Optional[str] = None
    upi_id: Optional[str] = None
    pan_number: Optional[str] = None
    
    # Enum: unsubmitted, pending, verified, rejected
    verification_status: str = "unsubmitted" 
    rejection_reason: Optional[str] = None


class Labour(LabourBase, table=True):
    __tablename__ = "labour"

    id: Optional[uuid.UUID] = Field(
        default=None,
        sa_column=Column(
            PG_UUID(as_uuid=True),
            primary_key=True,
            server_default=text("gen_random_uuid()"),
        ),
    )
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)


# ----------------
# PRODUCTS (or Services)
# ----------------
class ProductBase(SQLModel):
    name: str
    description: Optional[str] = None
    price: float


class Product(ProductBase, table=True):
    __tablename__ = "products"

    id: Optional[uuid.UUID] = Field(
        default=None,
        sa_column=Column(
            PG_UUID(as_uuid=True),
            primary_key=True,
            server_default=text("gen_random_uuid()"),
        ),
    )
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)


# ----------------
# ORDERS / JOB REQUESTS
# ----------------
class OrderBase(SQLModel):
    user_id: Optional[uuid.UUID] = None
    labour_id: Optional[uuid.UUID] = None
    title: Optional[str] = None
    description: Optional[str] = None
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    scheduled_at: Optional[datetime] = None
    total_amount: Optional[float] = 0.0
    required_labours: Optional[int] = 1
    currency: Optional[str] = "INR"
    order_status: Optional[str] = "pending"


class Order(OrderBase, table=True):
    __tablename__ = "orders"

    id: Optional[uuid.UUID] = Field(
        default=None,
        sa_column=Column(
            PG_UUID(as_uuid=True),
            primary_key=True,
            server_default=text("gen_random_uuid()"),
        ),
    )
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)


# ----------------
# ORDER ITEMS
# ----------------
class OrderItem(SQLModel, table=True):
    __tablename__ = "order_items"

    id: Optional[uuid.UUID] = Field(
        default=None,
        sa_column=Column(
            PG_UUID(as_uuid=True),
            primary_key=True,
            server_default=text("gen_random_uuid()"),
        ),
    )

    order_id: Optional[uuid.UUID] = None
    product_id: Optional[uuid.UUID] = None
    quantity: int = 1
    price: float = 0.0


# ----------------
# BILLING & PAYMENT
# ----------------
class JobBilling(SQLModel, table=True):
    __tablename__ = "job_billing"

    id: Optional[uuid.UUID] = Field(
        default=None,
        sa_column=Column(
            PG_UUID(as_uuid=True),
            primary_key=True,
            server_default=text("gen_random_uuid()"),
        ),
    )
    job_id: uuid.UUID = Field(foreign_key="orders.id")
    
    # Billing Details
    work_type: str  # shifting, construction, warehouse
    
    # Estimation Inputs
    floor_no: int = 0
    lift_available: bool = True
    walking_distance_meters: int = 0
    labour_count: int = 1
    
    # Heavy Items (Stored as JSON string e.g. {"fridge": 1, "sofa": 2})
    heavy_items_json: str = "{}" 
    
    # New Pricing Inputs
    hours_requested: float = 1.0
    house_size: str = "1RK" # 1RK, 1BHK, 2BHK, 3BHK
    special_items_count: int = 0
    service_type_charge: float = 0.0 # Stored charge amount or type? Let's store the charge amount or the type. 
    # The prompt says "Service Type Charges". We can store the type key and calculation.
    service_charge_type: str = "normal" # normal, heavy, risk 
    
    # Cost Breakdown (Estimates)
    base_price: float = 0.0
    labour_cost_time_estimate: float = 0.0
    floor_charges_estimate: float = 0.0
    walking_charges_estimate: float = 0.0
    heavy_item_charges: float = 0.0
    
    # New Breakdown Fields
    service_charge_estimate: float = 0.0 # For Service Type
    special_items_charge_estimate: float = 0.0
    house_size_charge: float = 0.0 # Fixed
    distance_charge_estimate: float = 0.0 # Renamed/Aliased to walking?
    # prompt says "Distance Charges ... (= ₹60 per km per labour)". 
    # Current walking is "₹30 per 50m". 
    # 50m * 20 = 1km. 30 * 20 = 600?
    # Wait. Prompt: "₹3 per 50 meters per labour = ₹60 per km". 
    # 3 * 20 = 60. Correct. 
    # Old code was "₹30 per 50m". 
    # So I need to update the rate in service too.
    
    gst_amount: float = 0.0
    platform_fee: float = 0.0
    per_labour_earning: float = 0.0 # Estimate?
    
    total_estimated_amount: float = 0.0
    
    # Final Bill Details
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None
    
    actual_duration_minutes: int = 0
    waiting_time_minutes: int = 0
    
    labour_cost_time_final: float = 0.0
    waiting_charges_final: float = 0.0
    floor_charges_final: float = 0.0
    walking_charges_final: float = 0.0
    
    service_charge_final: float = 0.0
    special_items_charge_final: float = 0.0
    house_size_charge_final: float = 0.0
    gst_amount_final: float = 0.0
    platform_fee_final: float = 0.0
    per_labour_earning_final: float = 0.0
    
    total_final_amount: float = 0.0
    
    is_locked: bool = False # Price locked at job start
    
    payment_status: str = "pending" # pending, paid, failed, cancelled
    payment_method: str = "online" # online, cash

    # Complete Bill Breakdown (JSON)
    bill_breakdown_json: Optional[str] = None
    
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)


# ----------------
# WALLET TRANSACTIONS
# ----------------
class LabourWalletTransaction(SQLModel, table=True):
    __tablename__ = "labour_wallet_transactions"

    id: Optional[uuid.UUID] = Field(
        default=None,
        sa_column=Column(
            PG_UUID(as_uuid=True),
            primary_key=True,
            server_default=text("gen_random_uuid()"),
        ),
    )
    labour_id: uuid.UUID = Field(foreign_key="labour.id")
    job_id: Optional[uuid.UUID] = Field(foreign_key="orders.id", default=None)
    
    amount: float # Positive for credit, Negative for debit
    description: str
    transaction_type: str = "credit" # credit, debit
    
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)


# ----------------
# JOB ASSIGNMENTS (Multi-Labour)
# ----------------
class JobAssignment(SQLModel, table=True):
    __tablename__ = "job_assignments"

    id: Optional[uuid.UUID] = Field(
        default=None,
        sa_column=Column(
            PG_UUID(as_uuid=True),
            primary_key=True,
            server_default=text("gen_random_uuid()"),
        ),
    )
    job_id: uuid.UUID = Field(foreign_key="orders.id")
    labour_id: uuid.UUID = Field(foreign_key="labour.id")
    
    status: str = "assigned" # assigned, on_the_way, reached, started, completed
    
    # Financials Snapshot for this assignment
    gross_amount: float = 0.0
    platform_fee: float = 0.0
    net_amount: float = 0.0
    
    created_at: Optional[datetime] = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = Field(default_factory=datetime.utcnow)

