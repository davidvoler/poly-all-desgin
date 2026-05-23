from pydantic import BaseModel

class School(BaseModel):
    id: int|None = None
    name: str
    is_public: bool
    created_at: str|None = None
    updated_at: str|None = None