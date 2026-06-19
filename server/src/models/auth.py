from pydantic import BaseModel

class SchoolUser(BaseModel):
    user_id: int = 0
    school_id: int = 0
    roles: list[str] = []
    status: str = "active"
    signed_terms_version: int|None = None
    roles: list[str]| None = []
    #school data

class User(BaseModel):
    user_id: int = 0
    name: str = ""
    

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
    user_id: int | None = None
    school_id: int | None = None
    name: str | None = None
    domain: str | None = ''
    preference: dict | None = {}
    roles: list[str]| None = [] # applicable for dashboard users
    plan: list[str] | None = [] # applicable for none free schools
    school_user_id: int | None = None
    #school data
    school_name: str | None = None
    school_type: str | None = None
    logo_url: str | None = None
    primary_color: str | None = None
    # Set when a private school needs the client to collect an invitation
    # code before the user can be created/joined. When True the rest of the
    # payload is empty — the client should show the invitation prompt.
    requires_invitation: bool = False


class InvitationUseRequest(BaseModel):
    id_token: str | None = None
    email: str | None = None
    name: str | None = None
    sub: str | None = None
    invitation_token: str| None = None
    course_id: int | None = None
    lang: str | None = None
    to_lang: str | None = None
    



