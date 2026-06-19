"""Building blocks for the learner-app auth flows in routers/auth_new.py.

This mirrors the proven behaviour of the legacy routers/auth.py but pulls
the reusable pieces out as plain functions so the router stays thin:

  * password hashing / verification (bcrypt, same cost as the dashboard)
  * Auth0 verification with a dev fallback
  * user + school_user upserts against the real schema
  * invitation validation / redemption (school.school_invitations)
  * UserPref assembly (preference row + school metadata + roles)
  * the HttpOnly session cookie

Schema notes that bit the first draft:
  * users live in `user_data.users` (email, email_hash, password_hash,
    school_id) — there is no `name`/`password`/`sub` column. user_id is a
    serial, so creation uses RETURNING, never a client-supplied id.
  * passwords are bcrypt hashes in `password_hash`, never plaintext.
  * invitations live in `school.school_invitations`, keyed by
    `invitation_code` with `school` / `max_uses` / `uses_count` /
    `expiration` — there is no `invitation_token`/`used`/`email` column.
"""
import hashlib
import os

import bcrypt
from fastapi import Request, Response

from models.auth import (InvitationUseRequest, PasswordLoginRequest,
                         UserAuth0Request, UserPref)
from models.school import School
from school.utils import auth0 as auth0_verifier
from utils.auth_deps import get_or_create_school_user
from utils.db import get_query_results, run_query

_COOKIE_MAX_AGE = 60 * 60 * 24 * 365  # 1 year — matches the legacy code
_COOKIE_NAME = "user_id"


# --------------------------------------------------------------------------
# Session cookie
# --------------------------------------------------------------------------
def _cookie_kwargs(domain: str | None = None) -> dict:
    """HttpOnly always. SameSite + Secure + Domain depend on env — see the
    long-form notes in routers/auth.py. Kept identical so a cookie set by
    either router is readable by the other."""
    secure = os.getenv("COOKIE_SECURE", "").lower() in {"1", "true", "yes"}
    samesite = os.getenv("COOKIE_SAMESITE", "lax").lower()
    return {
        "max_age": _COOKIE_MAX_AGE,
        "httponly": True,
        "samesite": samesite,
        "secure": secure,
        "domain": domain,
    }


def set_session_cookie(response: Response, user_id: int, domain: str | None = None) -> None:
    response.set_cookie(key=_COOKIE_NAME, value=str(user_id), **_cookie_kwargs(domain))



def clear_session_cookies(response: Response) -> None:
    for key in (_COOKIE_NAME):
        response.delete_cookie(key)


# --------------------------------------------------------------------------
# Passwords
# --------------------------------------------------------------------------
def _hash_password(plain: str) -> str:
    """Bcrypt, 12-round cost, identical to the dashboard's hasher. Truncated
    to bcrypt's 72-byte input limit so long pass-phrases don't crash."""
    return bcrypt.hashpw(plain.encode("utf-8")[:72], bcrypt.gensalt(rounds=12)).decode("ascii")


def _verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode("utf-8")[:72], hashed.encode("ascii"))
    except (ValueError, AttributeError):
        # Malformed / missing stored hash — failed verify rather than 500.
        return False


# --------------------------------------------------------------------------
# Auth0
# --------------------------------------------------------------------------
async def auth_auth0_user(payload: UserAuth0Request) -> str | None:
    """Return the verified, normalised email or None.

      * Auth0 configured + id_token present → verify the JWT, trust the
        `email` claim (rejecting unverified emails).
      * Auth0 not configured → dev fallback: trust the supplied email.
      * Auth0 configured but no token → None (caller maps to 400/401)."""
    if payload.id_token and auth0_verifier.is_enabled():
        try:
            claims = await auth0_verifier.verify_id_token(payload.id_token)
        except ValueError:
            return None
        if claims.get("email_verified") is False:
            return None
        return (claims.get("email") or "").strip().lower() or None
    if not auth0_verifier.is_enabled():
        return (payload.email or "").strip().lower() or None
    return None


# --------------------------------------------------------------------------
# Users / school users
# --------------------------------------------------------------------------
async def get_user(email: str) -> dict | None:
    """Raw user row by email, or None. Email match is case-insensitive."""
    if not email:
        return None
    rows = await get_query_results(
        "SELECT * FROM user_data.users WHERE LOWER(email) = %s LIMIT 1",
        (email.strip().lower(),),
    )
    return rows[0] if rows else None


async def create_user(email: str, school_id: int, password: str | None = None) -> int:
    """Insert a user_data.users row and return its generated user_id (0 on
    failure). `name`/`sub` from Auth0 aren't persisted — the table has no
    column for them today."""
    email = email.strip().lower()
    email_hash = hashlib.sha256(email.encode("utf-8")).hexdigest()[:64]
    password_hash = _hash_password(password) if password else None
    rows = await get_query_results(
        """INSERT INTO user_data.users (email, email_hash, password_hash, school_id)
        VALUES (%s, %s, %s, %s)
        RETURNING user_id""",
        (email, email_hash, password_hash, school_id),
    )
    return int(rows[0]["user_id"]) if rows else 0


async def auth_user_with_password(payload: PasswordLoginRequest) -> int | None:
    """Verify email + password against user_data.users. Returns the user_id
    or None. Does NOT create a user when the email is unknown — sign-up goes
    through the Auth0 / invitation flows."""
    if not payload.email or not payload.password:
        return None
    user = await get_user(payload.email)
    if not user:
        return None
    if not _verify_password(payload.password, user.get("password_hash") or ""):
        return None
    user_id = int(user["user_id"])
    await run_query(
        "UPDATE user_data.users SET last_login = now() WHERE user_id = %s",
        (user_id,),
    )
    return user_id


def auth_user_with_cookie(request: Request) -> int | None:
    """Read + parse the `user_id` session cookie. Returns the id or None;
    the caller is responsible for confirming the user still exists / is
    active (see is_school_user_active)."""
    raw = request.cookies.get(_COOKIE_NAME)
    if not raw:
        return None
    try:
        return int(raw)
    except (TypeError, ValueError):
        return None


async def is_school_user_active(user_id: int, school_id: int) -> bool:
    """The extra security gate for cookie logins: the user must still have an
    active school_users row for this school."""
    rows = await get_query_results(
        """SELECT status FROM school.school_users
        WHERE user_id = %s AND school_id = %s LIMIT 1""",
        (user_id, school_id),
    )
    return bool(rows) and rows[0].get("status") == "active"


# --------------------------------------------------------------------------
# Invitations  (school.school_invitations)
# --------------------------------------------------------------------------
async def validate_invitation(invitation_code: str, school_id: int) -> dict | None:
    """Return a usable invitation row for this school, or None. Usable means:
    code matches, belongs to the school, not expired, and has remaining uses."""
    if not invitation_code:
        return None
    rows = await get_query_results(
        """SELECT * FROM school.school_invitations
        WHERE invitation_code = %s
          AND school = %s
          AND (expiration IS NULL OR expiration > now())
          AND uses_count < max_uses
        LIMIT 1""",
        (invitation_code, school_id),
    )
    return rows[0] if rows else None


async def redeem_invitation(invitation_id: int) -> bool:
    """Consume one use of an invitation. Stamps redeemed_at the first time and
    guards uses_count in the WHERE clause so concurrent redeems can't push it
    past max_uses."""
    return await run_query(
        """UPDATE school.school_invitations
        SET uses_count = uses_count + 1,
            redeemed_at = COALESCE(redeemed_at, now())
        WHERE invitation_id = %s AND uses_count < max_uses""",
        (invitation_id,),
    )


def school_require_invitation(school: School) -> bool:
    """Private schools gate new sign-ups behind an invitation code."""
    return bool(school) and school.school_type == "private"


# --------------------------------------------------------------------------
# UserPref assembly
# --------------------------------------------------------------------------
async def _fetch_preference(user_id: int, school_id: int) -> dict | None:
    rows = await get_query_results(
        """SELECT user_id, course_id, module_id, lesson_id,
                  ui_lang, lang, to_lang
        FROM user_data.preference
        WHERE user_id = %s AND school_id = %s
        ORDER BY updated_at DESC
        LIMIT 1""",
        (user_id, school_id),
    )
    return rows[0] if rows else None


async def build_user_pref(user_id: int, school: School) -> UserPref:
    """The full payload every successful login returns: the preference row,
    the school's roles for this user, plus school branding/metadata."""
    school_user = await get_or_create_school_user(user_id, school.school_id)
    preference = await _fetch_preference(user_id, school.school_id)
    return UserPref(
        user_id=user_id,
        school_id=school.school_id,
        preference=preference or {},
        roles=school_user.roles or [],
        plan=[school.plan] if school.plan else [],
        school_name=school.name,
        school_type=school.school_type,
        logo_url=school.logo_url,
        primary_color=school.primary_color,
    )


async def create_user_with_invitation(payload: InvitationUseRequest,
                                       school: School) -> UserPref | None:
    """Deep-link / private-school join: validate the invitation, get-or-create
    the user and their school_users row, redeem the invitation, seed any
    preference carried on the invite (course / languages), and return the
    full UserPref. Returns None when the invitation is invalid or required
    fields are missing — the caller maps that to a 400."""
    email = (payload.email or "").strip().lower()
    if not email or not payload.invitation_token:
        return None

    invitation = await validate_invitation(payload.invitation_token, school.school_id)
    if not invitation:
        return None

    user = await get_user(email)
    user_id = int(user["user_id"]) if user else await create_user(email, school.school_id)
    if not user_id:
        return None

    # get_or_create_school_user + redeem are both idempotent enough that a
    # repeat invitation use for an existing member just re-logs them in.
    await get_or_create_school_user(user_id, school.school_id)
    await redeem_invitation(invitation["invitation_id"])
    await _seed_invitation_preference(user_id, school.school_id, payload)

    return await build_user_pref(user_id, school)


async def _seed_invitation_preference(user_id: int, school_id: int,
                                      payload: InvitationUseRequest) -> None:
    """Pre-fill the user's preference from invitation data (course / langs) so
    a freshly-joined student lands in the right course. Best-effort: skipped
    when the invite carries no preference hints."""
    if not (payload.course_id or payload.lang or payload.to_lang):
        return
    await run_query(
        """INSERT INTO user_data.preference
            (user_id, school_id, lang, to_lang, course_id)
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (user_id, school_id, lang) DO UPDATE
            SET to_lang = EXCLUDED.to_lang,
                course_id = EXCLUDED.course_id,
                updated_at = now()""",
        (user_id, school_id, payload.lang or "", payload.to_lang or "",
         payload.course_id),
    )
