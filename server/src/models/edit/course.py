from pydantic import BaseModel

class Course(BaseModel):
    course_id: int
    title: str | None = ''
    description: str | None = ''
    lang: str | None = ''
    to_lang: str | None = ''
    tags: list[str] | None = []
    metadata: dict | None = {}
    published: bool | None = False

class CourseImport(BaseModel):
    document: str


class CourseExport(BaseModel):
    course_id: int
