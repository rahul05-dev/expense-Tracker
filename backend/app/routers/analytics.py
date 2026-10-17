from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas import CategorySpendOut, MonthlyPointOut, SummaryOut
from app.security import get_current_user
from app.services import transaction_service

router = APIRouter(prefix="/api/analytics", tags=["Analytics"])


@router.get("/summary", response_model=SummaryOut)
def summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return transaction_service.get_summary(db, current_user.id)


@router.get("/monthly", response_model=list[MonthlyPointOut])
def monthly(
    year: int | None = Query(default=None, ge=2000, le=2100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    selected_year = year or datetime.now().year
    return transaction_service.get_monthly_analytics(db, current_user.id, selected_year)


@router.get("/by-category", response_model=list[CategorySpendOut])
def by_category(
    year: int | None = Query(default=None, ge=2000, le=2100),
    month: int | None = Query(default=None, ge=1, le=12),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    selected_year = year or datetime.now().year
    return transaction_service.get_category_spending(db, current_user.id, selected_year, month)
