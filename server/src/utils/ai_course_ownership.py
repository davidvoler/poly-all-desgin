"""Shared ownership checks for the Create-with-AI editor/generation
endpoints. Every course_word/module/lesson/sentence/exercise row is only
reachable through its course, and course_simple.course is the only one of
those tables that actually carries user_id/school_id — so every check here
ultimately joins back to it. Never trust a client-supplied id without one
of these; a 404 (not a 403) on mismatch avoids confirming the id exists at
all to a caller who doesn't own it."""
from fastapi import HTTPException

from models.auth import SchoolUser
from utils.db import get_query_results


async def assert_course_owned(course_id: int, school_user: SchoolUser) -> None:
    rows = await get_query_results(
        "SELECT course_id FROM course_simple.course WHERE course_id = %s AND user_id = %s::text AND school_id = %s",
        (course_id, school_user.user_id, school_user.school_id),
    )
    if not rows:
        raise HTTPException(status_code=404, detail="Course not found")


async def assert_lesson_owned(lesson_id: int, school_user: SchoolUser) -> dict:
    """Returns the lesson row (course_id, module_id, status) after
    verifying it belongs to the caller's school+user."""
    rows = await get_query_results(
        "SELECT course_id, module_id, status FROM course_simple.lesson WHERE lesson_id = %s", (lesson_id,)
    )
    if not rows:
        raise HTTPException(status_code=404, detail="Lesson not found")
    await assert_course_owned(rows[0]["course_id"], school_user)
    return rows[0]
