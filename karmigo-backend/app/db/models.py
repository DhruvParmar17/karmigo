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
    email: str
    full_name: Optional[str] = None
    phone: Optional[str] = None


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
    email: str
    phone: Optional[str] = None
    skills: Optional[str] = None
    rating: Optional[float] = 0.0


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
    scheduled_at: Optional[datetime] = None
    total_amount: Optional[float] = 0.0
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
