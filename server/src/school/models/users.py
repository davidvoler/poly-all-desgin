from pydantic import BaseModel
from datetime import datetime as DateTime


class SchoolUser(BaseModel):
    """One row in `school.school_users`. The shape returned to the dashboard
    on list/get — `password_hash` is omitted from responses (handled at the
    route layer)."""
    school_user_id: int | None = None
    school_id: int
    user_id: int | None = None
    name: str = ''
    email: str
    role: str = 'editor'                    # owner | editor | viewer
    assigned_languages: list[str] = []
    courses_owned: int = 0
    last_seen: DateTime | None = None
    status: str = 'active'                  # active | suspended
    created_at: DateTime | None = None


class SchoolUserCreate(BaseModel):
    """Payload for POST /api/v1/school/users/ — invite-style create that
    accepts a plaintext password and hashes it server-side. `user_id` may
    be NULL until the invitee accepts (we fill it from user_data.users)."""
    school_id: int
    name: str = ''
    email: str
    password: str | None = None
    role: str = 'editor'
    assigned_languages: list[str] = []


class LoginRequest(BaseModel):
    email: str
    password: str
    # Optional — when omitted, the server matches against any school the
    # email is registered with and returns the first hit.
    school_slug: str | None = None


class LoginResponse(BaseModel):
    """Returned by POST /api/v1/school/login on success. The dashboard
    stores this in memory and uses school_id + role to gate UI."""
    school_user_id: int
    school_id: int
    school_slug: str
    school_name: str
    name: str
    email: str
    role: str
