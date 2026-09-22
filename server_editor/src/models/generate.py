from pydantic import BaseModel

class GenerateRequest(BaseModel):
    course_id: int
    module_id: int
    lesson_id: int
    level: str = "A1"
    lang: str
    to_lang: str
    provider: str
    model: str
    cache: bool = True

class GenerateWordsRequest(GenerateRequest):
    count: int
    already_used: list[str] = []

class GenerateLessonRequest(GenerateRequest):
    words: list[str]



class GenerateQuizRequest(GenerateRequest):
    number_of_questions: int
    word: str

class BreakTextRequest(GenerateRequest):
    text: str
    