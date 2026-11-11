"""Editor sign-in, the same flow as the app's server/src/routers/auth_new.py and
on the same accounts (user_data.users).

  * get_or_create_user  — Auth0 sign-in. Public schools create a missing user;
    private schools need an invitation, which the editor does not take.
  * login_with_password — email + password; never creates a user. Off unless
    EDITOR_PASSWORD_LOGIN=true.
  * me                  — the signed-in editor, from the session cookie.
  * logout              — clears the session cookie.

Unlike the app, a session needs an active `editor` role at the site's school,
and the cookie is signed (utils/session.py). Users never get that role here.
"""
import os

from fastapi import APIRouter, Depends, HTTPException, Request, Response

from utils.auth_utils import (PasswordLoginRequest, UserAuth0Request,
                              auth_auth0_user, auth_user_with_password,
                              create_user, get_user, school_require_invitation,
                              touch_last_login)
from utils.permission import SchoolUser, editor_member, get_school_user, school_from_request
from utils.session import SessionError, clear_session_cookie, set_session_cookie

router = APIRouter()


def password_login_enabled() -> bool:
    """Email + password is for local development only: production signs in
    with OAuth. Set EDITOR_PASSWORD_LOGIN=true to turn it on."""
    return os.getenv("EDITOR_PASSWORD_LOGIN", "").lower() in ("1", "true", "yes")


async def _start_session(request: Request, response: Response, user_id: int) -> SchoolUser:
    """Sets the session cookie when the user is an editor at the site's school."""
    school = await school_from_request(request)
    user = await editor_member(user_id, school)
    if not user:
        raise HTTPException(status_code=403, detail=f"This account is not an editor at {school.name}")
    try:
        set_session_cookie(response, user.user_id, user.school_id)
    except SessionError as e:
        raise HTTPException(status_code=500, detail=str(e))
    await touch_last_login(user_id)
    return user


@router.post("/get_or_create_user", response_model=SchoolUser)
async def get_or_create_user(payload: UserAuth0Request, request: Request,
                             response: Response) -> SchoolUser:
    """Auth0 sign-in/sign-up, as in the app."""
    school = await school_from_request(request)

    email = await auth_auth0_user(payload)
    if not email:
        raise HTTPException(status_code=401, detail="Auth0 verification failed")

    user = await get_user(email)
    if not user:
        if school_require_invitation(school.school_type):
            raise HTTPException(status_code=403, detail=f"{school.name} only takes new users by invitation")
        user_id = await create_user(email, school.school_id)
        if not user_id:
            raise HTTPException(status_code=500, detail="Failed to create user")
    else:
        user_id = int(user["user_id"])

    return await _start_session(request, response, user_id)


# Older editor builds call this name.
router.add_api_route("/login_auth0", get_or_create_user, methods=["POST"],
                     response_model=SchoolUser)


@router.post("/login_with_password", response_model=SchoolUser)
async def login_with_password(payload: PasswordLoginRequest, request: Request,
                              response: Response) -> SchoolUser:
    """Email + password sign-in. An unknown email is a 401, not a sign-up."""
    if not password_login_enabled():
        raise HTTPException(status_code=404, detail="Password sign-in is turned off")
    user_id = await auth_user_with_password(payload)
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    return await _start_session(request, response, user_id)


@router.get("/me", response_model=SchoolUser)
async def me(user: SchoolUser = Depends(get_school_user)) -> SchoolUser:
    """The signed-in editor; 401 when the session is missing or expired."""
    return user


@router.post("/logout")
async def logout(response: Response) -> dict:
    clear_session_cookie(response)
    return {"ok": True}
