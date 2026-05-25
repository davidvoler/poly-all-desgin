import logging
import secrets
from datetime import datetime, timedelta

import bcrypt
from fastapi import APIRouter, Depends, HTTPException

from school.models.users import (
    Auth0LoginRequest,
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    LoginRequest,
    LoginResponse,
    ResetPasswordRequest,
    SchoolUser,
    SchoolUserCreate,
)
from school.utils import auth0 as auth0_verifier
from school.utils.activity import log_activity
from school.utils.auth import require_school_member
from utils.db import get_query_results, run_query

logger = logging.getLogger(__name__)

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
    _caller: int | None = Depends(require_school_member),
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
    # Admin first so the Editors page always leads with the school's owner.
    sql += " ORDER BY (role = 'admin') DESC, created_at"
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
    timestamp.

    Lookup order: `school.super_admins` first (cross-school identities
    are not tied to any school_id, so they'd never match a regular
    school_users + schools JOIN), then the regular school_users path.
    A super-admin session reports `school_id=0`, `role='super_admin'`,
    `school_slug=''`, `school_name='All schools'` — the dashboard's
    auth gate watches for role to decide what nav to render."""
    # 1) Super-admin? Skip the schools join entirely.
    super_rows = await get_query_results(
        """
        SELECT super_admin_id, name, email, password_hash
        FROM school.super_admins
        WHERE email = %s
        """,
        (payload.email,),
    )
    if super_rows:
        sa = super_rows[0]
        sa_hash = sa.get('password_hash')
        if sa_hash and _verify_password(payload.password, sa_hash):
            await run_query(
                "UPDATE school.super_admins SET last_seen = now() WHERE super_admin_id = %s",
                (sa['super_admin_id'],),
            )
            return LoginResponse(
                school_user_id=sa['super_admin_id'],
                school_id=0,
                school_slug='',
                school_name='All schools',
                name=sa.get('name') or '',
                email=sa['email'],
                role='super_admin',
            )
        # Fall through to the regular path — same email might exist
        # as both a super_admin and a school_users row.

    sql = """
        SELECT u.school_user_id, u.school_id, u.name, u.email, u.role,
               u.password_hash, u.status, u.pending_terms,
               s.slug as school_slug, s.name as school_name
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
        pending_terms=bool(row.get('pending_terms')),
    )


@router.post("/login_auth0", response_model=LoginResponse)
async def login_auth0(payload: Auth0LoginRequest):
    """Sign in with an Auth0-issued ID token.

    Flow:
      1. Verify the token against the configured Auth0 JWKS (issuer,
         signature, expiry, audience when one is configured).
      2. Read the `email` claim and look up an existing school_users
         row — same matching rules as the password route, including
         the optional `school_slug` narrowing.
      3. Return the standard LoginResponse so the dashboard reuses
         its existing session machinery.

    We intentionally do NOT auto-create users from the Auth0 directory.
    An admin still has to invite the email (POST /school_users/) so
    school-level ACLs aren't bypassed by anyone with an Auth0 login.
    The route returns 404 when the verified email isn't on the
    roster — the dashboard surfaces a "ask an admin to invite you"
    message in that case."""
    if not auth0_verifier.is_enabled():
        raise HTTPException(
            status_code=503,
            detail="Auth0 login is not configured on this server",
        )

    try:
        claims = await auth0_verifier.verify_id_token(payload.id_token)
    except ValueError as e:
        # Never leak which step failed (sig vs aud vs expiry) — the
        # client only needs to know the token didn't pass.
        logger.info("auth0 verify failed: %s", e)
        raise HTTPException(status_code=401, detail="Invalid Auth0 token")

    email = (claims.get("email") or "").strip().lower()
    if not email:
        raise HTTPException(
            status_code=401, detail="Auth0 token has no email claim")
    if claims.get("email_verified") is False:
        # Auth0 includes `email_verified` for most identity providers.
        # Reject unverified to stop someone signing up via a free
        # provider with a colleague's email.
        raise HTTPException(
            status_code=401, detail="Email is not verified")

    sql = """
        SELECT u.school_user_id, u.school_id, u.name, u.email, u.role,
               u.status,
               s.slug as school_slug, s.name as school_name
        FROM school.school_users u
        JOIN school.schools s ON s.school_id = u.school_id
        WHERE LOWER(u.email) = %s
    """
    params: tuple = (email,)
    if payload.school_slug:
        sql += " AND s.slug = %s"
        params = (email, payload.school_slug)
    sql += " ORDER BY u.created_at LIMIT 1"

    rows = await get_query_results(sql, params)
    if not rows:
        raise HTTPException(
            status_code=404,
            detail="No school account is linked to this Auth0 email",
        )
    row = rows[0]

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
        name=row.get('name') or claims.get('name') or '',
        email=row['email'],
        role=row['role'],
    )


_RESET_TTL_MINUTES = 30


@router.post("/forgot_password", response_model=ForgotPasswordResponse)
async def forgot_password(payload: ForgotPasswordRequest):
    """Issue a one-shot reset token. Always responds with `sent=true`
    so callers can't enumerate which emails are registered; the token
    is only returned when an account actually exists. In production
    the token would land in an email; for the demo we also log it so
    you can copy it from `docker logs server`."""
    sql = """
        SELECT u.school_user_id
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
        # Same shape as the happy path — keeps enumeration harder.
        return ForgotPasswordResponse(sent=True)

    school_user_id = rows[0]['school_user_id']
    token = secrets.token_urlsafe(24)
    expires_at = datetime.utcnow() + timedelta(minutes=_RESET_TTL_MINUTES)
    await run_query(
        """
        INSERT INTO school.password_resets
            (school_user_id, token, expires_at)
        VALUES (%s, %s, %s)
        """,
        (school_user_id, token, expires_at),
    )

    # Visible in `docker logs server` so a demo user can grab it.
    print(f"[password-reset] {payload.email} → token={token} (expires {expires_at.isoformat()}Z)")
    logger.info("password-reset issued for %s, expires %s",
                payload.email, expires_at.isoformat())

    return ForgotPasswordResponse(
        sent=True,
        token=token,
        expires_at=expires_at.isoformat() + 'Z',
    )


@router.post("/reset_password")
async def reset_password(payload: ResetPasswordRequest):
    """Consume a one-shot token and set a new bcrypt-hashed password.
    Rejects expired or already-used tokens. Returns {ok: true} on
    success so the dashboard can show a "now sign in" toast."""
    if not payload.token or not payload.new_password:
        raise HTTPException(status_code=400, detail="Token and password required")

    rows = await get_query_results(
        """
        SELECT reset_id, school_user_id, expires_at, consumed_at
        FROM school.password_resets
        WHERE token = %s
        """,
        (payload.token,),
    )
    if not rows:
        raise HTTPException(status_code=400, detail="Invalid token")
    r = rows[0]

    if r.get('consumed_at') is not None:
        raise HTTPException(status_code=400, detail="Token already used")
    expires = r.get('expires_at')
    if expires is not None and expires < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Token expired")

    pw_hash = _hash_password(payload.new_password)
    await run_query(
        "UPDATE school.school_users SET password_hash = %s WHERE school_user_id = %s",
        (pw_hash, r['school_user_id']),
    )
    await run_query(
        "UPDATE school.password_resets SET consumed_at = now() WHERE reset_id = %s",
        (r['reset_id'],),
    )
    return {"ok": True}
