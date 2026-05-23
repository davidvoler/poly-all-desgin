from pydantic import BaseModel


class User(BaseModel):
    id: int|None = None
    school_id: int
    name: str
    email: str
    password: str
    is_active: bool
    admin: bool
    editor: bool
    reviewer: bool
    created_at: str|None = None
    updated_at: str|None = None