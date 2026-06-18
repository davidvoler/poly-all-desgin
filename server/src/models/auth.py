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