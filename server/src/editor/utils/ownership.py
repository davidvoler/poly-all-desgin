"""Ownership checks for the editor endpoints.

A course's `owner_user_id` is set to the school_user_id of whoever
uploaded it (or whoever was assigned ownership later). Editing the
course is allowed when:
  - the caller IS the owner, OR
  - the caller is an admin / super_editor on the same school
    (super_editor exists explicitly for the private-school case
    where one person edits everyone's content).

Used by:
  - POST /api/v1/editor/review/{course_id}/status
  - POST /api/v1/editor/lesson/  (when payload.lesson_id is on a
    course the caller doesn't own)

The dependency raises 403 directly so the route doesn't have to
think about it.
"""
from fastapi import HTTPException

from utils.db import get_query_results


_PRIVILEGED_ROLES = {'admin', 'super_editor'}


async def require_course_editor(
    *,
    course_id: int,
    school_user_id: int | None,
) -> None:
    """Raise 403 if `school_user_id` can't edit `course_id`.
    `school_user_id` is None when the request didn't carry an auth
    header — in that mode we permit (matches the back-compat behaviour
    of `require_school_member` so existing demo flows keep working)."""
    if school_user_id is None:
        return

    course_rows = await get_query_results(
        "SELECT owner_user_id FROM course_simple.course WHERE course_id = %s",
        (course_id,),
    )
    if not course_rows:
        raise HTTPException(status_code=404, detail="Course not found")
    owner_user_id = course_rows[0].get('owner_user_id')

    # NULL owner = legacy / seeded course. Anyone signed in on the
    # right school can edit; the school check already happened in
    # require_school_member.
    if owner_user_id is None:
        return

    if owner_user_id == school_user_id:
        return

    user_rows = await get_query_results(
        "SELECT role FROM school.school_users WHERE school_user_id = %s",
        (school_user_id,),
    )
    role = (user_rows[0].get('role') if user_rows else None) or ''
    if role in _PRIVILEGED_ROLES:
        return

    raise HTTPException(
        status_code=403,
        detail="Only the course owner (or an admin) can edit this course",
    )
