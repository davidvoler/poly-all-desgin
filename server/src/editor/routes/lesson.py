import json

from fastapi import APIRouter, Header, HTTPException

from editor.models.course import LessonData, LessonDetail
from editor.utils.ownership import require_course_editor
from utils.db import get_query_results, run_query

router = APIRouter()


def _parse_options(raw):
    """Exercise options are inserted as `json.dumps(...)`. Postgres may
    hand them back as a string (text column) or already-decoded list
    (jsonb). Handle both."""
    if raw is None:
        return []
    if isinstance(raw, (list, dict)):
        return raw
    if isinstance(raw, str):
        try:
            return json.loads(raw)
        except (TypeError, ValueError):
            return []
    return []


@router.get("/{lesson_id}", response_model=LessonDetail)
async def get_lesson_detail(lesson_id: int):
    """Lesson row + ordered list of its exercises. Used by the
    dashboard's per-lesson editor; the shape matches LessonData so the
    dashboard can hand the response straight back as a save payload."""
    lesson_rows = await get_query_results(
        """
        SELECT lesson_id, course_id, module_id, title, description, words
        FROM course_simple.lesson
        WHERE lesson_id = %s
        """,
        (lesson_id,),
    )
    if not lesson_rows:
        raise HTTPException(status_code=404, detail="Lesson not found")
    l = lesson_rows[0]

    exercise_rows = await get_query_results(
        """
        SELECT exercise_id, exercise_type, sentence, options, audio,
               word1, word2, word3, sentence_id, to_sentence_id
        FROM course_simple.exercise
        WHERE lesson_id = %s
        ORDER BY exercise_id
        """,
        (lesson_id,),
    )
    exercises = [{
        'exercise_id': e['exercise_id'],
        'type': e.get('exercise_type') or '',
        'text': e.get('sentence') or '',
        'options': _parse_options(e.get('options')),
        'voice': e.get('audio') or '',
        'word1': e.get('word1') or '',
        'word2': e.get('word2') or '',
        'word3': e.get('word3') or '',
        'sentence_id': e.get('sentence_id'),
        'sentence_to_id': e.get('to_sentence_id'),
    } for e in exercise_rows]

    return LessonDetail(
        lesson_id=l['lesson_id'],
        course_id=l['course_id'],
        module_id=l['module_id'],
        title=l.get('title') or '',
        description=l.get('description') or '',
        words=list(l.get('words') or []),
        exercises=exercises,
    )


@router.post("/")
async def add_lesson_to_course(
    data: LessonData,
    x_school_user_id: int | None = Header(default=None),
):
    """Save (or overwrite) a single lesson's exercises without re-uploading
    the whole course. Used by the per-lesson editor on the dashboard.

    Insert vs. update is decided by whether the payload carries a lesson_id:
      - No lesson_id → INSERT a fresh row in `course_simple.lesson`
      - With lesson_id → UPDATE the lesson row + replace its exercises
    Exercises are wiped-and-reinserted because the editor sends the full
    array; partial diffs would need stable per-exercise ids the UI
    doesn't carry yet.

    Ownership: only the course owner (or admin / super_editor) can save
    here. When the request comes without an auth header, the check
    no-ops so existing demo flows keep working."""
    await require_course_editor(
        course_id=data.course_id,
        school_user_id=x_school_user_id,
    )
    if data.lesson_id is None:
        inserted = await get_query_results(
            """
            INSERT INTO course_simple.lesson (course_id, module_id, title, words)
            VALUES (%s, %s, %s, %s)
            RETURNING lesson_id
            """,
            (data.course_id, data.module_id, data.title, data.words),
        )
        if not inserted:
            raise HTTPException(status_code=500, detail="Insert failed")
        lesson_id = inserted[0]['lesson_id']
    else:
        await run_query(
            """
            UPDATE course_simple.lesson
            SET title = %s, words = %s
            WHERE lesson_id = %s
            """,
            (data.title, data.words, data.lesson_id),
        )
        lesson_id = data.lesson_id
        await run_query(
            "DELETE FROM course_simple.exercise WHERE lesson_id = %s",
            (lesson_id,),
        )

    for ex in data.exercises:
        await run_query(
            """
            INSERT INTO course_simple.exercise
                (course_id, module_id, lesson_id, exercise_type, sentence,
                 options, audio, word1, word2, word3, sentence_id, to_sentence_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                data.course_id, data.module_id, lesson_id,
                ex.get('type', ''), ex.get('text', ''),
                json.dumps(ex.get('options', [])),
                ex.get('voice', ''),
                ex.get('word1', ''), ex.get('word2', ''), ex.get('word3', ''),
                ex.get('sentence_id'), ex.get('sentence_to_id'),
            ),
        )

    return {"lesson_id": lesson_id, "exercise_count": len(data.exercises)}
