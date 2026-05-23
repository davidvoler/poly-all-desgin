from datetime import datetime

from fastapi import APIRouter, HTTPException

from school.models.school import (
    ActivityRow,
    LanguageSummary,
    School,
    SchoolCreate,
    SchoolStats,
    StudentRow,
)
from school.routes.users import _hash_password
from utils.db import get_query_results, run_query

router = APIRouter()


# Static metadata used to dress up bare language codes coming back from
# the database. Keeps the dashboard from having to know any locales
# itself — the server pre-renders flag/native/english/rtl. New languages
# only need a row here.
_LANG_META: dict[str, dict] = {
    'ar': {'flag': '🇸🇦', 'native': 'العربية', 'english': 'Arabic', 'rtl': True},
    'he': {'flag': '🇮🇱', 'native': 'עברית', 'english': 'Hebrew', 'rtl': True},
    'it': {'flag': '🇮🇹', 'native': 'Italiano', 'english': 'Italian', 'rtl': False},
    'en': {'flag': '🇺🇸', 'native': 'English', 'english': 'English', 'rtl': False},
    'es': {'flag': '🇪🇸', 'native': 'Español', 'english': 'Spanish', 'rtl': False},
    'fr': {'flag': '🇫🇷', 'native': 'Français', 'english': 'French', 'rtl': False},
    'ja': {'flag': '🇯🇵', 'native': '日本語', 'english': 'Japanese', 'rtl': False},
    'el': {'flag': '🇬🇷', 'native': 'Ελληνικά', 'english': 'Greek', 'rtl': False},
}


def _lang_meta(code: str) -> dict:
    return _LANG_META.get(code) or {
        'flag': '',
        'native': code,
        'english': code.upper(),
        'rtl': False,
    }


def _humanize(dt: datetime | None) -> str:
    """Render a timestamp as "3 m ago" / "2 h ago" / "Yesterday" /
    "3 days ago" — matches the strings the design uses. None → "Never"."""
    if dt is None:
        return 'Never'
    now = datetime.now(tz=dt.tzinfo) if dt.tzinfo else datetime.now()
    delta = now - dt
    sec = int(delta.total_seconds())
    if sec < 60:
        return 'Just now'
    if sec < 3600:
        return f'{sec // 60} m ago'
    if sec < 86400:
        return f'{sec // 3600} h ago'
    days = sec // 86400
    if days == 1:
        return 'Yesterday'
    if days < 28:
        return f'{days} days ago'
    if days < 365:
        return f'{days // 7} weeks ago'
    return f'{days // 365} years ago'


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


@router.get("/{school_id}/activity", response_model=list[ActivityRow])
async def get_activity(school_id: int, limit: int = 10):
    """Feeds the Overview "Recent activity" panel. Joins to
    school_users so we can render the actor's name (NULL when the row
    represents a system event, e.g. an automated import)."""
    rows = await get_query_results(
        """
        SELECT al.activity_id, al.school_id, al.actor_user_id,
               al.kind, al.summary, al.created_at,
               su.name AS actor_name
        FROM school.activity_log al
        LEFT JOIN school.school_users su
            ON su.user_id = al.actor_user_id
                OR su.school_user_id = al.actor_user_id
        WHERE al.school_id = %s
        ORDER BY al.created_at DESC
        LIMIT %s
        """,
        (school_id, limit),
    )
    out: list[ActivityRow] = []
    for r in rows:
        created = r.get('created_at')
        out.append(ActivityRow(
            activity_id=r['activity_id'],
            school_id=r['school_id'],
            actor_user_id=r.get('actor_user_id'),
            actor_name=r.get('actor_name') or 'System',
            kind=r.get('kind') or 'generic',
            summary=r.get('summary') or '',
            created_at=created,
            when_human=_humanize(created),
        ))
    return out


@router.get("/{school_id}/languages", response_model=list[LanguageSummary])
async def get_languages_summary(school_id: int, role: str | None = None):
    """Powers both halves of the Languages page. With `role` omitted,
    returns both lists ('teach' before 'native'); pass role='teach' or
    role='native' to filter to one. Per-language counts come from
    course_simple.course and school.student_enrollments."""
    school_rows = await get_query_results(
        "SELECT languages_taught, native_languages FROM school.schools WHERE school_id = %s",
        (school_id,),
    )
    if not school_rows:
        raise HTTPException(status_code=404, detail="School not found")
    taught = list(school_rows[0].get('languages_taught') or [])
    native = list(school_rows[0].get('native_languages') or [])

    # Per-course counts (for the "we teach" cards).
    course_rows = await get_query_results(
        """
        SELECT c.lang AS code,
               COUNT(DISTINCT c.course_id) AS courses,
               COUNT(DISTINCT se.user_id)  AS students
        FROM course_simple.course c
        JOIN school.course_access ca ON ca.course_id = c.course_id
        LEFT JOIN school.student_enrollments se
            ON se.school_id = ca.school_id AND se.course_id = c.course_id
        WHERE ca.school_id = %s
        GROUP BY c.lang
        """,
        (school_id,),
    )
    by_code = {r['code']: r for r in course_rows}

    # Native-language stats — student count per native language for this
    # school. user_data.preference.to_lang is the student's native code.
    total_students_rows = await get_query_results(
        """
        SELECT COUNT(DISTINCT se.user_id) AS total
        FROM school.student_enrollments se WHERE se.school_id = %s
        """,
        (school_id,),
    )
    total_students = int((total_students_rows[0] if total_students_rows else {}).get('total') or 0)

    native_rows = await get_query_results(
        """
        SELECT p.to_lang AS code, COUNT(DISTINCT se.user_id) AS students
        FROM school.student_enrollments se
        JOIN user_data.preference p ON p.user_id = se.user_id
        WHERE se.school_id = %s AND p.to_lang IS NOT NULL
        GROUP BY p.to_lang
        """,
        (school_id,),
    )
    native_by_code = {r['code']: int(r['students']) for r in native_rows}

    out: list[LanguageSummary] = []
    if role in (None, 'teach'):
        for code in taught:
            meta = _lang_meta(code)
            c = by_code.get(code) or {}
            out.append(LanguageSummary(
                lang=code,
                role='teach',
                flag=meta['flag'],
                native=meta['native'],
                english=meta['english'],
                rtl=meta['rtl'],
                courses=int(c.get('courses') or 0),
                students=int(c.get('students') or 0),
                active=True,
            ))
    if role in (None, 'native'):
        for code in native:
            meta = _lang_meta(code)
            students = native_by_code.get(code, 0)
            pct = (
                f'{round(students / total_students * 100)}%'
                if total_students > 0 else None
            )
            out.append(LanguageSummary(
                lang=code,
                role='native',
                flag=meta['flag'],
                native=meta['native'],
                english=f"{meta['english']} · spoken natively",
                rtl=meta['rtl'],
                students=students,
                percent_of_school=pct,
                active=True,
            ))
    return out


@router.get("/{school_id}/students", response_model=list[StudentRow])
async def get_students(
    school_id: int,
    lang: str | None = None,
    status: str | None = None,
    limit: int = 200,
):
    """Roster for the Students page. Joins enrollment rows with
    user_data.users (for name/email) and course_simple.course (for the
    course label). Filter by `lang` (the language the student is
    learning) or `status` (active|slowing|inactive|no_course)."""
    where = ["se.school_id = %s"]
    params: list = [school_id]
    if lang:
        where.append("se.lang = %s")
        params.append(lang)
    if status:
        where.append("se.status = %s")
        params.append(status)

    sql = f"""
        SELECT
            se.user_id, se.lang, se.course_id, se.progress,
            se.last_active, se.status,
            COALESCE(u.email, '') AS email,
            COALESCE(SPLIT_PART(u.email, '@', 1), '') AS email_local,
            c.title AS course_title
        FROM school.student_enrollments se
        LEFT JOIN user_data.users u ON u.user_id = se.user_id
        LEFT JOIN course_simple.course c ON c.course_id = se.course_id
        WHERE {' AND '.join(where)}
        ORDER BY se.last_active DESC NULLS LAST
        LIMIT %s
    """
    rows = await get_query_results(sql, (*params, limit))
    out: list[StudentRow] = []
    for r in rows:
        code = r.get('lang') or ''
        meta = _lang_meta(code)
        # Build a display name from the email local-part since
        # user_data.users doesn't store a separate name column.
        local = (r.get('email_local') or '').replace('.', ' ')
        name = ' '.join(s.capitalize() for s in local.split() if s) or '—'
        last_seen = r.get('last_active')
        out.append(StudentRow(
            user_id=r['user_id'],
            name=name,
            email=r.get('email') or '',
            lang=code,
            lang_flag=meta['flag'],
            lang_name=meta['english'],
            course=r.get('course_title') or '—',
            course_id=r.get('course_id'),
            progress=float(r.get('progress') or 0.0),
            last_seen=last_seen,
            last_seen_human=_humanize(last_seen),
            status=r.get('status') or 'active',
        ))
    return out
