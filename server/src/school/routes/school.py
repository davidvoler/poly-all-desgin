from fastapi import APIRouter, HTTPException

from school.models.school import School, SchoolCreate, SchoolStats
from school.routes.users import _hash_password
from utils.db import get_query_results, run_query

router = APIRouter()


_SCHOOL_COLS = (
    "school_id, slug, name, plan, streak_days, languages_taught, "
    "native_languages, logo_url, primary_color, created_at, updated_at"
)


def _row_to_school(row: dict) -> School:
    """Maps a `school.schools` row to the response model. Defensive on
    nulls so a freshly-seeded row (no logo, empty languages) still
    serialises cleanly."""
    return School(
        school_id=row.get('school_id'),
        slug=row.get('slug') or '',
        name=row.get('name') or '',
        plan=row.get('plan') or 'free',
        streak_days=row.get('streak_days') or 0,
        languages_taught=list(row.get('languages_taught') or []),
        native_languages=list(row.get('native_languages') or []),
        logo_url=row.get('logo_url'),
        primary_color=row.get('primary_color') or '#1E88E5',
        created_at=row.get('created_at'),
        updated_at=row.get('updated_at'),
    )


@router.get("/", response_model=list[School])
async def list_schools():
    """List every school — only used by the create-school onboarding
    flow to check if any school exists yet."""
    rows = await get_query_results(
        f"SELECT {_SCHOOL_COLS} FROM school.schools ORDER BY created_at",
        (),
    )
    return [_row_to_school(r) for r in rows]


@router.get("/{school_id}", response_model=School)
async def get_school(school_id: int):
    rows = await get_query_results(
        f"SELECT {_SCHOOL_COLS} FROM school.schools WHERE school_id = %s",
        (school_id,),
    )
    if not rows:
        raise HTTPException(status_code=404, detail="School not found")
    return _row_to_school(rows[0])


@router.get("/by_slug/{slug}", response_model=School)
async def get_school_by_slug(slug: str):
    rows = await get_query_results(
        f"SELECT {_SCHOOL_COLS} FROM school.schools WHERE slug = %s",
        (slug,),
    )
    if not rows:
        raise HTTPException(status_code=404, detail="School not found")
    return _row_to_school(rows[0])


@router.post("/", response_model=School)
async def create_school(payload: SchoolCreate):
    """Onboards a school + seeds its owner. Slug must be globally
    unique (enforced by the schools_slug_uq constraint); we surface that
    as a 409 instead of letting psycopg's UniqueViolation leak."""
    existing = await get_query_results(
        "SELECT 1 FROM school.schools WHERE slug = %s",
        (payload.slug,),
    )
    if existing:
        raise HTTPException(status_code=409, detail="Slug already in use")

    insert = await get_query_results(
        """
        INSERT INTO school.schools (slug, name, plan)
        VALUES (%s, %s, %s)
        RETURNING school_id
        """,
        (payload.slug, payload.name, payload.plan),
    )
    if not insert:
        raise HTTPException(status_code=500, detail="Failed to create school")
    school_id = insert[0]['school_id']

    # Seed owner with a bcrypt-hashed password so the new school is
    # immediately usable from the login screen.
    pw_hash = _hash_password(payload.owner_password)
    await run_query(
        """
        INSERT INTO school.school_users
            (school_id, user_id, name, email, password_hash, role)
        VALUES (%s, NULL, %s, %s, %s, 'owner')
        """,
        (school_id, payload.owner_name, payload.owner_email, pw_hash),
    )
    return await get_school(school_id)


@router.put("/{school_id}", response_model=School)
async def update_school(school_id: int, payload: School):
    """Partial update — only the fields the Settings page actually edits."""
    await run_query(
        """
        UPDATE school.schools
        SET name = %s, plan = %s, logo_url = %s, primary_color = %s,
            languages_taught = %s, native_languages = %s,
            updated_at = now()
        WHERE school_id = %s
        """,
        (
            payload.name, payload.plan, payload.logo_url, payload.primary_color,
            payload.languages_taught, payload.native_languages, school_id,
        ),
    )
    return await get_school(school_id)


@router.delete("/{school_id}")
async def delete_school(school_id: int):
    ok = await run_query(
        "DELETE FROM school.schools WHERE school_id = %s",
        (school_id,),
    )
    return {"ok": ok}


@router.get("/{school_id}/stats", response_model=SchoolStats)
async def get_school_stats(school_id: int):
    """Counts shown in the Overview header tiles. One round-trip; each
    sub-query is independent so the planner can parallelise."""
    rows = await get_query_results(
        """
        SELECT
            (SELECT cardinality(languages_taught)
                FROM school.schools WHERE school_id = %s) AS active_languages,
            (SELECT COUNT(*) FROM school.course_access
                WHERE school_id = %s) AS courses,
            (SELECT COUNT(*) FROM school.school_users
                WHERE school_id = %s AND role IN ('owner','editor')) AS editors,
            (SELECT COUNT(DISTINCT user_id) FROM school.student_enrollments
                WHERE school_id = %s) AS students
        """,
        (school_id, school_id, school_id, school_id),
    )
    r = rows[0] if rows else {}
    return SchoolStats(
        school_id=school_id,
        active_languages=int(r.get('active_languages') or 0),
        courses=int(r.get('courses') or 0),
        editors=int(r.get('editors') or 0),
        students=int(r.get('students') or 0),
    )
