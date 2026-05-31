import shutil
import tempfile
import zipfile
from pathlib import Path
from fastapi import APIRouter, File, HTTPException, UploadFile
import os
from fastapi import APIRouter, Depends
from utils.auth_deps import current_user_id
from editor.utils.parse_course import parse_course
from editor.utils.folder_to_db import load_course
from utils.db import run_query

router = APIRouter()

TEMP_FOLDER = "../content/temp"


@router.post("/")
async def upload_course(file: UploadFile = File(...),user_id: int = Depends(current_user_id)):
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

    course_id = -1

    # 2. Parse the extracted folder.
    course_folders = os.listdir(dest)
    course_folder = course_folders[0] if course_folders else None
    if course_folder:
        full_path = os.path.join(str(dest), course_folder)
        course_data = parse_course(full_path)
        # print(course_data)
        course_id = await load_course(course_data)
    #Todo get current school id
    school_id = 1

    sql = """
    INSERT INTO school.course_access (school_id, course_id, status) VALUES (%s, %s, %s)"""
    params = (school_id, course_id, 'draft')
    await run_query(sql, params)
    return {
        "course_id": course_id, 
        "message": f"Course uploaded and parsed successfully with id {course_id}"
    }
