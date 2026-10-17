from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas import MessageResponse, TransactionCreate, TransactionOut, TransactionUpdate
from app.security import get_current_user
from app.services import transaction_service

router = APIRouter(prefix="/api/transactions", tags=["Transactions"])


def to_out(transaction) -> TransactionOut:
    return TransactionOut(
        id=transaction.id,
        title=transaction.title,
        amount=transaction.amount,
        type=transaction.type,
        category_id=transaction.category_id,
        category_name=transaction.category.name,
        date=transaction.date,
        description=transaction.description,
        created_at=transaction.created_at,
    )


@router.get("", response_model=list[TransactionOut])
def list_transactions(
    type: str | None = Query(default=None, pattern="^(income|expense)$"),
    category_id: UUID | None = None,
    start_date: date | None = None,
    end_date: date | None = None,
    search: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    items = transaction_service.list_transactions(
        db,
        current_user.id,
        transaction_type=type,
        category_id=category_id,
        start_date=start_date,
        end_date=end_date,
        search=search,
    )
    return [to_out(item) for item in items]


@router.post("", response_model=TransactionOut, status_code=status.HTTP_201_CREATED)
def create_transaction(
    payload: TransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return to_out(transaction_service.create_transaction(db, current_user.id, payload))


@router.get("/{transaction_id}", response_model=TransactionOut)
def get_transaction(
    transaction_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return to_out(transaction_service.get_owned_transaction(db, current_user.id, transaction_id))


@router.put("/{transaction_id}", response_model=TransactionOut)
def update_transaction(
    transaction_id: UUID,
    payload: TransactionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return to_out(
        transaction_service.update_transaction(db, current_user.id, transaction_id, payload)
    )


@router.delete("/{transaction_id}", response_model=MessageResponse)
def delete_transaction(
    transaction_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    transaction_service.delete_transaction(db, current_user.id, transaction_id)
    return MessageResponse(message="Transaction deleted.")
