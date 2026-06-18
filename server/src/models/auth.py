from pydantic import BaseModel

class SchoolUser(BaseModel):
    user_id: int = 0
    school_id: int = 0
    roles: list[str] = []
    status: str = "active"
    signed_terms_version: int|None = None
    roles: list = []
    #school data


class SchoolUserBase(BaseModel):
    user_id: int = 0
    school_id: int = 0



class SchoolData(BaseModel):
    school_id: int
    roles: list[str]
    status: str
    school_name: str
    school_type: str
    logo_url: str | None
    primary_color: str | None


class SchoolDataWithUser(SchoolData):
    school_user: SchoolUser | None = None
    school: SchoolData | None = None



class UserAuth0Request(BaseModel):
    id_token: str | None = None
    email: str | None = None
    name: str | None = None
    sub: str | None = None

class PasswordLoginRequest(BaseModel):
    email: str
    password: str


class UserPref(BaseModel):
    """Return shape for the auth routes — combines the bare user row
    with the most-recent Preference so the home page can paint without
    a second round-trip. `preference` is null for a brand-new user who
    hasn't picked a course yet.

    `school_user` carries the caller's membership in the school resolved
    from the request hostname (roles, status, signed-terms). The
    dashboard reads `school_user.roles` to gate admin-only UI, so it
    must be serialized — not silently dropped."""
    user_id: int
    school_id: int
    email: str
    name: str
    preference: dict | None = None
    school_user: SchoolUser | None = None


class InvitationUseRequest(BaseModel):
    id_token: str | None = None
    email: str | None = None
    name: str | None = None
    sub: str | None = None
    invitation_token: str