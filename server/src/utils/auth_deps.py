"""FastAPI dependencies for reading the signed-in user from the
HttpOnly `user_id` cookie set by routers/auth.py. Use this on every
user-scoped endpoint instead of accepting `user_id` from the client —
the cookie is the only source the server should trust."""
from datetime import datetime, timedelta
from urllib.parse import urlparse
from utils.db import get_query_results, run_query
from utils.user_school_data import get_user_full_data
from models.auth import SchoolUserBase, SchoolUser
from fastapi import HTTPException, Request
from models.school import School


SCHOOL_CACHE = {}
SCHOOL_CACHE_LAST_LOADED = datetime.now()
COOKIE_MAX_AGE = 60 * 60 * 24 * 30 # 30 days in seconds
COOKIE_NAME = "user_id"

async def _load_schools_cache():
    global SCHOOL_CACHE
    sql = "SELECT * FROM school.schools"
    results = await get_query_results(sql, None)
    SCHOOL_CACHE = {row['school_id']: row for row in results}
    SCHOOL_CACHE_LAST_LOADED = datetime.now()


async def get_schools_cache() -> dict:
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


async def current_school_id(request: Request) -> int:
    origin = request.headers.get("origin")
    hostname = urlparse(origin).hostname if origin else ""
    school_id = await school_id_from_hostname(hostname)
    return school_id    

async def current_school(request: Request) -> School:
    origin = request.headers.get("origin")
    hostname = urlparse(origin).hostname if origin else ""
    schools_cache = await get_schools_cache()
    print(f"Schools hostname: {hostname}")
    for school_id, school in schools_cache.items():
        print(f"Checking school_id={school_id}, school_url={school['school_url']}, school_dashboard_url={school['school_dashboard_url']}")
        if school['school_url'] == hostname or school['school_dashboard_url'] == hostname:
            return School(**school)
    return None


async def current_school_user_full(request: Request) -> SchoolUser:
    raw = request.cookies.get("user_id")
    origin = request.headers.get("origin")
    hostname = urlparse(origin).hostname if origin else ""
    school_id = await school_id_from_hostname(hostname)
    user_id = -1
    try:
        user_id = int(raw)
    except (TypeError, ValueError) as e:
        print(f"Error parsing user_id from cookie: {e}")
        #TODO: Handle the error
        user_id = -1
    print (user_id, school_id)
    return await get_user_full_data(user_id, school_id)
            




async def get_or_create_school_user(user_id: int, school_id: int) -> SchoolUser:
    data = await get_query_results(
        """SELECT * FROM school.school_users
        WHERE user_id = %s AND school_id = %s LIMIT 1""",
        (user_id, school_id),
    )
    for row in data:
        return SchoolUser(**row)
    # User not found, create a new one. `roles` is a varchar[] column —
    # pass the Python list directly so psycopg adapts it to a Postgres
    # array; json.dumps would store the literal string "[...]" instead.
    school_user = SchoolUser(user_id=user_id, school_id=school_id, roles=["student"])
    await run_query(
        """INSERT INTO school.school_users (user_id, school_id, roles)
        VALUES (%s, %s, %s)""",
        (school_user.user_id, school_user.school_id, school_user.roles),
    )
    return school_user



