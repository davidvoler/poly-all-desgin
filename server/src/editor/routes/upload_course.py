import os
import re
import shutil
import tempfile
import zipfile
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from pydantic import BaseModel

from editor.utils.parse_course import parse_course
from editor.utils.folder_to_db import load_course
from utils.auth_deps import current_user_id
from utils.db import run_query

router = APIRouter()

TEMP_FOLDER = "../content/temp"

# Header line that separates files in a pasted single-document course, e.g.
# `=== module1/lesson1/exercises.txt ===`.
_FILE_HEADER = re.compile(r'^===\s*(.+?)\s*===\s*$')


async def _import_course_folder(course_root: str) -> int:
    """Parse a course folder (must contain course.txt) and load it into the
    DB, then register it as a draft for the school. Returns the new
    course_id. Shared by the zip-upload and text-paste import paths."""
    course_data = parse_course(course_root)
    if not course_data:
        raise HTTPException(
            status_code=400,
            detail="No course.txt found / course folder is malformed",
        )
    course_id = await load_course(course_data)
    if not course_id or course_id < 0:
        raise HTTPException(status_code=500, detail="Failed to load course")

    # TODO: resolve the caller's school instead of hardcoding 1.
    school_id = 1
    await run_query(
        "INSERT INTO school.course_access (school_id, course_id, status) "
        "VALUES (%s, %s, %s)",
        (school_id, course_id, 'draft'),
    )
    return course_id


def _write_document_tree(document: str, root: Path) -> bool:
    """Split a single `=== path ===`-delimited document into files under
    [root]. Returns True when a course.txt was written. Rejects absolute /
    traversing paths so a pasted blob can't escape the temp dir."""
    files: dict[str, list[str]] = {}
    current: str | None = None
    for line in document.split('\n'):
        m = _FILE_HEADER.match(line)
        if m:
            current = m.group(1).strip()
            files.setdefault(current, [])
            continue
        if current is not None:
            files[current].append(line)

    wrote_course = False
    for rel, lines in files.items():
        rel = rel.lstrip('/')
        if not rel or '..' in Path(rel).parts:
            continue
        dest = (root / rel).resolve()
        if not str(dest).startswith(str(root.resolve())):
            continue  # path traversal guard
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text('\n'.join(lines).strip('\n') + '\n', encoding='utf-8')
        if rel == 'course.txt':
            wrote_course = True
    return wrote_course


@router.post("/")
async def upload_course(file: UploadFile = File(...),
                        user_id: int = Depends(current_user_id)):
    """Accept a .zip course archive, extract it, parse, and load it."""
    if not file.filename or not file.filename.lower().endswith(".zip"):
        raise HTTPException(status_code=400, detail="Expected a .zip file")
    Path(TEMP_FOLDER).mkdir(parents=True, exist_ok=True)
    dest = Path(tempfile.mkdtemp(prefix="course_", dir=TEMP_FOLDER))

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

    # The archive contains a single top-level course folder.
    folders = [f for f in os.listdir(dest)
               if not f.startswith('.') and not f.startswith('__')]
    if not folders:
        raise HTTPException(status_code=400, detail="Empty archive")
    course_root = os.path.join(str(dest), folders[0])
    course_id = await _import_course_folder(course_root)
    return {
        "course_id": course_id,
        "message": f"Course uploaded and parsed successfully with id {course_id}",
    }


class CourseDocument(BaseModel):
    # A single document with `=== path ===` headers before each file (the
    # shape the AI-create flow asks the model to produce).
    document: str
    course_title: str | None = None


@router.post("/text")
async def upload_course_text(payload: CourseDocument,
                             user_id: int = Depends(current_user_id)):
    """Import a course pasted as one `=== path ===`-delimited document —
    the output of the 'Create with AI' flow. Splits it into the course
    folder, then runs the same parse + load path as the zip upload."""
    if not payload.document.strip():
        raise HTTPException(status_code=400, detail="Empty document")
    Path(TEMP_FOLDER).mkdir(parents=True, exist_ok=True)
    dest = Path(tempfile.mkdtemp(prefix="course_txt_", dir=TEMP_FOLDER))
    course_root = dest / "course"
    course_root.mkdir(parents=True, exist_ok=True)

    if not _write_document_tree(payload.document, course_root):
        raise HTTPException(
            status_code=400,
            detail="Document has no '=== course.txt ===' section",
        )
    course_id = await _import_course_folder(str(course_root))
    return {
        "course_id": course_id,
        "message": f"Course imported successfully with id {course_id}",
    }
