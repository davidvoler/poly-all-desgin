from pydantic import BaseModel

class Course(BaseModel):
    course_id: int
    title: str | None = ''
    description: str | None = ''
    lang: str | None = ''
    to_lang: str | None = ''
    tags: list[str] | None = []
    metadata: dict | None = {}



class CourseImport(BaseModel):
    document: str