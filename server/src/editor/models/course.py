from pydantic import BaseModel


class Lesson(BaseModel):
    id: int
    course_id: int
    module_id: int
    content: str
    lang: str
    to_lang: str


