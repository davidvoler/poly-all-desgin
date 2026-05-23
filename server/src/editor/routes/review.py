from fastapi import APIRouter, HTTPException

from editor.models.course import CourseStatusUpdate, EditorCourse
from editor.routes.editor_courses import get_editor_course
from utils.db import get_query_results, run_query

router = APIRouter()


# Allowed status transitions. Kept as a graph so future additions
# (e.g. "needs_changes") are a one-line edit instead of an `if` ladder.
_ALLOWED: dict[str, set[str]] = {
    'draft':     {'review', 'archived'},
    'review':    {'draft', 'published', 'archived'},
    'published': {'review', 'archived'},
    'archived':  {'draft'},
}
_VALID = {'draft', 'review', 'published', 'archived'}


@router.get("/queue", response_model=list[EditorCourse])
async def review_queue(school_id: int):
    """Convenience endpoint — every course this school has in 'review'.
    The Editors dashboard's Courses page has a tab/filter that hits this
    instead of the general list endpoint."""
    rows = await get_query_results(
        """
        SELECT c.course_id, c.title, c.description, c.lang, c.to_lang,
               c.status, c.lesson_count, ca.access, ca.updated_at,
               (SELECT COUNT(*) FROM course_simple.module
                    WHERE course_id = c.course_id) AS module_count,
               0 AS student_count
        FROM course_simple.course c
        JOIN school.course_access ca ON ca.course_id = c.course_id
        WHERE ca.school_id = %s AND c.status = 'review'
        ORDER BY c.updated_at DESC NULLS LAST
        """,
        (school_id,),
    )
    return [
        EditorCourse(
            course_id=r['course_id'],
            title=r.get('title') or '',
            description=r.get('description') or '',
            lang=r.get('lang') or '',
            to_lang=r.get('to_lang') or '',
            status=r.get('status') or 'review',
            access=r.get('access'),
            lesson_count=int(r.get('lesson_count') or 0),
            module_count=int(r.get('module_count') or 0),
            student_count=int(r.get('student_count') or 0),
            updated_at=r.get('updated_at'),
        )
        for r in rows
    ]


@router.post("/{course_id}/status", response_model=EditorCourse)
async def set_course_status(
    course_id: int,
    payload: CourseStatusUpdate,
    school_id: int,
    actor_user_id: int | None = None,
):
    """Change a course's review status. Validates the transition against
    a small state graph so the API can't be coaxed into illegal moves
    (e.g. draft → published without a review). Logs the change to
    school.activity_log so the Overview "Recent activity" feed picks it
    up."""
    if payload.status not in _VALID:
        raise HTTPException(
            status_code=400,
            detail=f"Unknown status: {payload.status}",
        )

    cur = await get_query_results(
        "SELECT status, title FROM course_simple.course WHERE course_id = %s",
        (course_id,),
    )
    if not cur:
        raise HTTPException(status_code=404, detail="Course not found")
    current_status = cur[0].get('status') or 'draft'
    title = cur[0].get('title') or 'Untitled course'

    if payload.status == current_status:
        # No-op transition — return the current row instead of writing.
        return await get_editor_course(course_id=course_id, school_id=school_id)

    if payload.status not in _ALLOWED.get(current_status, set()):
        raise HTTPException(
            status_code=409,
            detail=f"Cannot move course from {current_status} to {payload.status}",
        )

    await run_query(
        """
        UPDATE course_simple.course
        SET status = %s, updated_at = now()
        WHERE course_id = %s
        """,
        (payload.status, course_id),
    )

    # Log the transition. `kind` matches the front-end's activity-row
    # styling (course_review_submitted vs. course_published vs. generic).
    kind = {
        'review': 'course_review_submitted',
        'published': 'course_published',
        'archived': 'course_archived',
        'draft': 'course_returned_to_draft',
    }.get(payload.status, 'course_status_changed')

    note_suffix = f' — {payload.note}' if payload.note else ''
    summary = (
        f"{kind.replace('_', ' ').capitalize()}: {title}"
        f" ({current_status} → {payload.status}){note_suffix}"
    )
    await run_query(
        """
        INSERT INTO school.activity_log
            (school_id, actor_user_id, kind, summary)
        VALUES (%s, %s, %s, %s)
        """,
        (school_id, actor_user_id, kind, summary),
    )

    return await get_editor_course(course_id=course_id, school_id=school_id)
