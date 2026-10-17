from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError

from app.config import settings
from app.database import Base, engine
from app.models import Category, Transaction, User  # noqa: F401
from app.routers import analytics, auth, categories, transactions


@asynccontextmanager
async def lifespan(_app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="Expense Tracker API",
    description="REST API for the college Expense Tracker project.",
    version="1.0.0",
    lifespan=lifespan,
    redirect_slashes=False,
)

allow_credentials = settings.cors_origins.strip() != "*"
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(_request: Request, exc: RequestValidationError):
    messages = []
    for error in exc.errors():
        loc = error.get("loc", [])
        field = loc[-1] if loc else "field"
        messages.append(f"{field}: {error.get('msg', 'Invalid value')}")
    detail = messages[0] if messages else "Please check the information you entered."
    return JSONResponse(status_code=422, content={"detail": detail})


@app.exception_handler(SQLAlchemyError)
async def database_exception_handler(_request: Request, _exc: SQLAlchemyError):
    return JSONResponse(
        status_code=500,
        content={"detail": "Something went wrong while saving your data. Please try again."},
    )


@app.get("/health")
def health():
    return {"status": "ok"}


app.include_router(auth.router)
app.include_router(categories.router)
app.include_router(transactions.router)
app.include_router(analytics.router)
