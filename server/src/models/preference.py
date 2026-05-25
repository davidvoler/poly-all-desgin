from pydantic import BaseModel
from models.course import Course

class Preference(BaseModel):
    user_id: int
    course_id: int|None = None
    module_id: int|None = None
    lesson_id: int|None = None
    ui_lang: str|None = None
    lang: str|None = None
    to_lang: str|None = None


