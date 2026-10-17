from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.category import Category
from app.models.transaction import Transaction
from app.schemas import CategoryCreate, CategoryUpdate


def list_categories(db: Session, user_id: UUID, category_type: str | None = None) -> list[Category]:
    query = db.query(Category).filter(Category.user_id == user_id)
    if category_type:
        query = query.filter(Category.type == category_type)
    return query.order_by(Category.type, Category.name).all()


def get_owned_category(db: Session, user_id: UUID, category_id: UUID) -> Category:
    category = (
        db.query(Category)
        .filter(Category.id == category_id, Category.user_id == user_id)
        .first()
    )
    if category is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found.",
        )
    return category


def create_category(db: Session, user_id: UUID, data: CategoryCreate) -> Category:
    category = Category(
        user_id=user_id,
        name=data.name,
        type=data.type,
        icon=data.icon,
        color=data.color,
    )
    db.add(category)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You already have a category with this name and type.",
        )
    db.refresh(category)
    return category


def update_category(db: Session, user_id: UUID, category_id: UUID, data: CategoryUpdate) -> Category:
    category = get_owned_category(db, user_id, category_id)
    updates = data.model_dump(exclude_unset=True)
    for field, value in updates.items():
        setattr(category, field, value)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You already have a category with this name and type.",
        )
    db.refresh(category)
    return category


def delete_category(db: Session, user_id: UUID, category_id: UUID) -> None:
    category = get_owned_category(db, user_id, category_id)
    in_use = (
        db.query(Transaction)
        .filter(Transaction.category_id == category.id, Transaction.user_id == user_id)
        .first()
    )
    if in_use:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This category is used by existing transactions. Move or delete those first.",
        )
    db.delete(category)
    db.commit()
