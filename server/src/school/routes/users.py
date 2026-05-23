import bcrypt
from fastapi import APIRouter, HTTPException

from school.models.users import (
    LoginRequest,
    LoginResponse,
    SchoolUser,
    SchoolUserCreate,
)
from school.utils.activity import log_activity
from utils.db import get_query_results, run_query

router = APIRouter()


def _hash_password(plain: str) -> str:
    """Bcrypt with a 12-round cost. Returned as str so it stores cleanly
    in `password_hash`. Truncates to 72 bytes (bcrypt's hard limit) so
    longer pass-phrases don't crash the hash call."""
    pw = plain.encode('utf-8')[:72]
    return bcrypt.hashpw(pw, bcrypt.gensalt(rounds=12)).decode('ascii')


def _verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(
            plain.encode('utf-8')[:72],
            hashed.encode('ascii'),
        )
    except ValueError:
        # Malformed stored hash — treat as failed verify rather than 500.
        return False


_USER_COLS = (
    "school_user_id, school_id, user_id, name, email, role, "
    "assigned_languages, courses_owned, last_seen, status, created_at"
)


def _row_to_user(row: dict) -> SchoolUser:
    return SchoolUser(
        school_user_id=row.get('school_user_id'),
        school_id=row['school_id'],
        user_id=row.get('user_id'),
        name=row.get('name') or '',
        email=row.get('email') or '',
        role=row.get('role') or 'editor',
        assigned_languages=list(row.get('assigned_languages') or []),
        courses_owned=int(row.get('courses_owned') or 0),
        last_seen=row.get('last_seen'),
        status=row.get('status') or 'active',
        created_at=row.get('created_at'),
    )


@router.get("/", response_model=list[SchoolUser])
async def list_school_users(
    school_id: int,
    role: str | None = None,
    q: str | None = None,
):
    """Roster for the Editors page. Optional `role` filter so the UI
    can request just owners/editors/viewers. Optional `q` matches
    name/email (case-insensitive substring)."""
    sql = f"SELECT {_USER_COLS} FROM school.school_users WHERE school_id = %s"
    params: list = [school_id]
    if role:
        sql += " AND role = %s"
        params.append(role)
    if q and q.strip():
        sql += " AND (name ILIKE %s OR email ILIKE %s)"
        like = f"%{q.strip()}%"
        params.extend([like, like])
    sql += " ORDER BY (role = 'owner') DESC, created_at"
    rows = await get_query_results(sql, tuple(params))
    return [_row_to_user(r) for r in rows]


@router.get("/{school_user_id}", response_model=SchoolUser)
async def get_school_user(school_user_id: int):
    rows = await get_query_results(
        f"SELECT {_USER_COLS} FROM school.school_users WHERE school_user_id = %s",
        (school_user_id,),
    )
    if not rows:
        raise HTTPException(status_code=404, detail="User not found")
    return _row_to_user(rows[0])


@router.post("/", response_model=SchoolUser)
async def create_school_user(payload: SchoolUserCreate):
    """Invite-style create. If `password` is provided, the user can log
    in immediately; otherwise the row is dormant until they accept the
    invite (typical for the dashboard's email-invite flow). Returns the
    new row including its generated id."""
    existing = await get_query_results(
        "SELECT 1 FROM school.school_users WHERE school_id = %s AND email = %s",
        (payload.school_id, payload.email),
    )
    if existing:
        raise HTTPException(
            status_code=409, detail="A user with this email already exists")

    pw_hash = _hash_password(payload.password) if payload.password else None
    inserted = await get_query_results(
        """
        INSERT INTO school.school_users
            (school_id, name, email, password_hash, role, assigned_languages)
        VALUES (%s, %s, %s, %s, %s, %s)
        RETURNING school_user_id
        """,
        (
            payload.school_id, payload.name, payload.email, pw_hash,
            payload.role, payload.assigned_languages,
        ),
    )
    if not inserted:
        raise HTTPException(status_code=500, detail="Failed to create user")

    # Log to the Overview activity feed. Distinguish editor-with-password
    # ("added") from email-only invites so the feed reads naturally.
    label = payload.name or payload.email
    if payload.password:
        kind = 'editor_added'
        summary = f"Added {payload.role} {label}"
    else:
        kind = 'editor_invite'
        summary = f"Invited {payload.email} as {payload.role}"
    await log_activity(
        school_id=payload.school_id,
        kind=kind,
        summary=summary,
    )

    return await get_school_user(inserted[0]['school_user_id'])


@router.put("/{school_user_id}", response_model=SchoolUser)
async def update_school_user(school_user_id: int, payload: SchoolUser):
    """Partial update — covers role changes, language reassignment, and
    suspending/reactivating from the Editors page."""
    # Snapshot the row before mutating so the activity entry can call
    # out what actually changed (role / status) instead of a generic
    # "user updated".
    prev = await get_query_results(
        "SELECT role, status FROM school.school_users WHERE school_user_id = %s",
        (school_user_id,),
    )
    await run_query(
        """
        UPDATE school.school_users
        SET name = %s, role = %s, assigned_languages = %s, status = %s
        WHERE school_user_id = %s
        """,
        (
            payload.name, payload.role, payload.assigned_languages,
            payload.status, school_user_id,
        ),
    )
    if prev:
        prev_role = prev[0].get('role')
        prev_status = prev[0].get('status')
        label = payload.name or payload.email
        if prev_role != payload.role:
            await log_activity(
                school_id=payload.school_id,
                kind='editor_role_changed',
                summary=f"{label}: {prev_role} → {payload.role}",
            )
        if prev_status != payload.status and payload.status == 'suspended':
            await log_activity(
                school_id=payload.school_id,
                kind='editor_suspended',
                summary=f"Suspended {label}",
            )
        if prev_status != payload.status and payload.status == 'active':
            await log_activity(
                school_id=payload.school_id,
                kind='editor_added',
                summary=f"Reactivated {label}",
            )
    return await get_school_user(school_user_id)


@router.delete("/{school_user_id}")
async def delete_school_user(school_user_id: int):
    # Capture the row so we can log who was removed before deleting it.
    row = await get_query_results(
        "SELECT school_id, name, email FROM school.school_users WHERE school_user_id = %s",
        (school_user_id,),
    )
    ok = await run_query(
        "DELETE FROM school.school_users WHERE school_user_id = %s",
        (school_user_id,),
    )
    if ok and row:
        r = row[0]
        await log_activity(
            school_id=r['school_id'],
            kind='editor_removed',
            summary=f"Removed {r.get('name') or r.get('email')}",
        )
    return {"ok": ok}


@router.post("/login", response_model=LoginResponse)
async def login(payload: LoginRequest):
    """Plain email+password auth (no token — see ADR in TASKS.md). The
    dashboard caches the response in memory and uses `school_id` + `role`
    to gate UI. We touch `last_seen` so the Editors page shows a fresh
    timestamp."""
    sql = """
        SELECT u.school_user_id, u.school_id, u.name, u.email, u.role,
               u.password_hash, u.status, s.slug as school_slug, s.name as school_name
        FROM school.school_users u
        JOIN school.schools s ON s.school_id = u.school_id
        WHERE u.email = %s
    """
    params: tuple = (payload.email,)
    if payload.school_slug:
        sql += " AND s.slug = %s"
        params = (payload.email, payload.school_slug)
    sql += " ORDER BY u.created_at LIMIT 1"

    rows = await get_query_results(sql, params)
    if not rows:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    row = rows[0]

    pw_hash = row.get('password_hash')
    if not pw_hash:
        raise HTTPException(status_code=401, detail="Account not activated")
    if not _verify_password(payload.password, pw_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if row.get('status') != 'active':
        raise HTTPException(status_code=403, detail="Account suspended")

    await run_query(
        "UPDATE school.school_users SET last_seen = now() WHERE school_user_id = %s",
        (row['school_user_id'],),
    )

    return LoginResponse(
        school_user_id=row['school_user_id'],
        school_id=row['school_id'],
        school_slug=row['school_slug'],
        school_name=row['school_name'],
        name=row.get('name') or '',
        email=row['email'],
        role=row['role'],
    )
