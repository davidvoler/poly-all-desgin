import shutil
import tempfile
import zipfile
from pathlib import Path
from fastapi import APIRouter, File, HTTPException, UploadFile

router = APIRouter()

TEMP_FOLDER = "../content/temp"


@router.post("/")
async def upload_course(file: UploadFile = File(...)):
    """Accept a .zip course archive, extract it into a unique subfolder
    under TEMP_FOLDER, and return the destination path + file listing."""
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
    return {
        "path": str(dest),
        "file_count": len(extracted),
        "files": extracted,
    }
