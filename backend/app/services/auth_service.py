from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.category import Category
from app.models.user import User
from app.security import create_access_token, hash_password, verify_password

DEFAULT_CATEGORIES = [
    ("Food", "expense", "restaurant", "#EF4444"),
    ("Transport", "expense", "directions_car", "#F97316"),
    ("Shopping", "expense", "shopping_bag", "#EC4899"),
    ("Bills", "expense", "receipt_long", "#8B5CF6"),
    ("Entertainment", "expense", "movie", "#06B6D4"),
    ("Education", "expense", "school", "#3B82F6"),
    ("Health", "expense", "favorite", "#22C55E"),
    ("Other", "expense", "more_horiz", "#6B7280"),
    ("Salary", "income", "payments", "#16A34A"),
    ("Freelance", "income", "laptop", "#0D9488"),
    ("Business", "income", "storefront", "#2563EB"),
    ("Gift", "income", "card_giftcard", "#D946EF"),
    ("Other", "income", "more_horiz", "#6B7280"),
]


def seed_default_categories(db: Session, user_id: UUID) -> None:
    for name, category_type, icon, color in DEFAULT_CATEGORIES:
        db.add(
            Category(
                user_id=user_id,
                name=name,
                type=category_type,
                icon=icon,
                color=color,
            )
        )


def register_user(db: Session, name: str, email: str, password: str) -> tuple[User, str]:
    existing = db.query(User).filter(User.email == email.lower()).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email already exists.",
        )

    user = User(
        name=name,
        email=email.lower(),
        hashed_password=hash_password(password),
    )
    db.add(user)
    db.flush()
    seed_default_categories(db, user.id)
    db.commit()
    db.refresh(user)
    token = create_access_token(str(user.id))
    return user, token


def authenticate_user(db: Session, email: str, password: str) -> tuple[User, str]:
    user = db.query(User).filter(User.email == email.lower()).first()
    if user is None or not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
        )
    token = create_access_token(str(user.id))
    return user, token
