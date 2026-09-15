from pydantic import BaseModel

class GenerateQuizRequest(BaseModel):
    course_id: int
    module_id: int
    lesson_id: int
    lang: str
    to_lang: str

class GenerateLessonRequest(BaseModel):
    course_id: int
    module_id: int
    words: list[str]
    lang: str
    to_lang: str


class GenerateWordsRequest(BaseModel):
    pass