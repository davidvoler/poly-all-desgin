import io
import json
import zipfile
from datetime import datetime

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from utils.db import get_query_results

router = APIRouter()


@router.get("/{course_id}")
async def export_course(course_id: int):
    """Bundle the entire course (course row + modules + lessons +
    exercises) into a single zip and stream it back. Mirrors the shape
    `upload_course.py` accepts on the way in: one `course.json` at the
    archive root + a `modules/<n>.yaml` per module so the same
    folder_to_db.py loader works on re-import.

    Builds the zip entirely in memory (typical course payloads are
    well under a few MB) so we don't have to manage a temp dir."""
    course_rows = await get_query_results(
        """
        SELECT course_id, lang, to_lang, title, description, level, status, lesson_count
        FROM course_simple.course
        WHERE course_id = %s
        """,
        (course_id,),
    )
    if not course_rows:
        raise HTTPException(status_code=404, detail="Course not found")
    course = course_rows[0]

    module_rows = await get_query_results(
        """
        SELECT module_id, weight, title, description, words
        FROM course_simple.module
        WHERE course_id = %s
        ORDER BY weight, module_id
        """,
        (course_id,),
    )

    lesson_rows = await get_query_results(
        """
        SELECT lesson_id, module_id, title, description, words
        FROM course_simple.lesson
        WHERE course_id = %s
        ORDER BY module_id, lesson_id
        """,
        (course_id,),
    )

    exercise_rows = await get_query_results(
        """
        SELECT exercise_id, module_id, lesson_id, exercise_type, sentence,
               options, audio, word1, word2, word3, sentence_id, to_sentence_id
        FROM course_simple.exercise
        WHERE course_id = %s
        ORDER BY lesson_id, exercise_id
        """,
        (course_id,),
    )

    # Group lessons/exercises by their parent so the archive is
    # human-readable. Each module's yaml-equivalent gets a `lessons`
    # array, each lesson gets `exercises`.
    lessons_by_module: dict[int, list[dict]] = {}
    for l in lesson_rows:
        lessons_by_module.setdefault(l['module_id'], []).append({
            'lesson_id': l['lesson_id'],
            'title': l.get('title') or '',
            'description': l.get('description') or '',
            'words': list(l.get('words') or []),
            'exercises': [],
        })

    exercises_by_lesson: dict[int, list[dict]] = {}
    for e in exercise_rows:
        exercises_by_lesson.setdefault(e['lesson_id'], []).append({
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
        })
    for lessons in lessons_by_module.values():
        for lesson in lessons:
            lesson['exercises'] = exercises_by_lesson.get(lesson['lesson_id'], [])

    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zf:
        # course.json — top-level metadata. Loader can rebuild the row
        # from this on import.
        zf.writestr('course.json', json.dumps({
            'course_id': course['course_id'],
            'title': course.get('title') or '',
            'description': course.get('description') or '',
            'lang': course.get('lang'),
            'to_lang': course.get('to_lang'),
            'level': course.get('level') or 0,
            'status': course.get('status') or 'draft',
            'lesson_count': course.get('lesson_count') or 0,
            'exported_at': datetime.utcnow().isoformat() + 'Z',
        }, indent=2, ensure_ascii=False))

        # One json per module. Numeric prefix mirrors folder_to_db.py's
        # `module_<n>.yaml` convention so the loader picks them up in
        # order.
        for idx, m in enumerate(module_rows, start=1):
            payload = {
                'module_id': m['module_id'],
                'weight': m.get('weight') or idx,
                'title': m.get('title') or '',
                'description': m.get('description') or '',
                'words': list(m.get('words') or []),
                'modules': [
                    {'lessons': lessons_by_module.get(m['module_id'], [])},
                ],
            }
            zf.writestr(
                f"modules/module_{idx:02d}.json",
                json.dumps(payload, indent=2, ensure_ascii=False),
            )

    buf.seek(0)
    filename = f"course_{course_id}.zip"
    return StreamingResponse(
        buf,
        media_type='application/zip',
        headers={'Content-Disposition': f'attachment; filename="{filename}"'},
    )


def _parse_options(raw):
    """Exercise options were inserted via `json.dumps(...)` in
    folder_to_db.py — they may come back as a string (if the column is
    text) or already-decoded list (if it's jsonb). Handle both."""
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
