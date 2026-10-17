from datetime import date
from decimal import Decimal
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import extract, func
from sqlalchemy.orm import Session, joinedload

from app.models.category import Category
from app.models.transaction import Transaction
from app.schemas import TransactionCreate, TransactionUpdate

MONTH_NAMES = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
]


def _get_owned_category(db: Session, user_id: UUID, category_id: UUID, expected_type: str) -> Category:
    category = (
        db.query(Category)
        .filter(Category.id == category_id, Category.user_id == user_id)
        .first()
    )
    if category is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please choose a valid category.",
        )
    if category.type != expected_type:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The category type must match the transaction type.",
        )
    return category


def list_transactions(
    db: Session,
    user_id: UUID,
    transaction_type: str | None = None,
    category_id: UUID | None = None,
    start_date: date | None = None,
    end_date: date | None = None,
    search: str | None = None,
) -> list[Transaction]:
    query = (
        db.query(Transaction)
        .options(joinedload(Transaction.category))
        .filter(Transaction.user_id == user_id)
    )
    if transaction_type:
        query = query.filter(Transaction.type == transaction_type)
    if category_id:
        query = query.filter(Transaction.category_id == category_id)
    if start_date:
        query = query.filter(Transaction.date >= start_date)
    if end_date:
        query = query.filter(Transaction.date <= end_date)
    if search:
        like = f"%{search.strip()}%"
        query = query.filter(
            Transaction.title.ilike(like) | Transaction.description.ilike(like)
        )
    return query.order_by(Transaction.date.desc(), Transaction.created_at.desc()).all()


def get_owned_transaction(db: Session, user_id: UUID, transaction_id: UUID) -> Transaction:
    transaction = (
        db.query(Transaction)
        .options(joinedload(Transaction.category))
        .filter(Transaction.id == transaction_id, Transaction.user_id == user_id)
        .first()
    )
    if transaction is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found.",
        )
    return transaction


def create_transaction(db: Session, user_id: UUID, data: TransactionCreate) -> Transaction:
    _get_owned_category(db, user_id, data.category_id, data.type)
    transaction = Transaction(
        user_id=user_id,
        category_id=data.category_id,
        title=data.title,
        amount=data.amount,
        type=data.type,
        description=data.description,
        date=data.date,
    )
    db.add(transaction)
    db.commit()
    db.refresh(transaction)
    return get_owned_transaction(db, user_id, transaction.id)


def update_transaction(
    db: Session, user_id: UUID, transaction_id: UUID, data: TransactionUpdate
) -> Transaction:
    transaction = get_owned_transaction(db, user_id, transaction_id)
    updates = data.model_dump(exclude_unset=True)

    next_type = updates.get("type", transaction.type)
    next_category_id = updates.get("category_id", transaction.category_id)
    _get_owned_category(db, user_id, next_category_id, next_type)

    for field, value in updates.items():
        setattr(transaction, field, value)

    db.commit()
    return get_owned_transaction(db, user_id, transaction.id)


def delete_transaction(db: Session, user_id: UUID, transaction_id: UUID) -> None:
    transaction = get_owned_transaction(db, user_id, transaction_id)
    db.delete(transaction)
    db.commit()


def get_summary(db: Session, user_id: UUID) -> dict[str, Decimal]:
    rows = (
        db.query(Transaction.type, func.coalesce(func.sum(Transaction.amount), 0))
        .filter(Transaction.user_id == user_id)
        .group_by(Transaction.type)
        .all()
    )
    totals = {row[0]: Decimal(row[1]) for row in rows}
    income = totals.get("income", Decimal("0.00"))
    expense = totals.get("expense", Decimal("0.00"))
    return {
        "total_income": income,
        "total_expense": expense,
        "balance": income - expense,
    }


def get_monthly_analytics(db: Session, user_id: UUID, year: int) -> list[dict]:
    rows = (
        db.query(
            extract("month", Transaction.date).label("month"),
            Transaction.type,
            func.coalesce(func.sum(Transaction.amount), 0),
        )
        .filter(Transaction.user_id == user_id, extract("year", Transaction.date) == year)
        .group_by("month", Transaction.type)
        .all()
    )

    by_month: dict[int, dict[str, Decimal]] = {
        month: {"income": Decimal("0.00"), "expense": Decimal("0.00")}
        for month in range(1, 13)
    }
    for month, transaction_type, amount in rows:
        by_month[int(month)][transaction_type] = Decimal(amount)

    return [
        {
            "month": month,
            "month_name": MONTH_NAMES[month - 1],
            "income": values["income"],
            "expense": values["expense"],
        }
        for month, values in by_month.items()
    ]


def get_category_spending(
    db: Session, user_id: UUID, year: int, month: int | None = None
) -> list[dict]:
    query = (
        db.query(
            Category.id,
            Category.name,
            Category.color,
            func.coalesce(func.sum(Transaction.amount), 0),
        )
        .join(Transaction, Transaction.category_id == Category.id)
        .filter(
            Transaction.user_id == user_id,
            Transaction.type == "expense",
            extract("year", Transaction.date) == year,
        )
    )
    if month:
        query = query.filter(extract("month", Transaction.date) == month)

    rows = query.group_by(Category.id, Category.name, Category.color).order_by(
        func.sum(Transaction.amount).desc()
    ).all()

    return [
        {
            "category_id": category_id,
            "category_name": name,
            "color": color,
            "amount": Decimal(amount),
        }
        for category_id, name, color, amount in rows
        if Decimal(amount) > 0
    ]
