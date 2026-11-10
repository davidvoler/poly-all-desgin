"""The editor's signed session cookie.

The cookie holds a JWT signed with EDITOR_SESSION_SECRET, naming the user and
the school they signed in to. It cannot be forged or edited without the secret,
and it expires (EDITOR_SESSION_DAYS, default 7).

Cookie settings follow the main server's: COOKIE_SECURE (set true behind
HTTPS) and COOKIE_SAMESITE (default lax). It is always HttpOnly.
"""
import os
import time

from fastapi import Response
from jose import jwt
from jose.exceptions import JWTError

COOKIE_NAME = "editor_session"
_ALGORITHM = "HS256"
_TOKEN_TYPE = "editor_session"


class SessionError(Exception):
    pass


def _secret() -> str:
    secret = os.getenv("EDITOR_SESSION_SECRET", "")
    if len(secret) < 32:
        raise SessionError("EDITOR_SESSION_SECRET must be set to at least 32 characters")
    return secret


def _max_age() -> int:
    return int(os.getenv("EDITOR_SESSION_DAYS", "7")) * 24 * 60 * 60


def create_token(user_id: int, school_id: int) -> str:
    now = int(time.time())
    return jwt.encode(
        {"sub": str(user_id), "school_id": school_id, "typ": _TOKEN_TYPE,
         "iat": now, "exp": now + _max_age()},
        _secret(), algorithm=_ALGORITHM)


def read_token(token: str) -> tuple[int, int]:
    """The user and school ids in a valid token. Raises SessionError otherwise,
    including when it has expired."""
    try:
        claims = jwt.decode(token, _secret(), algorithms=[_ALGORITHM])
        if claims.get("typ") != _TOKEN_TYPE:
            raise SessionError("Not an editor session")
        return int(claims["sub"]), int(claims["school_id"])
    except (JWTError, KeyError, TypeError, ValueError) as e:
        raise SessionError(str(e)) from e


def _flag(name: str) -> bool:
    return os.getenv(name, "").lower() in ("1", "true", "yes")


def set_session_cookie(response: Response, user_id: int, school_id: int) -> None:
    response.set_cookie(
        COOKIE_NAME, create_token(user_id, school_id), max_age=_max_age(),
        httponly=True, secure=_flag("COOKIE_SECURE"),
        samesite=os.getenv("COOKIE_SAMESITE", "lax").lower(), path="/")


def clear_session_cookie(response: Response) -> None:
    response.delete_cookie(
        COOKIE_NAME, httponly=True, secure=_flag("COOKIE_SECURE"),
        samesite=os.getenv("COOKIE_SAMESITE", "lax").lower(), path="/")
