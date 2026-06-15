"""FastAPI dependencies for reading the signed-in user from the
HttpOnly `user_id` cookie set by routers/auth.py. Use this on every
user-scoped endpoint instead of accepting `user_id` from the client —
the cookie is the only source the server should trust."""
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
    if hostname.startswith("school1"):
        return 2
    return -1

def current_user_id_school_id(request: Request) -> (int, int):
    raw = request.cookies.get("user_id")
    hostname = request.url.hostname
    school_id = school_id_from_hostname(hostname)
    if not raw:
        return 0, school_id
    try:
        return int(raw), school_id
    except (TypeError, ValueError):
        return 0, school_id
    # if not raw:
    #     raise HTTPException(status_code=401, detail="Not signed in")
    # try:
    #     return int(raw)
    # except (TypeError, ValueError):
    #     raise HTTPException(status_code=401, detail="Malformed session cookie")

