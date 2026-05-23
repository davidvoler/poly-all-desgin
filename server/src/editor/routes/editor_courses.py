from fastapi import APIRouter, HTTPException

from editor.models.course import EditorCourse
from utils.db import get_query_results

router = APIRouter()


def _row_to_course(row: dict) -> EditorCourse:
    return EditorCourse(
        course_id=row['course_id'],
        title=row.get('title') or '',
        description=row.get('description') or '',
        lang=row.get('lang') or '',
        to_lang=row.get('to_lang') or '',
        status=row.get('status') or 'draft',
        access=row.get('access'),
        lesson_count=int(row.get('lesson_count') or 0),
        module_count=int(row.get('module_count') or 0),
        student_count=int(row.get('student_count') or 0),
        updated_at=row.get('updated_at'),
    )


@router.get("/", response_model=list[EditorCourse])
async def list_editor_courses(
    school_id: int,
    status: str | None = None,
    lang: str | None = None,
):
    """Powers the Courses table on the school dashboard. Joins three
    sources in one query:
      - course_simple.course → title/lang/status (source of truth)
      - school.course_access  → per-school access overlay
      - school.student_enrollments → student count per course
    Filter by status (e.g. 'review' to see the review queue) or lang."""
    where = ["ca.school_id = %s"]
    params: list = [school_id]
    if status:
        where.append("c.status = %s")
        params.append(status)
    if lang:
        where.append("c.lang = %s")
        params.append(lang)

    sql = f"""
        SELECT
            c.course_id, c.title, c.description, c.lang, c.to_lang,
            c.status, c.lesson_count,
            ca.access, ca.updated_at,
            mods.module_count,
            COALESCE(stu.student_count, 0) AS student_count
        FROM course_simple.course c
        JOIN school.course_access ca ON ca.course_id = c.course_id
        LEFT JOIN (
            SELECT course_id, COUNT(*) AS module_count
            FROM course_simple.module GROUP BY course_id
        ) mods ON mods.course_id = c.course_id
        LEFT JOIN (
            SELECT course_id, COUNT(DISTINCT user_id) AS student_count
            FROM school.student_enrollments WHERE school_id = %s
            GROUP BY course_id
        ) stu ON stu.course_id = c.course_id
        WHERE {' AND '.join(where)}
        ORDER BY c.status, c.updated_at DESC NULLS LAST
    """
    # The student-count subquery also needs the school_id — prepend it so
    # the placeholders line up.
    final_params = (school_id, *params)
    rows = await get_query_results(sql, final_params)
    return [_row_to_course(r) for r in rows]


@router.get("/{course_id}", response_model=EditorCourse)
async def get_editor_course(course_id: int, school_id: int):
    """Single-row variant — used when opening a course detail page."""
    rows = await get_query_results(
        """
        SELECT c.course_id, c.title, c.description, c.lang, c.to_lang,
               c.status, c.lesson_count,
               ca.access, ca.updated_at,
               (SELECT COUNT(*) FROM course_simple.module
                    WHERE course_id = c.course_id) AS module_count,
               (SELECT COUNT(DISTINCT user_id) FROM school.student_enrollments
                    WHERE school_id = %s AND course_id = c.course_id) AS student_count
        FROM course_simple.course c
        LEFT JOIN school.course_access ca
            ON ca.course_id = c.course_id AND ca.school_id = %s
        WHERE c.course_id = %s
        """,
        (school_id, school_id, course_id),
    )
    if not rows:
        raise HTTPException(status_code=404, detail="Course not found")
    return _row_to_course(rows[0])
