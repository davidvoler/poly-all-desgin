from pydantic import BaseModel

from models.word import Word

class PromptsContext(BaseModel):
    context_id: int = 0
    course_id: int = 0
    module_id: int = 0
    lesson_id: int = 0
    words: list[Word] = []
