"""FastAPI dependencies for reading the signed-in user from the
HttpOnly `user_id` cookie set by routers/auth.py. Use this on every
user-scoped endpoint instead of accepting `user_id` from the client —
the cookie is the only source the server should trust."""
from urllib.parse import urlparse
from utils.user_school_data import get_user_full_data
from models.auth import SchoolUserBase, SchoolUser

from fastapi import HTTPException, Request

def current_user_id(request: Request) -> int:
    raw = request.cookies.get("user_id")
    if not raw:
        return 0
    try:
        return int(raw)
    except (TypeError, ValueError):
        return 0
    # if not raw:
    #     raise HTTPException(status_code=401, detail="Not signed in")
    # try:
    #     return int(raw)
    # except (TypeError, ValueError):
    #     raise HTTPException(status_code=401, detail="Malformed session cookie")


def school_id_from_hostname(hostname: str) -> int:
    print(f"Determining school_id from hostname: {hostname}")
    if not hostname:
        return -1
    if hostname in ["localhost", "127.0.0.1", "app.polyglots.social", "dashboard.polyglots.social"]:
        return 1
    elif hostname in ("school1.app.polyglots.social", "school1.dashboard.polyglots.social"):
        return 2
    return -1

async def current_school_user(request: Request) -> SchoolUserBase:
    raw = request.cookies.get("user_id")
    origin = request.headers.get("origin")
    hostname = urlparse(origin).hostname if origin else ""
    school_id = school_id_from_hostname(hostname)
    if not raw:
        return SchoolUserBase(user_id=0, school_id=school_id)
    try:
        return SchoolUserBase(user_id=int(raw), school_id=school_id)
    except (TypeError, ValueError):
        return SchoolUserBase(user_id=0, school_id=school_id)

    
async def current_school_user_full(request: Request) -> SchoolUser:
    raw = request.cookies.get("user_id")
    origin = request.headers.get("origin")
    hostname = urlparse(origin).hostname if origin else ""
    school_id = school_id_from_hostname(hostname)
    user_id = -1
    try:
        user_id = int(raw)
    except (TypeError, ValueError):
        #TODO: Handle the error
        user_id = -1
    return await get_user_full_data(user_id, school_id)
            

