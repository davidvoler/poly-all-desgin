"""Learner-app auth (v2) — school-scoped sign-in built on utils/auth_utils.

Resolves the school from the request Origin (current_school) instead of a
bare school_id, and returns a full UserPref (preference + roles + school
branding) on every successful login.

Flows:
  * get_or_create_user  — Auth0 sign-in. Public schools auto-create the
    user; private schools return requires_invitation=True so the client
    collects an invitation code and calls /use_invitation.
  * use_invitation      — deep-link / private-school join: validate the
    invitation, create-or-login the user, seed preferences, set the cookie.
  * login_with_password — email + password; never auto-creates (401 on
    unknown email).
  * login_with_cookie   — restore a session from the cookie, re-checking the
    user is still an active member (does not refresh the cookie).

This router is not mounted yet — wire it into main.py (e.g. prefix
"/api/v1/auth2") once it supersedes routers/auth.py.
"""
from fastapi import APIRouter, Depends, HTTPException, Request, Response

from models.auth import (InvitationUseRequest, PasswordLoginRequest, SchoolUser,
                         UserAuth0Request, UserPref)
from models.school import School
from utils.auth_deps import current_school, current_school_user_full
from utils.auth_utils import (auth_auth0_user, auth_user_with_cookie,
                              auth_user_with_password, build_user_pref,
                              clear_session_cookies, create_user,
                              create_user_with_invitation, get_user,
                              is_school_user_active, school_require_invitation,
                              set_session_cookie)

router = APIRouter()


@router.post("/get_or_create_user", response_model=UserPref)
async def get_or_create_user(
        payload: UserAuth0Request,
        response: Response,
        school: School = Depends(current_school)):
    """Auth0 sign-in/sign-up. Sets the session cookie and returns the full
    UserPref. On a private school where the user doesn't exist yet, returns
    requires_invitation=True instead of creating the user."""
    if not school:
        raise HTTPException(status_code=400, detail="Unknown school")

    email = await auth_auth0_user(payload)
    if not email:
        raise HTTPException(status_code=401, detail="Auth0 verification failed")

    user = await get_user(email)
    if not user:
        if school_require_invitation(school):
            # Private school: defer creation until the client supplies a valid
            # invitation code (then it calls /use_invitation).
            return UserPref(
                requires_invitation=True,
                school_id=school.school_id,
                school_name=school.name,
                school_type=school.school_type,
            )
        user_id = await create_user(email, school.school_id)
        if not user_id:
            raise HTTPException(status_code=500, detail="Failed to create user")
    else:
        user_id = int(user["user_id"])

    pref = await build_user_pref(user_id, school)
    set_session_cookie(response, user_id, school.domain)
    return pref


@router.post("/use_invitation", response_model=UserPref)
async def use_invitation(
        payload: InvitationUseRequest,
        response: Response,
        school: School = Depends(current_school)):
    """Redeem an invitation code: validate it, create-or-login the user, seed
    any preference carried on the invite, and set the session cookie."""
    if not school:
        raise HTTPException(status_code=400, detail="Unknown school")

    pref = await create_user_with_invitation(payload, school)
    if not pref:
        raise HTTPException(status_code=400, detail="Invalid invitation")

    set_session_cookie(response, pref.user_id, school.domain)
    return pref


@router.post("/login_with_password", response_model=UserPref)
async def login_with_password(
        payload: PasswordLoginRequest,
        response: Response,
        school: School = Depends(current_school)):
    """Email + password sign-in. Never creates a user — an unknown email is a
    401, not a sign-up."""
    if not school:
        raise HTTPException(status_code=400, detail="Unknown school")

    user_id = await auth_user_with_password(payload)
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    pref = await build_user_pref(user_id, school)
    set_session_cookie(response, user_id, school.domain)
    return pref


@router.post("/login_with_cookie", response_model=UserPref)
async def login_with_cookie(
        request: Request,
        school: School = Depends(current_school)):
    """Restore a session from the `user_id` cookie. Re-checks the user is
    still an active member of this school (the extra-security step), and does
    NOT refresh the cookie."""
    if not school:
        raise HTTPException(status_code=400, detail="Unknown school")

    user_id = auth_user_with_cookie(request)
    if not user_id:
        raise HTTPException(status_code=401, detail="Not signed in")
    if not await is_school_user_active(user_id, school.school_id):
        raise HTTPException(status_code=401, detail="Account is not active")

    return await build_user_pref(user_id, school)


@router.post("/logout")
async def logout(response: Response):
    """Clear the session cookies. The client doesn't need to send any body —
    just hit this and forget."""
    clear_session_cookies(response)
    return {"ok": True}


@router.post("/school_user_permission", response_model=SchoolUser)
async def school_user_permission(user: SchoolUser = Depends(current_school_user_full)):
    """The user's roles/status for the current school, read straight from the
    DB (no cache). Call this before sensitive actions like deleting users or
    courses."""
    return user


@router.post("/join_with_invitation", response_model=UserPref)
async def join_with_invitation(
        payload: InvitationUseRequest,
        response: Response,
        school: School = Depends(current_school)):
    """Like /use_invitation but tolerant of an already-joined user: existing
    members are simply logged back in; everyone else goes through the
    invitation-validated create path."""
    if not school:
        raise HTTPException(status_code=400, detail="Unknown school")

    existing = await get_user(payload.email)
    if existing and await is_school_user_active(int(existing["user_id"]), school.school_id):
        pref = await build_user_pref(int(existing["user_id"]), school)
    else:
        pref = await create_user_with_invitation(payload, school)
        if not pref:
            raise HTTPException(status_code=400, detail="Invalid invitation")
    set_session_cookie(response, pref.user_id, school.domain)
    return pref
