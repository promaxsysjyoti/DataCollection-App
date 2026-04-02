from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
import os
from ..config import settings

router = APIRouter(prefix="/files", tags=["Files"])


@router.get("/{path:path}")
def serve_file(path: str):
    file_path = os.path.join(settings.UPLOAD_DIR, path)
    if not os.path.exists(file_path) or not os.path.isfile(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(file_path)
