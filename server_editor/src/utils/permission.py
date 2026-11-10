"""Who is signed in to the editor, and what they may access.

Every request names its school twice: the editor site it comes from (the
Origin's hostname, matched against school.schools.school_editor_url) and the
signed session cookie. Both must agree, and the user must still be an active
member of that school with the `editor` role.
"""
from urllib.parse import urlparse

from fastapi import HTTPException, Request
from pydantic import BaseModel

from utils.db import get_query_results
from utils.session import COOKIE_NAME, SessionError, read_token

EDITOR_ROLE = "editor"


class School(BaseModel):
    school_id: int
    name: str


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
    """The school whose editor site the request comes from."""
    hostname = _hostname(request)
    rows = await get_query_results(
        "SELECT school_id, name FROM school.schools WHERE LOWER(school_editor_url) = %(host)s",
        {"host": hostname},
    ) if hostname else []
    if not rows:
        raise HTTPException(status_code=400, detail=f"No school uses the editor at {hostname or 'this site'}")
    return School(**rows[0])


async def editor_member(user_id: int, school: School) -> SchoolUser | None:
    """The user as an active editor of [school], or None."""
    rows = await get_query_results(
        """
        SELECT u.user_id, u.email, su.roles FROM user_data.users u
        JOIN school.school_users su ON su.user_id = u.user_id
        WHERE u.user_id = %(user_id)s AND su.school_id = %(school_id)s
          AND su.status = 'active' AND %(role)s = ANY(su.roles)
        """,
        {"user_id": user_id, "school_id": school.school_id, "role": EDITOR_ROLE},
    )
    if not rows:
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
