import shutil
import tempfile
import zipfile
from pathlib import Path
from fastapi import APIRouter, File, HTTPException, UploadFile
import os

from editor.utils.parse_course import parse_course
from editor.utils.folder_to_db import load_course

router = APIRouter()

TEMP_FOLDER = "../content/temp"


@router.post("/")
async def upload_course(file: UploadFile = File(...)):
    """Accept a .zip course archive, extract it, and run parse_course
    over the extracted folder. All other logic is stripped for now."""
    
    if not file.filename or not file.filename.lower().endswith(".zip"):
        raise HTTPException(status_code=400, detail="Expected a .zip file")
    Path(TEMP_FOLDER).mkdir(parents=True, exist_ok=True)
    dest = Path(tempfile.mkdtemp(prefix="course_", dir=TEMP_FOLDER))

    # 1. Unzip the upload.
    tmp_zip = dest / "_upload.zip"
    with tmp_zip.open("wb") as out:
        shutil.copyfileobj(file.file, out)
    try:
        with zipfile.ZipFile(tmp_zip) as zf:
            zf.extractall(dest)
    except zipfile.BadZipFile:
        raise HTTPException(status_code=400, detail="File is not a valid zip")
    finally:
        tmp_zip.unlink(missing_ok=True)

    # 2. Parse the extracted folder.
    course_folders = os.listdir(dest)
    course_folder = course_folders[0] if course_folders else None
    if course_folder:
        full_path = os.path.join(str(dest), course_folder)
        course_data = parse_course(full_path)
        # print(course_data)
        upload_result = await load_course(course_data)
    return {}
