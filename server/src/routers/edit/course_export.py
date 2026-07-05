import shutil
import tempfile
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask
from utils.db import get_query_results
from utils.auth_deps import current_school_user
from models.auth import SchoolUser
from models.edit.course import CourseExport
from utils.course_export_from_db import export_course_from_db


TEMP_FOLDER = "../content/temp"

router = APIRouter()

def _get_course_root() -> Path:
    Path(TEMP_FOLDER).mkdir(parents=True, exist_ok=True)
    dest = Path(tempfile.mkdtemp(prefix="course_export_", dir=TEMP_FOLDER))
    return dest / "course.yaml"


@router.post("/")
async def download_course_text(payload: CourseExport,
                             school_user: SchoolUser  = Depends(current_school_user)):
    sql = """SELECT *
    FROM course_simple.course
    WHERE course_id = %s and user_id = %s and school_id = %s
    """
    results = await get_query_results(sql, (payload.course_id, school_user.user_id, school_user.school_id))
    if not results:
        raise HTTPException(status_code=404, detail="Course not found")

    target_file = _get_course_root()
    await export_course_from_db(payload.course_id, str(target_file))

    return FileResponse(
        path=target_file,
        filename="course.yaml",
        media_type="application/x-yaml",
        background=BackgroundTask(shutil.rmtree, target_file.parent, ignore_errors=True),
    )