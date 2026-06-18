from models.auth import (PasswordLoginRequest, UserAuth0Request, UserPref, 
                         InvitationUseRequest)
from server.src.models.school import School
from fastapi import Request


async def auth_auth0_user(payload: UserAuth0Request) -> bool:
    return True

async def use_invitation(payload: InvitationUseRequest, school: School)-> bool:
    pass

async def auth_user_with_password(payload: PasswordLoginRequest) -> bool:
    pass

async def auth_user_with_cookie(request: Request, school: School) -> bool:
    pass

def school_create_user(school: School) -> bool:
    if school.school_type == "private":
        return False
    if school.school_type == "no_charge":
        return True
    if school.school_type == "public":
        return True
    
def school_require_invitation(school: School) -> bool:
    if school.school_type == "private":
        return True
    return False

def create_user(user_id, school_id, email, name) -> UserPref:
    pass
def get_user(email: str, school_id: int, sub: str) -> UserPref:
    pass

def create_user_with_invitation(payload: InvitationUseRequest) -> UserPref:
    """ get or create user
        get or create school_user
        mark invitation as used
        set user preferences if in invitation
    """
    pass


