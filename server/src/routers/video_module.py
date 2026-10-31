import json

from fastapi import APIRouter, Depends, HTTPException

from models.auth import SchoolUser
from utils.auth_deps import current_ai_school_user
from utils.db import get_query_results, run_query
from utils.jsonb import coerce_json_list
from utils.edit.youtube_srt import youtube_id_from_url
from utils.edit.part_utils import get_ranked_words, text_to_parts

from models.edit.generate_poc_new import (
    CreateVideoModule,
    ModuleAction,
    VideoCourse,
    VideoCourseOption,
    VideoModule,
    VideoSubtitleLine,
)
# generate_poc_new owns VideoCourse loading/ownership checks and the
# subtitle-download/tokenize helpers shared with the (older) per-video
# pipeline — imported here rather than duplicated. This is a one-directional
# dependency: generate_poc_new.get_video_course imports fetch_video_modules
# back from this module, but only with a deferred (function-local) import,
# so the two files never cycle at module-load time.
from routers.generate_poc_new import (
    _download_subtitles_or_400,
    _load_video_course_owned,
    _tokenize,
)

router = APIRouter()


def _row_to_video_module(row: dict) -> VideoModule:
    subtitles_raw = row.get("subtitles")
    return VideoModule(
        module_id=row["module_id"],
        course_id=row["course_id"],
        title=row.get("title") or '',
        video_url=row.get("video_url") or '',
        subtitles=[VideoSubtitleLine(**s) for s in coerce_json_list(subtitles_raw)]
        if subtitles_raw is not None else None,
        words=list(row["words"]) if row.get("words") is not None else None,
        sentences=list(row["sentences"]) if row.get("sentences") is not None else None,
        phrases=list(row["phrases"]) if row.get("phrases") is not None else None,
    )


async def fetch_video_modules(course_id: int) -> list[VideoModule]:
    rows = await get_query_results(
        "SELECT * FROM course_simple.module WHERE course_id = %s AND module_type = 'video' ORDER BY module_id",
        (course_id,),
    )
    return [_row_to_video_module(r) for r in rows]


async def _load_video_module_owned(
    course_id: int, module_id: int, school_user: SchoolUser
) -> tuple[VideoCourse, VideoModule]:
    """Verifies the course belongs to the signed-in user, then loads the
    module row scoped to that course."""
    course = await _load_video_course_owned(course_id, school_user)
    rows = await get_query_results(
        "SELECT * FROM course_simple.module WHERE module_id = %s AND course_id = %s AND module_type = 'video'",
        (module_id, course_id),
    )
    if not rows:
        raise HTTPException(status_code=404, detail="Module not found on this course")
    return course, _row_to_video_module(rows[0])


@router.post("/create_video_module", response_model=VideoModule)
async def create_video_module(body: CreateVideoModule, school_user: SchoolUser = Depends(current_ai_school_user)):
    course = await _load_video_course_owned(body.course_id, school_user)
    existing = await fetch_video_modules(course.course_id)
    title = body.title or f"Module {len(existing) + 1}"
    rows = await get_query_results(
        """INSERT INTO course_simple.module (course_id, title, module_type)
        VALUES (%s, %s, 'video') RETURNING module_id""",
        (course.course_id, title),
    )
    return VideoModule(module_id=rows[0]["module_id"], course_id=course.course_id, title=title)


@router.post("/update_video_module", response_model=VideoModule)
async def update_video_module(body: VideoModule, school_user: SchoolUser = Depends(current_ai_school_user)):
    await _load_video_course_owned(body.course_id, school_user)  # ownership check
    result = await get_query_results(
        """UPDATE course_simple.module SET title = %s, video_url = %s, updated_at = now()
        WHERE module_id = %s AND course_id = %s AND module_type = 'video'
        RETURNING module_id""",
        (body.title, body.video_url, body.module_id, body.course_id),
    )
    if not result:
        raise HTTPException(status_code=404, detail="Module not found on this course")
    return body


@router.post("/delete_video_module")
async def delete_video_module(body: ModuleAction, school_user: SchoolUser = Depends(current_ai_school_user)):
    await _load_video_course_owned(body.course_id, school_user)  # ownership check
    await run_query(
        "DELETE FROM course_simple.module WHERE module_id = %s AND course_id = %s AND module_type = 'video'",
        (body.module_id, body.course_id),
    )
    return {"success": True}


@router.post("/download_module_subtitles", response_model=VideoModule)
async def download_module_subtitles(body: ModuleAction, school_user: SchoolUser = Depends(current_ai_school_user)):
    """Same as download_video_subtitles, but for a Video Module's own video
    (module.video_url), storing the result in the module's subtitles column."""
    course, module = await _load_video_module_owned(body.course_id, body.module_id, school_user)
    video_id = youtube_id_from_url(module.video_url)
    if not video_id:
        raise HTTPException(status_code=400, detail="Could not parse a YouTube video id from this URL")
    subs = _download_subtitles_or_400(video_id, course.lang or "en")
    module.subtitles = [VideoSubtitleLine(**s) for s in subs]
    await run_query(
        "UPDATE course_simple.module SET subtitles = %s, updated_at = now() WHERE module_id = %s",
        (json.dumps([s.model_dump() for s in module.subtitles]), module.module_id),
    )
    return module


@router.post("/extract_module_content", response_model=VideoModule)
async def extract_module_content(body: ModuleAction, school_user: SchoolUser = Depends(current_ai_school_user)):
    """Ranks the words in the module's subtitles by rarity and pulls out
    short sentences and phrases (each at most metadata.max_sentence_words
    words) — requires subtitles to have been downloaded first. Sentences
    split on '.' only; phrases split on both ',' and '.' (finer-grained)."""
    course, module = await _load_video_module_owned(body.course_id, body.module_id, school_user)
    if module.subtitles is None:
        raise HTTPException(status_code=400, detail="Download subtitles first")
    full_text = " ".join(s.text for s in module.subtitles)
    max_words = (course.metadata or VideoCourseOption()).max_sentence_words or 12

    tokens = _tokenize(full_text)
    try:
        ranked = get_ranked_words(tokens, course.lang or "en")
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Could not rank words for language '{course.lang}': {e}",
        )
    ranked.sort(key=lambda r: r["rank"])
    words = [r["word"] for r in ranked]

    sentences_all, phrases_all = text_to_parts(full_text)
    sentences = [s for s in sentences_all if len(s.split()) <= max_words]
    phrases = [p for p in phrases_all if len(p.split()) <= max_words]

    module.words = words
    module.sentences = sentences
    module.phrases = phrases
    await run_query(
        """UPDATE course_simple.module SET words = %s, sentences = %s, phrases = %s, updated_at = now()
        WHERE module_id = %s""",
        (words, sentences, phrases, module.module_id),
    )
    return module
