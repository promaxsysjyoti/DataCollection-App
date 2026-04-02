from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional
import os, uuid
from datetime import datetime
from pydantic import BaseModel

from ..database import get_db
from ..models import (
    User, Task, Submission, SubmissionFile,
    SubmissionStatus, TaskStatus,
    WalletTransaction, TransactionType
)
from ..schemas.schemas import SubmissionReview
from ..utils.auth import get_current_user, require_admin
from ..config import settings

router = APIRouter(prefix="/submissions", tags=["Submissions"])


# ------------------ NEW MODEL (FIX) ------------------

class SubmissionCreate(BaseModel):
    task_id: str
    notes: Optional[str] = None


# ------------------ HELPERS ------------------

def _file_dict(f: SubmissionFile):
    return {
        "id": str(f.id),
        "filename": f.filename,
        "original_filename": f.original_filename,
        "file_size": f.file_size,
        "mime_type": f.mime_type,
        "created_at": f.created_at.isoformat(),
        "file_url": f"/uploads/submissions/{f.submission_id}/{f.filename}",
    }


def _submission_dict(s: Submission):
    return {
        "id": str(s.id),
        "task_id": str(s.task_id),
        "user_id": str(s.user_id),
        "status": s.status.value,
        "notes": s.notes,
        "admin_remarks": s.admin_remarks,
        "created_at": s.created_at.isoformat(),
        "updated_at": s.updated_at.isoformat(),
        "files": [_file_dict(f) for f in s.files],
        "task_title": s.task.title if s.task else None,
        "user_name": s.user.full_name if s.user else None,
        "user_email": s.user.email if s.user else None,
    }


# ------------------ GET ALL ------------------

@router.get("")
def list_submissions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(Submission)

    if current_user.role.value == "level1":
        query = query.filter(Submission.user_id == current_user.id)

    submissions = query.order_by(Submission.created_at.desc()).all()

    return {
        "success": True,
        "data": [_submission_dict(s) for s in submissions],
        "total": len(submissions),
    }


# ------------------ CREATE ------------------

@router.post("")
async def create_submission(
    payload: SubmissionCreate,
    files: List[UploadFile] = File(default=[]),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        task_uuid = uuid.UUID(payload.task_id)
    except:
        raise HTTPException(status_code=400, detail="Invalid task_id")

    task = db.query(Task).filter(Task.id == task_uuid).first()

    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    if str(task.assigned_to_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="Task not assigned to you")

    if task.status == TaskStatus.approved:
        raise HTTPException(status_code=400, detail="Task already approved")

    submission = Submission(
        task_id=task_uuid,
        user_id=current_user.id,
        notes=payload.notes,
        status=SubmissionStatus.pending,
    )

    db.add(submission)
    db.flush()

    upload_folder = os.path.join(settings.UPLOAD_DIR, "submissions", str(submission.id))
    os.makedirs(upload_folder, exist_ok=True)

    saved_files = []

    for upload in files:
        if not upload.filename:
            continue

        content = await upload.read()

        ext = upload.filename.split(".")[-1]
        new_name = f"{uuid.uuid4()}.{ext}"
        save_path = os.path.join(upload_folder, new_name)

        with open(save_path, "wb") as f:
            f.write(content)

        sub_file = SubmissionFile(
            submission_id=submission.id,
            filename=new_name,
            original_filename=upload.filename,
            file_path=save_path,
            file_size=len(content),
            mime_type=upload.content_type,
        )

        db.add(sub_file)
        saved_files.append(upload.filename)

    task.status = TaskStatus.submitted
    task.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(submission)

    return {
        "success": True,
        "message": "Submission created",
        "data": _submission_dict(submission),
    }


# ------------------ GET ONE ------------------

@router.get("/{submission_id}")
def get_submission(
    submission_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    s = db.query(Submission).filter(Submission.id == uuid.UUID(submission_id)).first()

    if not s:
        raise HTTPException(status_code=404, detail="Not found")

    if current_user.role.value == "level1" and str(s.user_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="Access denied")

    return {"success": True, "data": _submission_dict(s)}