"""Who is signed in to the editor, and what they may access.

Every request names its school twice: the editor site it comes from (the
Origin's hostname, matched against school.schools.school_editor_url, else
school_dashboard_url or school_url) and the
signed session cookie. Both must agree. With EDITOR_REQUIRE_ROLE=true the user
must also be an active member of that school with the `editor` role; without
it, any signed-in user gets in.
"""
import os
from urllib.parse import urlparse

from fastapi import HTTPException, Request
from pydantic import BaseModel

from utils.db import get_query_results
from utils.session import COOKIE_NAME, SessionError, read_token

EDITOR_ROLE = "editor"


class School(BaseModel):
    school_id: int
    name: str
    school_type: str | None = None


class SchoolUser(BaseModel):
    user_id: int
    school_id: int
    # The school_id as text: how courses and AI keys store the school.
    school: str
    school_name: str = ""
    email: str = ""
    roles: list[str] = []


def _hostname(request: Request) -> str:
    origin = request.headers.get("origin") or ""
    return (urlparse(origin).hostname or "").lower()


async def school_from_request(request: Request) -> School:
    """The school the request comes from, by the Origin's hostname: first its
    editor site, then (like the app's server) its dashboard or student site."""
    hostname = _hostname(request)
    rows = []
    if hostname:
        rows = await get_query_results(
            "SELECT school_id, name, school_type FROM school.schools WHERE LOWER(school_editor_url) = %(host)s",
            {"host": hostname},
        )
        if not rows:
            # A separate query, so it still works where school_editor_url is missing.
            rows = await get_query_results(
                """SELECT school_id, name, school_type FROM school.schools
                WHERE LOWER(school_dashboard_url) = %(host)s OR LOWER(school_url) = %(host)s
                ORDER BY (LOWER(school_dashboard_url) = %(host)s) DESC, school_id
                LIMIT 1""",
                {"host": hostname},
            )
    if not rows:
        raise HTTPException(status_code=400, detail=f"No school uses the editor at {hostname or 'this site'}")
    return School(**rows[0])


def editor_role_required() -> bool:
    """Off for now: any signed-in user may use the editor. Set
    EDITOR_REQUIRE_ROLE=true to let in only active members with the editor role."""
    return os.getenv("EDITOR_REQUIRE_ROLE", "").lower() in ("1", "true", "yes")


async def editor_member(user_id: int, school: School) -> SchoolUser | None:
    """The user as an editor of [school], or None. Without EDITOR_REQUIRE_ROLE
    every existing user counts, with whatever roles they have at the school."""
    rows = await get_query_results(
        """
        SELECT u.user_id, u.email, su.roles, su.status FROM user_data.users u
        LEFT JOIN school.school_users su
          ON su.user_id = u.user_id AND su.school_id = %(school_id)s
        WHERE u.user_id = %(user_id)s
        """,
        {"user_id": user_id, "school_id": school.school_id},
    )
    if not rows:
        return None
    if editor_role_required() and not (
        rows[0]["status"] == "active" and EDITOR_ROLE in (rows[0]["roles"] or [])
    ):
        return None
    return SchoolUser(
        user_id=user_id, school_id=school.school_id, school=str(school.school_id),
        school_name=school.name, email=rows[0]["email"] or "", roles=list(rows[0]["roles"] or []),
    )


async def get_school_user(request: Request) -> SchoolUser:
    """FastAPI dependency: the signed-in editor, or 401."""
    token = request.cookies.get(COOKIE_NAME)
    if not token:
        raise HTTPException(status_code=401, detail="Not signed in")
    try:
        user_id, school_id = read_token(token)
    except SessionError:
        raise HTTPException(status_code=401, detail="The session is invalid or has expired. Sign in again.")
    school = await school_from_request(request)
    if school.school_id != school_id:
        # Signed in to another school's editor.
        raise HTTPException(status_code=401, detail="Not signed in to this school")
    user = await editor_member(user_id, school)
    if not user:
        raise HTTPException(status_code=403, detail="This account is no longer an editor here")
    return user


# The query that finds the school of each kind of id, through its course.
_OWNER_QUERIES = {
    "course_id": "SELECT school FROM course_simple.course WHERE course_id = %(id)s",
    "module_id": """SELECT c.school FROM course_simple.module m
        JOIN course_simple.course c ON c.course_id = m.course_id WHERE m.module_id = %(id)s""",
    "lesson_id": """SELECT c.school FROM course_simple.lesson l
        JOIN course_simple.course c ON c.course_id = l.course_id WHERE l.lesson_id = %(id)s""",
    "exercise_id": """SELECT c.school FROM course_simple.exercise e
        JOIN course_simple.course c ON c.course_id = e.course_id WHERE e.exercise_id = %(id)s""",
}


async def require_access(user: SchoolUser, **ids: int | None) -> None:
    """Raises 404 unless each given course, module, lesson or exercise belongs
    to the user's school. Ids that are None or 0 are skipped (not created yet).

        await require_access(user, course_id=c, module_id=m)
    """
    for kind, value in ids.items():
        if not value:
            continue
        rows = await get_query_results(_OWNER_QUERIES[kind], {"id": value})
        if not rows or rows[0]["school"] != user.school:
            # 404, not 403, so other schools' ids are not revealed.
            raise HTTPException(status_code=404, detail=f"No such {kind.removesuffix('_id')}")


async def can_manage_school_keys(school_user: SchoolUser) -> bool:
    """Whether the user may add, replace or remove the school's AI keys.
    Every editor may, as only editors can sign in."""
    return EDITOR_ROLE in school_user.roles
