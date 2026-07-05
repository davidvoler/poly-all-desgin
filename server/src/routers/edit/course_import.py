from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException
from utils.auth_deps import current_school_user
from models.auth import SchoolUser
from models.edit.course import CourseImport
from utils.course_import_to_db import course_to_db
import tempfile


TEMP_FOLDER = "../content/temp"

router = APIRouter()

def _write_course_file(document: str) -> str:
    # course_to_db()/course_from_file() open() this as a single YAML
    # document (`type: course/module/lesson/exercise` sections separated
    # by `---`) — the same shape export_course_from_db() writes, so
    # export → import round-trips.
    Path(TEMP_FOLDER).mkdir(parents=True, exist_ok=True)
    dest = Path(tempfile.mkdtemp(prefix="course_txt_", dir=TEMP_FOLDER))
    file_path = dest / "course.yaml"
    file_path.write_text(document, encoding="utf-8")
    return str(file_path)


@router.post("/")
async def upload_course_text(payload: CourseImport,
                             school_user: SchoolUser  = Depends(current_school_user)):
    if not payload.document.strip():
        raise HTTPException(status_code=400, detail="Empty document")

    file_path = _write_course_file(payload.document)
    course_id = await course_to_db(file_path, school_user.user_id, school_user.school_id)
    return {
        "course_id": course_id,
        "message": f"Course imported successfully with id {course_id}",
    }