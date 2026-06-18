from pydantic import BaseModel

class SchoolUser(BaseModel):
    user_id: int = 0
    school_id: int = 0
    roles: list[str] = []
    status: str = "active"
    signed_terms_version: int = 0
    permissions: dict[str, bool] = {}
    is_school_public: bool = False


class SchoolUserBase(BaseModel):
    user_id: int = 0
    school_id: int = 0
