import shutil
import tempfile
import zipfile
from pathlib import Path
from fastapi import APIRouter, File, HTTPException, UploadFile

from editor.utils.parse_course import parse_course

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
    parse_course(str(dest))

    return {}
