from pydantic import BaseModel
from models.course import Course

class Preference(BaseModel):
    # Optional on request — the server fills it from the auth cookie.
    # Always populated on response (the DB row has it).
    user_id: int | None = None
    course_id: int|None = None
    module_id: int|None = None
    lesson_id: int|None = None
    ui_lang: str|None = None
    lang: str|None = None
    to_lang: str|None = None


