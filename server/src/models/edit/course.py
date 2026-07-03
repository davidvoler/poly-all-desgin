from pydantic import BaseModel


class Course(BaseModel):
    course_id: int
    title: str | None = ''
    description: str | None = ''
    lang: str | None = ''
    to_lang: str | None = ''
    tags: list[str] | None = []
    metadata: dict | None = {}

class Revision(BaseModel):
    revision_id: int
    course_id: int
    title: str | None = ''
    description: str | None = ''
    lang: str | None = ''
    to_lang: str | None = ''
    tags: list[str] | None = []
    metadata: dict | None = {}

