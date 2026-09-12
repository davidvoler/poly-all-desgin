import json
import random
import re
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException

from models.auth import SchoolUser
from utils.auth_deps import current_ai_school_user
from utils.db import get_query_results, run_query
from utils.jsonb import coerce_json_list
from utils.ai_course_ownership import assert_lesson_owned
from utils.ai_course_content import sentence_id_for
from utils.generate import (
    generate_words,
    generate_sentences,
    generate_translated_sentence_distractors,
)
from utils.edit.youtube_srt import youtube_id_from_url, youtube_subs
from utils.edit.part_utils import get_ranked_words, text_to_parts

from models.edit.generate_poc_new import (
    Course,
    CourseOption,
    CourseWord,
    CreateVideoModule,
    GenerateForWords,
    ModuleAction,
    Sentence,
    VideoAction,
    VideoCourse,
    VideoCourseOption,
    VideoCourseId,
    VideoItem,
    VideoModule,
    VideoSection,
    VideoSubtitleLine,
    VideoWordRank,
)
from models.edit.ai_course import ExerciseOut, exercise_from_row

router = APIRouter()


def _default_title(course: Course, school_user: SchoolUser) -> str:
    return (
        f"Course {course.lang or 'Unknown'} to {course.to_lang or 'Unknown'} "
        f"school {school_user.school_name or 'Unknown'} "
        f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    )


def _gen_params(course: Course) -> dict:
    """The generation knobs from a course's options (course_simple.course.metadata),
    unwrapped to the plain str/int values utils/generate.py expects."""
    opts = course.metadata or CourseOption()
    return {
        "content_source": str(opts.content_source.value if opts.content_source else "corpus"),
        "provider": str(opts.provider.value if opts.provider else "ollama"),
        "model": str(opts.model.value if opts.model else "gemma4"),
        "max_words": opts.max_sentences_words or 4,
    }


def _words_json(course: Course) -> str:
    return json.dumps([w.model_dump() for w in (course.words or [])])


def _metadata_json(course: Course) -> str:
    return json.dumps((course.metadata or CourseOption()).model_dump())


async def _persist_words(course: Course, school_user: SchoolUser):
    """Write just the course word list — used by generate_words_list so a
    partial Course body can't clobber title / level / metadata / status."""
    sql = """
    UPDATE course_simple.course
    SET words = %s, updated_at = now()
    WHERE course_id = %s AND user_id = %s::text AND school_id = %s
    RETURNING course_id
    """
    return await get_query_results(
        sql, (_words_json(course), course.course_id, school_user.user_id, school_user.school_id)
    )


async def _update_course(course: Course, school_user: SchoolUser):
    """Persist a course row (meta + options + word list), scoped to the
    signed-in user/school."""
    sql = """
    UPDATE course_simple.course
    SET lang = %s,
        to_lang = %s,
        title = %s,
        description = %s,
        status = %s,
        level = %s,
        metadata = %s,
        words = %s,
        updated_at = now()
    WHERE course_id = %s AND user_id = %s::text AND school_id = %s
    RETURNING course_id
    """
    params = (
        course.lang,
        course.to_lang,
        course.title,
        course.description,
        "published" if course.published else "draft",
        course.level or "",
        _metadata_json(course),
        _words_json(course),
        course.course_id,
        school_user.user_id,
        school_user.school_id,
    )
    return await get_query_results(sql, params)


@router.post("/create_course", response_model=Course)
async def create_course(course: Course, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Creates a new course. The `metadata` (CourseOption) block carries the
    generation options — content source, AI provider/model and the
    sentence/exercise knobs — and is stored on the course so every later
    generate_* call can read it back.
    """
    if not course.title:
        course.title = _default_title(course, school_user)

    sql = """
    INSERT INTO course_simple.course
        (lang, to_lang, user_id, school_id, title, description, status, level, metadata, words)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    RETURNING course_id
    """
    params = (
        course.lang,
        course.to_lang,
        school_user.user_id,
        school_user.school_id,
        course.title,
        course.description,
        "draft",
        course.level or "",
        _metadata_json(course),
        _words_json(course),
    )
    rows = await get_query_results(sql, params)
    course.course_id = rows[0]["course_id"] if rows else 0
    return course


@router.post("/update_course", response_model=Course)
async def update_course(course: Course, school_user: SchoolUser = Depends(current_ai_school_user)):
    result = await _update_course(course, school_user)
    if not result:
        raise HTTPException(status_code=404, detail="Course not found")
    return course


def _default_video_title(course: VideoCourse, school_user: SchoolUser) -> str:
    return (
        f"Video course {course.lang or 'Unknown'} to {course.to_lang or 'Unknown'} "
        f"school {school_user.school_name or 'Unknown'} "
        f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    )


def _video_metadata_json(course: VideoCourse) -> str:
    return json.dumps((course.metadata or VideoCourseOption()).model_dump())


def _videos_json(course: VideoCourse) -> str:
    return json.dumps([v.model_dump() for v in (course.videos or [])])


def _row_to_video_course(row: dict) -> VideoCourse:
    return VideoCourse(
        course_id=row["course_id"],
        title=row.get("title") or '',
        description=row.get("description") or '',
        lang=row.get("lang") or '',
        to_lang=row.get("to_lang") or '',
        level=row.get("level") or '',
        videos=[VideoItem(**v) for v in coerce_json_list(row.get("videos"))],
        # modules live in course_simple.module (module_type='video'), not on
        # the course row — populated separately by _load_video_course_owned.
        modules=[],
        metadata=VideoCourseOption(**(row.get("metadata") or {})),
    )


@router.post("/create_video_course", response_model=VideoCourse)
async def create_video_course(course: VideoCourse, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Creates a new video course. Videos are added afterward (a course can
    hold more than one) — see add_video_to_course. The `metadata`
    (VideoCourseOption) block carries the generation options — content
    source, AI provider/model and the target video-section length — and is
    stored on the course, same as a text course's CourseOption.
    """
    if not course.title:
        course.title = _default_video_title(course, school_user)

    sql = """
    INSERT INTO course_simple.course
        (lang, to_lang, user_id, school_id, title, description, status, level, metadata, kind, videos)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 'video', %s)
    RETURNING course_id
    """
    params = (
        course.lang,
        course.to_lang,
        school_user.user_id,
        school_user.school_id,
        course.title,
        course.description,
        "draft",
        course.level or "",
        _video_metadata_json(course),
        _videos_json(course),
    )
    rows = await get_query_results(sql, params)
    course.course_id = rows[0]["course_id"] if rows else 0
    return course


@router.post("/update_video_course", response_model=VideoCourse)
async def update_video_course(course: VideoCourse, school_user: SchoolUser = Depends(current_ai_school_user)):
    sql = """
    UPDATE course_simple.course
    SET lang = %s,
        to_lang = %s,
        title = %s,
        description = %s,
        level = %s,
        metadata = %s,
        videos = %s,
        updated_at = now()
    WHERE course_id = %s AND user_id = %s::text AND school_id = %s AND kind = 'video'
    RETURNING course_id
    """
    params = (
        course.lang,
        course.to_lang,
        course.title,
        course.description,
        course.level or "",
        _video_metadata_json(course),
        _videos_json(course),
        course.course_id,
        school_user.user_id,
        school_user.school_id,
    )
    result = await get_query_results(sql, params)
    if not result:
        raise HTTPException(status_code=404, detail="Video course not found")
    return course


@router.post("/get_video_course", response_model=VideoCourse)
async def get_video_course(body: VideoCourseId, school_user: SchoolUser = Depends(current_ai_school_user)):
    return await _load_video_course_owned(body.course_id, school_user)


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
    )


async def _fetch_video_modules(course_id: int) -> list[VideoModule]:
    rows = await get_query_results(
        "SELECT * FROM course_simple.module WHERE course_id = %s AND module_type = 'video' ORDER BY module_id",
        (course_id,),
    )
    return [_row_to_video_module(r) for r in rows]


async def _load_video_course_owned(course_id: int, school_user: SchoolUser) -> VideoCourse:
    rows = await get_query_results(
        """SELECT * FROM course_simple.course
        WHERE course_id = %s AND user_id = %s::text AND school_id = %s AND kind = 'video'""",
        (course_id, school_user.user_id, school_user.school_id),
    )
    if not rows:
        raise HTTPException(status_code=404, detail="Video course not found")
    course = _row_to_video_course(rows[0])
    course.modules = await _fetch_video_modules(course_id)
    return course


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


async def _save_video_course_videos(course: VideoCourse, school_user: SchoolUser) -> None:
    await run_query(
        """UPDATE course_simple.course SET videos = %s, updated_at = now()
        WHERE course_id = %s AND user_id = %s::text AND school_id = %s""",
        (_videos_json(course), course.course_id, school_user.user_id, school_user.school_id),
    )


def _find_video(course: VideoCourse, video_url: str) -> VideoItem:
    for v in course.videos or []:
        if v.video_url == video_url:
            return v
    raise HTTPException(status_code=404, detail="Video not found on this course")


_WORD_RE = re.compile(r"[^\W\d_]+", re.UNICODE)


def _tokenize(text: str) -> list[str]:
    return [w.lower() for w in _WORD_RE.findall(text) if len(w) > 1]


def _sections_from_subs(subs: list[VideoSubtitleLine], section_len_sec: int) -> list[VideoSection]:
    """Bucket subtitle lines into consecutive `section_len_sec`-second windows."""
    if not subs:
        return []
    sections: list[VideoSection] = []
    bucket_start = subs[0].start
    bucket_text: list[str] = []
    for s in subs:
        if s.start - bucket_start >= section_len_sec and bucket_text:
            sections.append(VideoSection(
                start_seconds=bucket_start,
                end_seconds=s.start,
                text=" ".join(bucket_text).strip(),
            ))
            bucket_start = s.start
            bucket_text = []
        bucket_text.append(s.text)
    if bucket_text:
        last = subs[-1]
        sections.append(VideoSection(
            start_seconds=bucket_start,
            end_seconds=last.start + last.duration,
            text=" ".join(bucket_text).strip(),
        ))
    return sections


@router.post("/download_video_subtitles", response_model=VideoCourse)
async def download_video_subtitles(body: VideoAction, school_user: SchoolUser = Depends(current_ai_school_user)):
    """Fetches the video's subtitles (in the course's learning language) via
    youtube_transcript_api and stores them on the matching video entry."""
    course = await _load_video_course_owned(body.course_id, school_user)
    video = _find_video(course, body.video_url)
    video_id = youtube_id_from_url(body.video_url)
    if not video_id:
        raise HTTPException(status_code=400, detail="Could not parse a YouTube video id from this URL")
    try:
        subs, _seconds = youtube_subs(video_id, course.lang or "en")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Could not download subtitles: {e}")
    video.subtitles = [VideoSubtitleLine(**s) for s in subs]
    await _save_video_course_videos(course, school_user)
    return course


@router.post("/create_video_module", response_model=VideoModule)
async def create_video_module(body: CreateVideoModule, school_user: SchoolUser = Depends(current_ai_school_user)):
    course = await _load_video_course_owned(body.course_id, school_user)
    title = body.title or f"Module {len(course.modules or []) + 1}"
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
    try:
        subs, _seconds = youtube_subs(video_id, course.lang or "en")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Could not download subtitles: {e}")
    module.subtitles = [VideoSubtitleLine(**s) for s in subs]
    await run_query(
        "UPDATE course_simple.module SET subtitles = %s, updated_at = now() WHERE module_id = %s",
        (json.dumps([s.model_dump() for s in module.subtitles]), module.module_id),
    )
    return module


@router.post("/extract_video_words", response_model=VideoCourse)
async def extract_video_words(body: VideoAction, school_user: SchoolUser = Depends(current_ai_school_user)):
    """Ranks the words in the video's subtitles by rarity (wordfreq zipf
    frequency) — requires subtitles to have been downloaded first."""
    course = await _load_video_course_owned(body.course_id, school_user)
    video = _find_video(course, body.video_url)
    if video.subtitles is None:
        raise HTTPException(status_code=400, detail="Download subtitles first")
    tokens = _tokenize(" ".join(s.text for s in video.subtitles))
    try:
        ranked = get_ranked_words(tokens, course.lang or "en")
    except Exception as e:
        # wordfreq needs extra, not-always-installed tokenizer backends for
        # some languages (e.g. MeCab for Japanese) — surface that as a
        # clean 400 instead of a raw 500.
        raise HTTPException(
            status_code=400,
            detail=f"Could not rank words for language '{course.lang}': {e}",
        )
    ranked.sort(key=lambda r: r["rank"])
    video.words = [VideoWordRank(**r) for r in ranked]
    await _save_video_course_videos(course, school_user)
    return course


@router.post("/extract_video_phrases", response_model=VideoCourse)
async def extract_video_phrases(body: VideoAction, school_user: SchoolUser = Depends(current_ai_school_user)):
    """Splits the video's subtitles into short phrases — requires subtitles
    to have been downloaded first."""
    course = await _load_video_course_owned(body.course_id, school_user)
    video = _find_video(course, body.video_url)
    if video.subtitles is None:
        raise HTTPException(status_code=400, detail="Download subtitles first")
    full_text = " ".join(s.text for s in video.subtitles)
    _sentences, phrases = text_to_parts(full_text)
    video.phrases = phrases
    await _save_video_course_videos(course, school_user)
    return course


@router.post("/create_video_sections", response_model=VideoCourse)
async def create_video_sections(body: VideoAction, school_user: SchoolUser = Depends(current_ai_school_user)):
    """Breaks the video's subtitles into time sections of
    metadata.video_section_len_sec each — requires subtitles to have been
    downloaded first."""
    course = await _load_video_course_owned(body.course_id, school_user)
    video = _find_video(course, body.video_url)
    if video.subtitles is None:
        raise HTTPException(status_code=400, detail="Download subtitles first")
    section_len = (course.metadata or VideoCourseOption()).video_section_len_sec or 120
    video.sections = _sections_from_subs(video.subtitles, section_len)
    await _save_video_course_videos(course, school_user)
    return course


@router.post("/generate_words_list", response_model=list[CourseWord])
async def generate_words_list(
    course: Course,
    count: int = 20,
    school_user: SchoolUser = Depends(current_ai_school_user),
):
    """Generate a words list for a course and append it to course.words,
    then persist. Uses the course's own options for content source /
    provider / model."""
    p = _gen_params(course)
    words_so_far = [w.word for w in (course.words or [])]
    words = await generate_words(
        course.lang,
        course.to_lang,
        words_so_far=words_so_far,
        level=course.level,
        content_source=p["content_source"],
        provider=p["provider"],
        model=p["model"],
        max_words=count,
    )
    existing = {w.word for w in (course.words or [])}
    weight = max((w.weight for w in (course.words or [])), default=0)
    for w in words:
        if w in existing:
            continue
        weight += 1
        course.words.append(CourseWord(word=w, weight=weight, used=0))
    await _update_course(course, school_user)
    return course.words


def _spread(total: int, count: int, i: int, produced: int) -> int:
    """How many items to ask for on word `i` of `count`, so they add up
    to `total` — the last word soaks up the remainder."""
    per = max(1, total // max(1, count))
    return (total - produced) if i == count - 1 else per


async def _persist_lesson_sentences(lesson_id: int, lang: str, sentences: list[Sentence]) -> None:
    """Append new sentences to course_simple.lesson.sentences (an ordered
    jsonb list) and upsert each into the content-addressable
    course_simple.sentence cache — mirrors routers/generate_poc.py."""
    rows = await get_query_results(
        "SELECT sentences FROM course_simple.lesson WHERE lesson_id = %s", (lesson_id,)
    )
    existing = coerce_json_list(rows[0].get("sentences")) if rows else []
    have = {e.get("sentence_id") for e in existing}
    for s in sentences:
        if s.sentence_id in have:
            continue
        have.add(s.sentence_id)
        existing.append(
            {
                "sentence_id": s.sentence_id,
                "word": s.word,
                "text": s.sentences,
                "gloss": s.gloss or "",
                "chosen": True,
            }
        )
        await run_query(
            """INSERT INTO course_simple.sentence (sentence_id, lang, text, gloss)
            VALUES (%s, %s, %s, %s) ON CONFLICT (sentence_id) DO NOTHING""",
            (s.sentence_id, lang, s.sentences, s.gloss or ""),
        )
    await run_query(
        "UPDATE course_simple.lesson SET sentences = %s WHERE lesson_id = %s",
        (json.dumps(existing), lesson_id),
    )


@router.post("/sentences_for_word", response_model=list[Sentence])
async def sentences_for_word(generate: GenerateForWords, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Generate sentences for the requested words, spreading `num_elements`
    across them. When `lesson_id` is set, the sentences are also saved
    onto that lesson (course_simple.lesson.sentences).
    """
    course = generate.course
    words = generate.words or []
    p = _gen_params(course)
    if generate.lesson_id:
        await assert_lesson_owned(generate.lesson_id, school_user)

    results: list[Sentence] = []
    for i, w in enumerate(words):
        num_sentences = _spread(generate.num_elements, len(words), i, len(results))
        if num_sentences <= 0:
            continue
        sentences = await generate_sentences(
            lang=course.lang,
            to_lang=course.to_lang,
            word=w,
            level=course.level,
            content_source=p["content_source"],
            provider=p["provider"],
            model=p["model"],
            max_words=p["max_words"],
            num_sentences=num_sentences,
        )
        for s in sentences:
            # generate_sentences returns plain strings from the AI path and
            # {sentences, translation, ...} row dicts from the corpus path.
            text = s.get("sentences") if isinstance(s, dict) else s
            gloss = s.get("translation", "") if isinstance(s, dict) else ""
            if not text:
                continue
            results.append(
                Sentence(
                    sentences=text,
                    word=w,
                    gloss=gloss,
                    sentence_id=sentence_id_for(course.lang or "", text),
                    chosen=True,
                )
            )

    if generate.lesson_id and results:
        await _persist_lesson_sentences(generate.lesson_id, course.lang or "", results)
    return results


@router.post("/exercise_for_word", response_model=list[ExerciseOut])
async def exercise_for_word(generate: GenerateForWords, school_user: SchoolUser = Depends(current_ai_school_user)):
    """
    Create single-choice exercises for the requested words, from
    translated sentences + AI/corpus distractors. When `lesson_id` is
    set, the exercises are inserted into course_simple.exercise and the
    lesson is marked ready.
    """
    course = generate.course
    words = generate.words or []
    p = _gen_params(course)

    lesson = None
    if generate.lesson_id:
        lesson = await assert_lesson_owned(generate.lesson_id, school_user)

    built: list[dict] = []  # {prompt, options: list[str], answer, exercise_type}
    for i, w in enumerate(words):
        num_sentences = _spread(generate.num_elements, len(words), i, len(built))
        if num_sentences <= 0:
            continue
        rows = await generate_translated_sentence_distractors(
            lang=course.lang,
            to_lang=course.to_lang,
            word=w,
            level=course.level,
            content_source=p["content_source"],
            provider=p["provider"],
            model=p["model"],
            max_words=p["max_words"],
            num_sentences=num_sentences,
        )
        for s in rows:
            sentence = s.get("sentence") or s.get(course.lang) or ""
            translation = s.get("translation") or s.get(course.to_lang) or ""
            distractors = [d for d in (s.get("distractors") or []) if d and d != translation]
            options = distractors + [translation]
            random.shuffle(options)
            built.append(
                {
                    "prompt": sentence,
                    "options": options,
                    "answer": translation,
                    "exercise_type": "single_choice",
                    "sentence_id": sentence_id_for(course.lang or "", sentence),
                }
            )

    if not (lesson and generate.lesson_id):
        # Not persisting — hand back a preview shape the client can render.
        return [
            ExerciseOut(
                exercise_id=0,
                lesson_id=generate.lesson_id or 0,
                sentence_id=b["sentence_id"],
                exercise_type=b["exercise_type"],
                prompt=b["prompt"],
                options=b["options"],
                answer=b["answer"],
            )
            for b in built
        ]

    out: list[ExerciseOut] = []
    for b in built:
        rows = await get_query_results(
            """INSERT INTO course_simple.exercise
                (course_id, module_id, lesson_id, exercise_type, sentence, sentence_id, options, answer)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING exercise_id, lesson_id, sentence_id, exercise_type, sentence, options, answer""",
            (
                lesson["course_id"],
                lesson["module_id"],
                generate.lesson_id,
                b["exercise_type"],
                b["prompt"],
                b["sentence_id"],
                json.dumps(b["options"]),
                b["answer"],
            ),
        )
        out.append(exercise_from_row(rows[0]))

    if out:
        await run_query(
            "UPDATE course_simple.lesson SET status = 'ready' WHERE lesson_id = %s",
            (generate.lesson_id,),
        )
    return out
