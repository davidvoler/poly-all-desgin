from fastapi import APIRouter, HTTPException

from editor.models.course import LessonData
from utils.db import get_query_results, run_query

router = APIRouter()


@router.post("/")
async def add_lesson_to_course(data: LessonData):
    """Save (or overwrite) a single lesson's exercises without re-uploading
    the whole course. Used by the per-lesson editor on the dashboard.

    Insert vs. update is decided by whether the payload carries a lesson_id:
      - No lesson_id → INSERT a fresh row in `course_simple.lesson`
      - With lesson_id → UPDATE the lesson row + replace its exercises
    Exercises are wiped-and-reinserted because the editor sends the full
    array; partial diffs would need stable per-exercise ids the UI
    doesn't carry yet."""
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

    import json
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
