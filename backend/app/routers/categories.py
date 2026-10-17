from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas import CategoryCreate, CategoryOut, CategoryUpdate, MessageResponse
from app.security import get_current_user
from app.services import category_service

router = APIRouter(prefix="/api/categories", tags=["Categories"])


@router.get("", response_model=list[CategoryOut])
def list_categories(
    type: str | None = Query(default=None, pattern="^(income|expense)$"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return category_service.list_categories(db, current_user.id, type)


@router.post("", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
def create_category(
    payload: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return category_service.create_category(db, current_user.id, payload)


@router.put("/{category_id}", response_model=CategoryOut)
def update_category(
    category_id: UUID,
    payload: CategoryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return category_service.update_category(db, current_user.id, category_id, payload)


@router.delete("/{category_id}", response_model=MessageResponse)
def delete_category(
    category_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    category_service.delete_category(db, current_user.id, category_id)
    return MessageResponse(message="Category deleted.")
