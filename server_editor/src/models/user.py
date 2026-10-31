from pydantic import BaseModel

class Permissions(BaseModel):
    can_edit: bool = False
    can_delete: bool = False
    can_view: bool = True

class User(BaseModel):
    id: int
    school: str | None = 'default'
    permissions: Permissions = Permissions()