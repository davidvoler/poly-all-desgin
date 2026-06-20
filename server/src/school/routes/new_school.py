from fastapi import APIRouter, Depends, HTTPException

from editor.models.course import EditorCourse
from editor.routes.editor_courses import _row_to_course
from models.auth import SchoolUser
from utils.auth_deps import current_school_user, current_school_user_full
from utils.db import get_query_results, run_query
from utils.user_school_data import LATEST_TERMS_VERSION

router = APIRouter()

# Roles that may see every course in the school (vs. only their own uploads).
_ALL_COURSES_ROLES = {"admin", "owner", "school_admin", "super_admin",
                      "super_editor", "teacher"}


@router.get("/me", response_model=SchoolUser)
async def get_me(school_user: SchoolUser = Depends(current_school_user_full)):
    """The signed-in user for the school resolved from the request hostname:
    roles, status, signed_terms_version, the computed `permissions` map, and
    school branding. This is the single object the dashboard reads to hide/show
    nav items and to decide whether to gate the Courses page behind the editor
    Terms & Conditions."""
    return school_user


@router.get("/courses", response_model=list[EditorCourse])
async def get_courses(school_user: SchoolUser = Depends(current_school_user)):
    """Courses the caller can see, role-scoped. Admins / super-editors /
    teachers see every course in the school; a plain editor sees only the
    courses they own. Returns the same rich `EditorCourse` shape as
    /api/v1/editor/courses/ (module/lesson/student counts + access overlay) so
    the dashboard table renders unchanged."""
    if not school_user or not school_user.user_id:
        raise HTTPException(status_code=401, detail="Not signed in")
    roles = school_user.roles or []
    school_id = school_user.school_id

    where = ["ca.school_id = %s"]
    params: list = [school_id]
    if not any(r in _ALL_COURSES_ROLES for r in roles):
        # Plain editor (or student with no course role) → only own uploads.
        where.append("c.owner_user_id = %s")
        params.append(school_user.user_id)

    sql = f"""
        SELECT
            c.course_id, c.title, c.description, c.lang, c.to_lang,
            c.status, c.lesson_count, c.metadata,
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
    # The student-count subquery also needs school_id — prepend it so the
    # placeholders line up (same shape as editor_courses.list_editor_courses).
    final_params = (school_id, *params)
    rows = await get_query_results(sql, final_params)
    return [_row_to_course(r) for r in rows]


@router.get("/school_users")
async def get_school_users(school_user: SchoolUser = Depends(current_school_user)):
    """Staff roster for the caller's school. Admins/teachers only. Joins
    user_data.users for the email and flattens `roles[]` to a primary `role`
    so the dashboard's SchoolUser.fromJson maps cleanly."""
    if not school_user or not school_user.user_id:
        raise HTTPException(status_code=401, detail="Not signed in")
    roles = school_user.roles or []
    if not any(r in _ALL_COURSES_ROLES for r in roles):
        raise HTTPException(status_code=403, detail="Forbidden")
    sql = """
        SELECT su.user_id, su.school_id, su.roles, su.status,
               su.signed_terms_version, su.created_at,
               u.email
        FROM school.school_users su
        LEFT JOIN user_data.users u ON u.user_id = su.user_id
        WHERE su.school_id = %s
        ORDER BY su.created_at NULLS LAST, su.user_id
    """
    rows = await get_query_results(sql, [school_user.school_id])
    results = []
    for r in rows:
        r_roles = r.get("roles") or []
        email = r.get("email") or ""
        results.append({
            "school_user_id": r["user_id"],
            "school_id": r["school_id"],
            # users table has no name column today; derive a label from the
            # email local-part so the roster isn't blank.
            "name": email.split("@")[0] if email else "",
            "email": email,
            "role": r_roles[0] if r_roles else "editor",
            "roles": r_roles,
            "assigned_languages": [],
            "courses_owned": 0,
            "status": r.get("status") or "active",
        })
    return results


@router.post("/become_editor")
async def become_editor(school_user: SchoolUser = Depends(current_school_user)):
    """
    if school is public
    1. sign editor terms and conditions
    2. add editor role to school_user
    if school is private
    1. verify editor invitation code
    2. sign editor terms and conditions
    3. add editor role to school_user
    """
    return {}


@router.post("/sign_editor_terms")
async def sign_editor_terms(school_user: SchoolUser = Depends(current_school_user_full)):
    """Record that the caller accepted the current editor Terms & Conditions.
    Stamps the latest version so the courses gate clears on the next /me read."""
    sql = "UPDATE school.school_users SET signed_terms_version = %s WHERE user_id = %s AND school_id = %s"
    params = (LATEST_TERMS_VERSION, school_user.user_id, school_user.school_id)
    await run_query(sql, params)
    return {"message": "Editor terms signed", "version": LATEST_TERMS_VERSION}


@router.get("/editor_terms")
async def get_editor_terms():
    """The editor Terms & Conditions text + its current version. The dashboard
    shows the text on the Courses gate and POSTs back to /sign_editor_terms."""
    with open("legal/EDITOR_TERMS.txt", "r") as f:
        terms = f.read()
    return {"terms": terms, "version": LATEST_TERMS_VERSION}
