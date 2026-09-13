from pydantic import BaseModel

class Course(BaseModel):
    course_id: int|None = None
    description: str
    language: str
    to_language: str   