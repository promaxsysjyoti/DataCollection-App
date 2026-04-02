from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
import logging

from .database import engine, Base
from .config import settings

# ✅ IMPORTANT: Import ALL models properly
from .models.models import User, Task, Submission, SubmissionFile, WalletTransaction

from .routers import (
    auth_router,
    users_router,
    tasks_router,
    submissions_router,
    wallet_router,
    dashboard_router,
    files_router,
)

from .utils.auth import hash_password


# ------------------ LOGGING ------------------

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# ------------------ CREATE DATABASE TABLES ------------------

Base.metadata.create_all(bind=engine)


# ------------------ CREATE DIRECTORIES ------------------

UPLOAD_DIR = settings.UPLOAD_DIR

try:
    os.makedirs(os.path.join(UPLOAD_DIR, "profiles"), exist_ok=True)
    os.makedirs(os.path.join(UPLOAD_DIR, "submissions"), exist_ok=True)
    logger.info(f"Upload directories ready at {UPLOAD_DIR}")
except Exception as e:
    logger.error(f"Error creating upload directories: {e}")


# ------------------ APP INIT ------------------

app = FastAPI(
    title="Audio Dataset System API",
    description="Backend API for Audio Dataset Collection Platform",
    version="2.0.1",
)


# ------------------ CORS ------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ⚠ change in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ------------------ STATIC FILES ------------------

if os.path.exists(UPLOAD_DIR):
    app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")
else:
    logger.warning("UPLOAD_DIR does not exist, static files not mounted")


# ------------------ ROUTERS ------------------

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(tasks_router)
app.include_router(submissions_router)
app.include_router(wallet_router)
app.include_router(dashboard_router)
app.include_router(files_router)


# ------------------ ROOT ------------------

@app.get("/")
def root():
    return {
        "message": "Audio Dataset System API",
        "version": "2.0.1",
        "status": "running",
    }


# ------------------ STARTUP EVENT ------------------

@app.on_event("startup")
def seed_default_admin():
    """Create default admin + level1 user if not exists."""
    from .database import SessionLocal
    from .models.models import User, UserRole

    db = SessionLocal()

    try:
        existing_admin = db.query(User).filter(User.email == "admin@example.com").first()

        if not existing_admin:
            admin = User(
                email="admin@example.com",
                hashed_password=hash_password("admin123"),
                full_name="System Admin",
                role=UserRole.admin,
                wallet_balance=10000.0,
            )

            level1 = User(
                email="level1@example.com",
                hashed_password=hash_password("level1123"),
                full_name="Demo Level1 User",
                role=UserRole.level1,
                wallet_balance=0.0,
            )

            db.add(admin)
            db.add(level1)
            db.commit()

            logger.info("✅ Default users created")
            logger.info("ADMIN: admin@example.com / admin123")
            logger.info("LEVEL1: level1@example.com / level1123")

    except Exception as e:
        logger.error(f"⚠ Seed error: {e}")
        db.rollback()

    finally:
        db.close()