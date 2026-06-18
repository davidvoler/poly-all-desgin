from pydantic import BaseModel

class SchoolUser(BaseModel):
    user_id: int = 0
    school_id: int = 0
    roles: list[str] = []
    status: str = "active"
    signed_terms_version: int|None = None
    roles: list = []


class SchoolUserBase(BaseModel):
    user_id: int = 0
    school_id: int = 0
