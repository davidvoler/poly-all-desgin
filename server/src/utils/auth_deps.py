"""FastAPI dependencies for reading the signed-in user from the
HttpOnly `user_id` cookie set by routers/auth.py. Use this on every
user-scoped endpoint instead of accepting `user_id` from the client —
the cookie is the only source the server should trust."""
from urllib.parse import urlparse

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

def current_user_id_school_id(request: Request) -> (int, int):
    raw = request.cookies.get("user_id")
    origin = request.headers.get("origin")
    hostname = urlparse(origin).hostname if origin else ""
    school_id = school_id_from_hostname(hostname)
    if not raw:
        return 0, school_id
    try:
        return int(raw), school_id
    except (TypeError, ValueError):
        return 0, school_id

def get_user_roles(user_id: int, school_id: int) -> list[str]:
    # Placeholder function to retrieve user roles from the database
    # In a real implementation, this would query the database for the user's roles
    if user_id == 1:
        return ["admin", "user"]
    elif user_id == 2:
        return ["user"]
    else:
        return []
    

