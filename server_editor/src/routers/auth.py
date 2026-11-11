"""Editor sign-in: email + password or Auth0, the same accounts as the app and
dashboard (user_data.users). Only active members of the site's school with the
`editor` role get a session. Auth0 sign-in creates the user row like the app
does, but never the editor role."""
import hashlib
import os

import bcrypt
from fastapi import APIRouter, Depends, HTTPException, Request, Response
from pydantic import BaseModel

from utils import auth0
from utils.db import get_query_results, run_query
from utils.permission import SchoolUser, editor_member, get_school_user, school_from_request
from utils.session import SessionError, clear_session_cookie, set_session_cookie

router = APIRouter()


def password_login_enabled() -> bool:
    """Email + password is for local development only: production signs in
    with OAuth. Set EDITOR_PASSWORD_LOGIN=true to turn it on."""
    return os.getenv("EDITOR_PASSWORD_LOGIN", "").lower() in ("1", "true", "yes")


class PasswordLogin(BaseModel):
    email: str
    password: str


class Auth0Login(BaseModel):
    """Same body as the app's /get_or_create_user. The email, name and sub come
    from the token's claims and are trusted only when AUTH0_DOMAIN is unset."""
    id_token: str | None = None
    email: str | None = None
    name: str | None = None
    sub: str | None = None


async def _user_by_email(email: str) -> dict | None:
    rows = await get_query_results(
        "SELECT user_id, password_hash FROM user_data.users WHERE LOWER(email) = %(email)s LIMIT 1",
        {"email": email.strip().lower()},
    )
    return rows[0] if rows else None


def _password_matches(plain: str, hashed: str | None) -> bool:
    try:
        # Same as the main server: bcrypt over the first 72 bytes.
        return bcrypt.checkpw(plain.encode("utf-8")[:72], (hashed or "").encode("ascii"))
    except (ValueError, AttributeError):
        return False


async def _start_session(request: Request, response: Response, user_id: int) -> SchoolUser:
    school = await school_from_request(request)
    user = await editor_member(user_id, school)
    if not user:
        raise HTTPException(status_code=403, detail=f"This account is not an editor at {school.name}")
    try:
        set_session_cookie(response, user.user_id, user.school_id)
    except SessionError as e:
        raise HTTPException(status_code=500, detail=str(e))
    await run_query("UPDATE user_data.users SET last_login = now() WHERE user_id = %(id)s",
                    {"id": user_id})
    return user


@router.post("/login_with_password", response_model=SchoolUser)
async def login_with_password(body: PasswordLogin, request: Request, response: Response) -> SchoolUser:
    if not password_login_enabled():
        raise HTTPException(status_code=404, detail="Password sign-in is turned off")
    user = await _user_by_email(body.email)
    if not user or not _password_matches(body.password, user.get("password_hash")):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    return await _start_session(request, response, int(user["user_id"]))


async def _get_or_create_user(email: str) -> int:
    """The user_id for this email, adding the user row when missing (same as
    the app's server)."""
    user = await _user_by_email(email)
    if user:
        return int(user["user_id"])
    email_hash = hashlib.sha256(email.encode("utf-8")).hexdigest()[:64]
    inserted = await get_query_results(
        "INSERT INTO user_data.users (email, email_hash) VALUES (%(email)s, %(hash)s) RETURNING user_id",
        {"email": email, "hash": email_hash},
    )
    if not inserted:
        raise HTTPException(status_code=500, detail="Failed to create user")
    return int(inserted[0]["user_id"])


@router.post("/get_or_create_user", response_model=SchoolUser)
async def get_or_create_user(body: Auth0Login, request: Request, response: Response) -> SchoolUser:
    """Auth0 sign-in, as in the app: verify the ID token when AUTH0_DOMAIN is
    set, otherwise trust the client's email. The session needs the editor role."""
    if body.id_token and auth0.is_enabled():
        try:
            claims = await auth0.verify_id_token(body.id_token)
        except ValueError:
            raise HTTPException(status_code=401, detail="Auth0 sign-in could not be verified")
        if claims.get("email_verified") is False:
            raise HTTPException(status_code=401, detail="The Auth0 account has no verified email")
        email = (claims.get("email") or "").strip().lower()
    elif not auth0.is_enabled():
        email = (body.email or "").strip().lower()
    else:
        raise HTTPException(status_code=400, detail="id_token is required on this server")
    if not email:
        raise HTTPException(status_code=400, detail="email is required")
    user_id = await _get_or_create_user(email)
    return await _start_session(request, response, user_id)


# Older editor builds call this name.
router.add_api_route("/login_auth0", get_or_create_user, methods=["POST"], response_model=SchoolUser)


@router.get("/me", response_model=SchoolUser)
async def me(user: SchoolUser = Depends(get_school_user)) -> SchoolUser:
    """The signed-in editor; 401 when the session is missing or expired."""
    return user


@router.post("/logout")
async def logout(response: Response) -> dict:
    clear_session_cookie(response)
    return {"ok": True}
