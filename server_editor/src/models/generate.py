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


class QuizRequest(BaseModel):
    course_id: str
    module_id: str
    lesson_id: str
    provider: str
    model: str
    cache: bool = True
    number_of_questions: int
    word: str