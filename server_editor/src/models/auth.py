from pydantic import BaseModel

class SchoolUser(BaseModel):
    user_id: int | None = 0
    school_id: str | None = 0
    roles: list[str]| None = []
    status: str | None = "active"
    signed_terms_version: int|None = None
    permissions: dict | None = {}
    domain: str | None = None
    dashboard: bool | None = False
