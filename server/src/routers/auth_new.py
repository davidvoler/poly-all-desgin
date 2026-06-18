from fastapi import APIRouter, HTTPException, Request, Response, Depends
from models.auth import PasswordLoginRequest, SchoolUser, UserAuth0Request, UserPref, InvitationUseRequest
from server.src.routers.auth_new_utils import auth_user_with_cookie
from server.src.school.models import school
from utils.auth_deps import  current_school
from models.school import School
from utils.auth_utils import (auth_auth0_user, 
                              use_invitation, 
                              auth_user_with_password,
                              auth_user_with_cookie,
                              school_create_user,
                              school_require_invitation, 
                              get_user,
                              create_user,
                              create_user_with_invitation)

router = APIRouter()






@router.post("/get_or_create_user", response_model=UserPref)
async def get_or_create_user(
    payload: UserAuth0Request,
    response: Response,
    school: School = Depends(current_school)):
    if not school:
        raise HTTPException(status_code=400, detail="Unknown school")
    auth_ok = await auth_auth0_user(payload)
    if not auth_ok:
        raise HTTPException(status_code=401, detail="Auth0 verification failed")
    user = await get_user(payload.email, school.school_id, payload.sub)
    if not user:
        if school_create_user(school):
            user = create_user(payload.email, school.school_id, payload.sub, payload.name)
        if school_require_invitation(school):
            return {
                "requires_invitation":True
            }
    return {}


@router.post("/use_invitation", response_model=UserPref)
async def use_invitation(
    payload: InvitationUseRequest,
    response: Response,
    school: School = Depends(current_school)):

    invitation_ok = await use_invitation(payload, school)
    if not invitation_ok:
        raise HTTPException(status_code=400, detail="Invalid invitation")
    #TODO: return full data and set cookie


@router.post("/login_with_password", response_model=UserPref)
async def login_with_password(payload: PasswordLoginRequest, 
                              response: Response, 
                              school: School = Depends(current_school)):

    auth_ok = await auth_user_with_password(payload)
    if not auth_ok:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    #TODO: return full data and set cookie
    

@router.post("/login_with_cookie", response_model=UserPref)
async def login_with_cookie(request: Request, 
                            school: School = Depends(current_school)):
    login_ok = await auth_user_with_cookie(request, school)
    if not login_ok:
        raise HTTPException(status_code=401, detail="Not signed in")
    #TODO: return full data but don't update the cookie 


@router.post("/logout")
async def logout(response: Response):
    """Clear the session cookies. The client doesn't need to send any
    body — just hit this and forget."""
    for key in (_COOKIE_NAME, "lang", "to_lang"):
        response.delete_cookie(key)
    return {"ok": True}




@router.post("/school_user_permission", response_model=SchoolUser)
async def school_user_permission( response: Response, user = Depends(current_school_user_full)):
    """Check the user's permissions for the current school. Get it from Databases - do not use cache 
    Use this url before important tasks such as deleting users or courses """
    #TODO: return school+user information
    return user



@router.post("/join_with_invitation", response_model=UserPref)
async def join_with_invitation(payload: InvitationUseRequest, response: Response, user = Depends(current_school_user_full)):
    user_exists = get_user(payload.email, payload.school_id, payload.sub)
    if user_exists:
        #TODO: login user and return data
        pass
    else:
        return await create_user_with_invitation(payload)
    



"""
1. return full information 
    a. pref 
    b. school info
    c. user_school info (roles, plan, etc.)
2. login with password - do not create a new user if the email doesn't exist, just return 401
3. login with cookie -  this is where we add extra security - verify the user is active etc. 
4. consider a single function for user verification 
5. Where do we request the user to enter invitation code  

6. we have multiple fields in school for school type 
    a. is_public
    b. plan
    c. school_type
    Do we need all of them? Can we simplify?
    
What is the process for a private school 
- login - create user - > verify invitation code  
- login with invitation code - optional
- login - if user doesn't exist, ask for invitation code - ond create a new user after invitation code is verified 
  What is the simplest way to start with?

Deep link flow for private schools:
 - user clicks on an invitation link that includes the invitation token
 - authenticate with auth0
 - send to the server auth data + invitation data 
 - if users is not new in school - just login the user
 - if user is completely new - or new in school 
    - validate the invitation token
    - if valid, create the user and log them in, set user preferences like course, language, etc. based on the invitation data
    - if invalid, return an error
"""