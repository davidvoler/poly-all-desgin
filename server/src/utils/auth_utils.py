from models.auth import PasswordLoginRequest, UserAuth0Request, UserPref, InvitationUseRequest
from server.src.models.school import School
from fastapi import Request


async def auth_user(payload: UserAuth0Request) -> bool:
    return True

async def use_invitation(payload: InvitationUseRequest, school: School)-> bool:
    pass

async def auth_user_with_password(payload: PasswordLoginRequest) -> bool:
    pass

async def auth_user_with_cookie(request: Request, school: School) -> bool:
    pass

