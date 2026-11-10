"""Editor sign-in: email + password or Auth0, the same accounts as the app and
dashboard (user_data.users). Only active members of the site's school with the
`editor` role get a session. Users are never created here."""
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
    id_token: str


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


@router.post("/login_auth0", response_model=SchoolUser)
async def login_auth0(body: Auth0Login, request: Request, response: Response) -> SchoolUser:
    if not auth0.is_enabled():
        raise HTTPException(status_code=503, detail="Auth0 sign-in is not configured on the server")
    try:
        claims = await auth0.verify_id_token(body.id_token)
    except ValueError:
        raise HTTPException(status_code=401, detail="Auth0 sign-in could not be verified")
    email = (claims.get("email") or "").strip().lower()
    if not email or claims.get("email_verified") is False:
        raise HTTPException(status_code=401, detail="The Auth0 account has no verified email")
    user = await _user_by_email(email)
    if not user:
        raise HTTPException(status_code=403, detail=f"No account for {email}")
    return await _start_session(request, response, int(user["user_id"]))


@router.get("/me", response_model=SchoolUser)
async def me(user: SchoolUser = Depends(get_school_user)) -> SchoolUser:
    """The signed-in editor; 401 when the session is missing or expired."""
    return user


@router.post("/logout")
async def logout(response: Response) -> dict:
    clear_session_cookie(response)
    return {"ok": True}
