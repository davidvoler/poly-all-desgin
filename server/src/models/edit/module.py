from pydantic import BaseModel

class ModuleEdit(BaseModel):
    course_id: int
    module_id: int| None = 0
    title: str | None = ''
    description: str | None = ''
    words: list[str] | None = []
