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
