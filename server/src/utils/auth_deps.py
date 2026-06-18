"""FastAPI dependencies for reading the signed-in user from the
HttpOnly `user_id` cookie set by routers/auth.py. Use this on every
user-scoped endpoint instead of accepting `user_id` from the client —
the cookie is the only source the server should trust."""
from datetime import datetime, timedelta
from urllib.parse import urlparse
from utils.db import get_query_results
from utils.user_school_data import get_user_full_data
from models.auth import SchoolUserBase, SchoolUser
from fastapi import HTTPException, Request

SCHOOL_CACHE = {}
SCHOOL_CACHE_LAST_LOADED = datetime.now()


async def _load_schools_cache():
    global SCHOOL_CACHE
    sql = "SELECT * FROM school.schools"
    results = await get_query_results(sql, None)
    SCHOOL_CACHE = {row['school_id']: row for row in results}
    SCHOOL_CACHE_LAST_LOADED = datetime.now()


async def get_schools_cache():
    n = datetime.now()
    global SCHOOL_CACHE
    if not SCHOOL_CACHE or (n - SCHOOL_CACHE_LAST_LOADED) > timedelta(hours=1):
        await _load_schools_cache()
    return SCHOOL_CACHE


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




async def school_id_from_hostname(hostname: str) -> int:
    print(f"Determining school_id from hostname: {hostname}")
    schools_cache = await get_schools_cache()
    print(f"Schools hostname: {hostname}")
    for school_id, school in schools_cache.items():
        print(f"Checking school_id={school_id}, school_url={school['school_url']}, school_dashboard_url={school['school_dashboard_url']}")
        if school['school_url'] == hostname or school['school_dashboard_url'] == hostname:
            return school_id
    return -1

async def current_school_user(request: Request) -> SchoolUserBase:
    raw = request.cookies.get("user_id")
    origin = request.headers.get("origin")
    hostname = urlparse(origin).hostname if origin else ""
    school_id = await school_id_from_hostname(hostname)
    print(f"Current school user: raw={raw}, hostname={hostname}, school_id={school_id}")
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
    school_id = await school_id_from_hostname(hostname)
    print(f"Current school user full: raw={raw}, hostname={hostname}, school_id={school_id}")
    user_id = -1
    try:
        user_id = int(raw)
    except (TypeError, ValueError):
        #TODO: Handle the error
        user_id = -1
    return await get_user_full_data(user_id, school_id)
            

