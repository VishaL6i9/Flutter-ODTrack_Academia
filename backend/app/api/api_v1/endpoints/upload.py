import os
import shutil
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from app.core.config import get_settings

router = APIRouter()
settings = get_settings()

@router.post("/", response_model=dict)
async def upload_file(file: UploadFile = File(...)):
    """
    Upload a file as an attachment for OD requests or signatures.
    """
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")

    # Ensure upload directory exists
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    
    # Create safe filename and store
    safe_filename = file.filename.replace(" ", "_")
    file_location = os.path.join(settings.UPLOAD_DIR, safe_filename)
    
    try:
        with open(file_location, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not upload file: {str(e)}")
        
    # Return path relative to the static route we define in main.py
    return {
        "filename": safe_filename,
        "url": f"/static/uploads/{safe_filename}",
        "message": "File uploaded successfully"
    }
