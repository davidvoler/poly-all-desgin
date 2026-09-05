"""
Implement response using tasks 
"""
import json
import random
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


from models.edit.generate_poc_new import (
    Course,
    CourseOption,
    CourseWord,
    GenerateForWords,
    Sentence,
    TaskStart
)
from models.edit.ai_course import ExerciseOut, exercise_from_row

from tasks.broker import broker
from taskiq import Context, TaskiqDepends

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

@broker.task
async def _generate_words_list(
    course: Course,
    count: int = 20,
    school_user: SchoolUser = Depends(current_ai_school_user),
    context: Context = TaskiqDepends(),
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

@router.post("/generate_words_list", response_model=TaskStart)
async def _generate_words_list(
    course: Course,
    count: int = 20,
    school_user: SchoolUser = Depends(current_ai_school_user),
    ):
    task = await _generate_words_list.kiq(course, count, school_user)

    # 2. Return task_id immediately while worker executes in background
    return TaskStart(
        status="QUEUED",
        task_id=task.task_id,
        task_type="generate_words_list"
    )


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

@broker.task
async def _sentences_for_word(generate: GenerateForWords, 
                              school_user: SchoolUser = Depends(current_ai_school_user),
                              context: Context = TaskiqDepends()):
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



@router.post("/sentences_for_word", response_model=TaskStart)
async def sentences_for_word(generate: GenerateForWords, school_user: SchoolUser = Depends(current_ai_school_user)) -> TaskStart:
    task = await _sentences_for_word.kiq(generate, school_user)
    return TaskStart(
        task_id=task.task_id,
        task_type="sentences_for_word",
        status="pending",
    )


@broker.task
async def _exercise_for_word(generate: GenerateForWords, 
                             school_user: SchoolUser = Depends(current_ai_school_user),
                             context: Context = TaskiqDepends()):
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
@router.post("/exercise_for_word", response_model=TaskStart)
async def exercise_for_word(generate: GenerateForWords, school_user: SchoolUser = Depends(current_ai_school_user)):
    task = await _exercise_for_word.kiq(generate, school_user)
    return TaskStart(
        task_id=task.task_id,
        task_type="exercise_for_word",
        status="pending",
    )
