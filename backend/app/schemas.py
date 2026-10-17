from datetime import date as date_type, datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class MessageResponse(BaseModel):
    message: str


class UserCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(min_length=6, max_length=72)

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, value: str) -> str:
        cleaned = value.strip()
        if len(cleaned) < 2:
            raise ValueError("Name must be at least 2 characters.")
        return cleaned


class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1)


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    email: EmailStr


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class CategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    type: str
    icon: str | None = None
    color: str | None = None

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Category name cannot be empty.")
        return cleaned

    @field_validator("type")
    @classmethod
    def valid_type(cls, value: str) -> str:
        normalized = value.lower().strip()
        if normalized not in {"income", "expense"}:
            raise ValueError("Type must be income or expense.")
        return normalized


class CategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=80)
    icon: str | None = None
    color: str | None = None

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, value: str | None) -> str | None:
        if value is None:
            return value
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Category name cannot be empty.")
        return cleaned


class CategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    type: str
    icon: str | None
    color: str | None


class TransactionCreate(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    amount: Decimal = Field(gt=0)
    type: str
    category_id: UUID
    date: date_type
    description: str | None = Field(default=None, max_length=500)

    @field_validator("title")
    @classmethod
    def title_not_blank(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Title cannot be empty.")
        return cleaned

    @field_validator("type")
    @classmethod
    def valid_type(cls, value: str) -> str:
        normalized = value.lower().strip()
        if normalized not in {"income", "expense"}:
            raise ValueError("Type must be income or expense.")
        return normalized

    @field_validator("description")
    @classmethod
    def clean_description(cls, value: str | None) -> str | None:
        if value is None:
            return None
        cleaned = value.strip()
        return cleaned or None


class TransactionUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=120)
    amount: Decimal | None = Field(default=None, gt=0)
    type: str | None = None
    category_id: UUID | None = None
    date: date_type | None = None
    description: str | None = Field(default=None, max_length=500)

    @field_validator("title")
    @classmethod
    def title_not_blank(cls, value: str | None) -> str | None:
        if value is None:
            return value
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Title cannot be empty.")
        return cleaned

    @field_validator("type")
    @classmethod
    def valid_type(cls, value: str | None) -> str | None:
        if value is None:
            return value
        normalized = value.lower().strip()
        if normalized not in {"income", "expense"}:
            raise ValueError("Type must be income or expense.")
        return normalized


class TransactionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    title: str
    amount: Decimal
    type: str
    category_id: UUID
    category_name: str
    date: date_type
    description: str | None
    created_at: datetime


class SummaryOut(BaseModel):
    total_income: Decimal
    total_expense: Decimal
    balance: Decimal


class MonthlyPointOut(BaseModel):
    month: int
    month_name: str
    income: Decimal
    expense: Decimal


class CategorySpendOut(BaseModel):
    category_id: UUID
    category_name: str
    color: str | None
    amount: Decimal
