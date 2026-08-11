from pydantic import BaseModel


class LessonEdit(BaseModel):
    course_id: int| None = 0
    module_id: int| None = 0
    lesson_id: int | None = 0
    title: str | None = ''
    description: str | None = ''
    words: list[str] | None = []
