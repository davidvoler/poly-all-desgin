import shutil
import tempfile
import zipfile
from pathlib import Path
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile

from editor.utils.folder_to_db import load_course_content
from school.utils.activity import log_activity
from school.utils.auth import require_school_member
from utils.db import get_query_results, run_query

router = APIRouter()

TEMP_FOLDER = "../content/temp"


@router.post("/")
async def upload_course(
    school_id: int = Form(...),
    actor_user_id: int | None = Form(None),
    course_title: str | None = Form(None),
    lang: str | None = Form(None),
    to_lang: str | None = Form(None),
    file: UploadFile = File(...),
    _caller: int | None = Depends(require_school_member),
):
    """Accept a .zip course archive, extract it under TEMP_FOLDER, and
    return the destination path + file listing.

    When the caller supplies `school_id` + `course_title` (the dashboard
    always does), the route also:
      - creates a `course_simple.course` row in 'draft' status,
      - links it to the school via `school.course_access`,
      - writes a `course_upload` activity entry,
    so the dashboard sees the new course on the next list refresh.
    Actual lesson/exercise ingestion from the extracted folder is still
    TODO (folder_to_db.load_course_from_folder isn't wired here yet)."""
    if not file.filename or not file.filename.lower().endswith(".zip"):
        raise HTTPException(status_code=400, detail="Expected a .zip file")

    Path(TEMP_FOLDER).mkdir(parents=True, exist_ok=True)
    dest = Path(tempfile.mkdtemp(prefix="course_", dir=TEMP_FOLDER))
    dest_resolved = dest.resolve()

    # Stream the upload to disk first (zipfile needs a seekable file),
    # then extract.
    tmp_zip = dest / "_upload.zip"
    with tmp_zip.open("wb") as out:
        shutil.copyfileobj(file.file, out)

    try:
        with zipfile.ZipFile(tmp_zip) as zf:
            # Reject zip-slip — entries that resolve outside `dest`.
            for name in zf.namelist():
                try:
                    (dest_resolved / name).resolve().relative_to(dest_resolved)
                except ValueError:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Unsafe path in archive: {name}",
                    )
            zf.extractall(dest)
    except zipfile.BadZipFile:
        raise HTTPException(status_code=400, detail="File is not a valid zip")
    finally:
        tmp_zip.unlink(missing_ok=True)

    extracted = sorted(
        str(p.relative_to(dest))
        for p in dest.rglob("*")
        if p.is_file()
    )

    # Create the course row + access overlay so the dashboard's Courses
    # table picks it up immediately. We use sensible defaults; the
    # uploader can edit metadata after the fact.
    course_id: int | None = None
    derived_title = course_title or _title_from_filename(file.filename)
    inserted = await get_query_results(
        """
        INSERT INTO course_simple.course (title, lang, to_lang, status)
        VALUES (%s, %s, %s, 'draft')
        RETURNING course_id
        """,
        (derived_title, lang or 'ar', to_lang or 'en'),
    )
    ingest = {'modules': 0, 'skipped': 0}
    if inserted:
        course_id = inserted[0]['course_id']
        await run_query(
            """
            INSERT INTO school.course_access (school_id, course_id, access, status)
            VALUES (%s, %s, 'members', 'draft')
            ON CONFLICT (school_id, course_id) DO NOTHING
            """,
            (school_id, course_id),
        )
        # Best-effort ingestion of the extracted folder. Failures here
        # don't abort the upload — the course row + access overlay are
        # already persisted, and the editor can fix things up later.
        try:
            ingest = await load_course_content(course_id, str(dest))
        except Exception:
            # Swallow — load_course_content is itself best-effort, but
            # an outer exception (e.g. permission error) shouldn't 500
            # the whole upload.
            ingest = {'modules': 0, 'skipped': 0}

        modules_blurb = (
            f", {ingest['modules']} modules loaded"
            if ingest['modules'] > 0 else ''
        )
        await log_activity(
            school_id=school_id,
            actor_user_id=actor_user_id,
            kind='course_upload',
            summary=(
                f"Uploaded course {derived_title} — "
                f"{len(extracted)} files{modules_blurb}"
            ),
        )

    return {
        "course_id": course_id,
        "path": str(dest),
        "file_count": len(extracted),
        "modules_loaded": ingest['modules'],
        "modules_skipped": ingest['skipped'],
        "files": extracted,
    }


def _title_from_filename(name: str) -> str:
    """Strip extension + replace separators with spaces so the seeded
    course row reads naturally before the editor fills in a real title."""
    stem = Path(name).stem
    return stem.replace('_', ' ').replace('-', ' ').strip() or 'Untitled course'
