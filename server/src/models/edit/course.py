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
    level: str | None = ''
    # Only populated by GET /courses (the create_with_ai_poc "My courses"
    # list) — None everywhere else, kept optional so existing consumers of
    # GET /course/{id} and POST /course are unaffected.
    word_count: int | None = None
    module_count: int | None = None
    lesson_count: int | None = None
    ready_lesson_count: int | None = None

class CourseImport(BaseModel):
    document: str


class CourseExport(BaseModel):
    course_id: int
