"""Sign-in building blocks, copied from server/src/utils/auth_utils.py so the
editor signs users in the same way as the app (routers/auth_new.py there).

The editor keeps its own session (a signed cookie, see utils/session.py) and
only lets in users with the `editor` role, so the app's cookie, invitation and
preference helpers are not copied.
"""
import hashlib

import bcrypt
from pydantic import BaseModel

from utils import auth0 as auth0_verifier
from utils.db import get_query_results, run_query


class UserAuth0Request(BaseModel):
    """Same body as the app's /get_or_create_user."""
    id_token: str | None = None
    email: str | None = None
    name: str | None = None
    sub: str | None = None


class PasswordLoginRequest(BaseModel):
    email: str
    password: str


# --------------------------------------------------------------------------
# Passwords
# --------------------------------------------------------------------------
def _hash_password(plain: str) -> str:
    """Bcrypt, 12-round cost, over bcrypt's 72-byte input limit."""
    return bcrypt.hashpw(plain.encode("utf-8")[:72], bcrypt.gensalt(rounds=12)).decode("ascii")


def _verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode("utf-8")[:72], hashed.encode("ascii"))
    except (ValueError, AttributeError):
        return False


# --------------------------------------------------------------------------
# Auth0
# --------------------------------------------------------------------------
async def auth_auth0_user(payload: UserAuth0Request) -> str | None:
    """The signed-in email, or None.

      * Auth0 configured + id_token → verify the token, use its `email` claim.
      * Auth0 not configured (AUTH0_DOMAIN unset) → trust the supplied email.
      * Auth0 configured but no token → None."""
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
# Users
# --------------------------------------------------------------------------
async def get_user(email: str) -> dict | None:
    """The user row for this email (case-insensitive), or None."""
    if not email:
        return None
    rows = await get_query_results(
        "SELECT * FROM user_data.users WHERE LOWER(email) = %s LIMIT 1",
        (email.strip().lower(),),
    )
    return rows[0] if rows else None


async def create_user(email: str, school_id: int, password: str | None = None) -> int:
    """Add a user_data.users row and return its user_id (0 on failure)."""
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
    """The user_id when email + password match, else None. Never creates a user."""
    if not payload.email or not payload.password:
        return None
    user = await get_user(payload.email)
    if not user:
        return None
    if not _verify_password(payload.password, user.get("password_hash") or ""):
        return None
    return int(user["user_id"])


async def touch_last_login(user_id: int) -> None:
    await run_query("UPDATE user_data.users SET last_login = now() WHERE user_id = %s", (user_id,))


def school_require_invitation(school_type: str | None) -> bool:
    """Private schools only take new users through an invitation."""
    return school_type == "private"
