"""Auth0-backed sign-in for the learner app (poliglots_app).

Flow:
  1. Client opens the Auth0 universal login page.
  2. Auth0 returns an ID token to the client.
  3. Client POSTs the ID token to /api/v1/auth/get_or_create_user.
  4. Server verifies the token, upserts `user_data.users` by email,
     sets a long-lived HttpOnly `user_id` cookie, returns the user +
     their preference row.
  5. Subsequent app launches hit /api/v1/auth/login_with_cookie which
     just reads the cookie — no Auth0 round-trip until the cookie
     expires (1 year by default, matching the previous code).

Local-dev escape hatch: when `AUTH0_DOMAIN` is unset on the server,
both routes accept an unverified email/sub payload so a dev can
sign in without an Auth0 tenant. The dashboard's /login_auth0 route
takes a similar stance — see `school.utils.auth0.is_enabled()`.
"""
from __future__ import annotations

import hashlib
import logging
import os

import bcrypt
from fastapi import APIRouter, HTTPException, Request, Response

from models.user_data import PasswordLoginRequest, UserAuth0Request, UserPref
from school.utils import auth0 as auth0_verifier
from utils.db import get_query_results, run_query

logger = logging.getLogger(__name__)
router = APIRouter()

_COOKIE_MAX_AGE = 60 * 60 * 24 * 365  # 1 year — matches the legacy code
_COOKIE_NAME = "user_id"


def _cookie_kwargs() -> dict:
    """HttpOnly always. SameSite + Secure + Domain depend on env:

      * `COOKIE_SECURE=1` flips on the Secure flag. Required when the
        cookie travels over HTTPS (prod) and harmless to omit on
        local HTTP (Safari drops Secure cookies on http:// even via
        127.0.0.1, so we keep it off in dev).
      * `COOKIE_DOMAIN=.polyglots.social` makes the cookie visible
        across every subdomain — needed when api.* sets a cookie that
        app.* / dashboard.* will rely on. Leave unset locally so the
        cookie defaults to the request host.
      * `COOKIE_SAMESITE=none|lax|strict` — defaults to `lax`. For
        cross-site contexts (e.g. embedded iframes) you'd flip this
        to `none`, but a same-site parent-domain setup with `lax`
        works fine for app.polyglots.social → api.polyglots.social.
    """
    secure = os.getenv("COOKIE_SECURE", "").lower() in {"1", "true", "yes"}
    samesite = os.getenv("COOKIE_SAMESITE", "lax").lower()
    domain = os.getenv("COOKIE_DOMAIN", "").strip() or None
    return {
        "max_age": _COOKIE_MAX_AGE,
        "httponly": True,
        "samesite": samesite,
        "secure": secure,
        "domain": domain,
    }


async def _fetch_user_pref(user_id: int) -> UserPref | None:
    """Combine the user row with the most-recent preference. Returns
    None when the user_id doesn't exist — caller decides how to map
    that to an HTTP status."""
    rows = await get_query_results(
        "SELECT user_id, email FROM user_data.users WHERE user_id = %s",
        (user_id,),
    )
    if not rows:
        return None
    u = rows[0]
    prefs = await get_query_results(
        """
        SELECT user_id, course_id, module_id, lesson_id,
               ui_lang, lang, to_lang
        FROM user_data.preference
        WHERE user_id = %s
        ORDER BY updated_at DESC
        LIMIT 1
        """,
        (user_id,),
    )
    return UserPref(
        user_id=u["user_id"],
        email=u.get("email") or "",
        name="",   # the users table doesn't store name today; harmless
        preference=prefs[0] if prefs else None,
    )


def _hash_password(plain: str) -> str:
    """Bcrypt with a 12-round cost, identical to the dashboard's
    school_users hasher. Truncates to bcrypt's 72-byte input limit so
    long pass-phrases don't crash the hash call."""
    pw = plain.encode("utf-8")[:72]
    return bcrypt.hashpw(pw, bcrypt.gensalt(rounds=12)).decode("ascii")


def _verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode("utf-8")[:72], hashed.encode("ascii"))
    except ValueError:
        # Malformed stored hash — treat as failed verify rather than 500.
        return False


async def _get_or_create_user(email: str) -> int:
    """Upsert by email — returns the user_id. The users table's
    composite PK is (email, user_id) which means re-inserting on the
    same email is the natural path; we look up first to keep things
    explicit and avoid an INSERT that no-ops silently."""
    rows = await get_query_results(
        "SELECT user_id FROM user_data.users WHERE email = %s LIMIT 1",
        (email,),
    )
    if rows:
        # Touch last_login so the row shows fresh activity.
        await run_query(
            "UPDATE user_data.users SET last_login = now() WHERE user_id = %s",
            (rows[0]["user_id"],),
        )
        return int(rows[0]["user_id"])

    email_hash = hashlib.sha256(email.lower().encode("utf-8")).hexdigest()[:64]
    inserted = await get_query_results(
        """
        INSERT INTO user_data.users (email, email_hash)
        VALUES (%s, %s)
        RETURNING user_id
        """,
        (email, email_hash),
    )
    if not inserted:
        raise HTTPException(status_code=500, detail="Failed to create user")
    return int(inserted[0]["user_id"])


@router.post("/get_or_create_user", response_model=UserPref)
async def get_or_create_user(
    payload: UserAuth0Request,
    response: Response,
):
    """Sign in (or sign up) with an Auth0 ID token. Sets a 1-year
    HttpOnly `user_id` cookie so subsequent app launches can call
    /login_with_cookie without re-prompting Auth0.

    Two paths:
      * **Verified** — `id_token` is set, AUTH0_DOMAIN is configured.
        Server validates the JWT and trusts the `email` claim.
      * **Dev fallback** — AUTH0_DOMAIN is unset. Server takes the
        client-supplied `email`/`sub` at face value. Never enabled
        on a box that has AUTH0_DOMAIN set, so prod can't accidentally
        accept unverified email."""
    email: str | None = None

    if payload.id_token and auth0_verifier.is_enabled():
        try:
            claims = await auth0_verifier.verify_id_token(payload.id_token)
        except ValueError as e:
            logger.info("auth0 verify failed: %s", e)
            raise HTTPException(status_code=401, detail="Invalid Auth0 token")
        email = (claims.get("email") or "").strip().lower()
        if claims.get("email_verified") is False:
            raise HTTPException(status_code=401, detail="Email is not verified")
    elif not auth0_verifier.is_enabled():
        # Dev fallback — trust the supplied email/sub.
        email = (payload.email or "").strip().lower()
    else:
        # Server has Auth0 configured but the client didn't send a token.
        raise HTTPException(
            status_code=400, detail="id_token is required on this server")

    if not email:
        raise HTTPException(status_code=400, detail="email is required")

    user_id = await _get_or_create_user(email)
    pref = await _fetch_user_pref(user_id)
    if pref is None:
        # Should never happen — we just upserted — but treat as 500
        # rather than handing back a half-baked response.
        raise HTTPException(status_code=500, detail="User row missing")

    response.set_cookie(key=_COOKIE_NAME, value=str(user_id), **_cookie_kwargs())
    # Mirror the legacy behavior: stash lang preferences in cookies too
    # so a fresh client without local storage can pre-fill its language
    # picker before the first /preference call lands.
    if pref.preference:
        lang = pref.preference.get("lang")
        to_lang = pref.preference.get("to_lang")
        if lang:
            response.set_cookie(key="lang", value=lang, **_cookie_kwargs())
        if to_lang:
            response.set_cookie(
                key="to_lang", value=to_lang, **_cookie_kwargs())
    return pref


@router.post("/login_with_password", response_model=UserPref)
async def login_with_password(payload: PasswordLoginRequest, response: Response):
    """Sign-up-or-sign-in via email + password.

      * **Existing email** → verify the bcrypt hash. 401 on mismatch.
        Touches last_login so the user row shows fresh activity.
      * **New email** → create the user with the given password as
        their bcrypt hash. The same row could later attach an Auth0
        identity by email — they coexist on one user_id.

    Sets the same HttpOnly `user_id` cookie as the Auth0 route, so
    subsequent calls to /login_with_cookie work identically. Used by
    the learner app for local-test logins where standing up Auth0
    isn't worth it."""
    email = (payload.email or "").strip().lower()
    if not email or not payload.password:
        raise HTTPException(
            status_code=400, detail="email and password are required")

    rows = await get_query_results(
        "SELECT user_id, password_hash FROM user_data.users "
        "WHERE LOWER(email) = %s LIMIT 1",
        (email,),
    )
    if rows:
        user_id = int(rows[0]["user_id"])
        stored_hash = rows[0].get("password_hash")
        if not stored_hash:
            # Row exists but was created via Auth0 / guest path (no
            # password set). Set it now so the next sign-in works.
            await run_query(
                "UPDATE user_data.users SET password_hash = %s "
                "WHERE user_id = %s",
                (_hash_password(payload.password), user_id),
            )
        elif not _verify_password(payload.password, stored_hash):
            raise HTTPException(status_code=401, detail="Invalid credentials")
        await run_query(
            "UPDATE user_data.users SET last_login = now() WHERE user_id = %s",
            (user_id,),
        )
    else:
        # Brand-new sign-up — insert with the supplied password hashed.
        email_hash = hashlib.sha256(
            email.encode("utf-8")).hexdigest()[:64]
        inserted = await get_query_results(
            """
            INSERT INTO user_data.users (email, email_hash, password_hash)
            VALUES (%s, %s, %s)
            RETURNING user_id
            """,
            (email, email_hash, _hash_password(payload.password)),
        )
        if not inserted:
            raise HTTPException(status_code=500, detail="Failed to create user")
        user_id = int(inserted[0]["user_id"])

    pref = await _fetch_user_pref(user_id)
    if pref is None:
        raise HTTPException(status_code=500, detail="User row missing")

    response.set_cookie(key=_COOKIE_NAME, value=str(user_id), **_cookie_kwargs())
    return pref


@router.post("/login_with_cookie", response_model=UserPref)
async def login_with_cookie(request: Request):
    """Restore a session from the `user_id` cookie. Returns 401 when
    the cookie is missing or points at a deleted row — the client
    falls back to the login screen in that case."""
    raw = request.cookies.get(_COOKIE_NAME)
    if not raw:
        raise HTTPException(status_code=401, detail="No session cookie")
    try:
        user_id = int(raw)
    except (TypeError, ValueError):
        raise HTTPException(status_code=401, detail="Malformed session cookie")

    pref = await _fetch_user_pref(user_id)
    if pref is None:
        raise HTTPException(status_code=401, detail="Unknown user")
    return pref


@router.post("/logout")
async def logout(response: Response):
    """Clear the session cookies. The client doesn't need to send any
    body — just hit this and forget."""
    for key in (_COOKIE_NAME, "lang", "to_lang"):
        response.delete_cookie(key)
    return {"ok": True}
