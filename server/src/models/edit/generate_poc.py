from pydantic import BaseModel
from enum import Enum

class PromptType(str, Enum):
    CREATE_LESSON = "create_lesson"
    GET_WORDS = "get_words"
    CREATE_COURSE = "create_course"

class Prompt(BaseModel):
    provider: str|None = None
    model: str|None = None
    lang: str|None = None
    to_lang: str|None = None
    prompt: str
    prompt_type: PromptType|None = None 
    extra_data: dict|None = None
    token_estimate: int|None = None
    estimated_cost: float|None = None

class GenerateCourseRequest(Prompt):
    prompt_type: PromptType | None = PromptType.CREATE_COURSE
    title: str | None = ''
    description: str | None = ''

class GenerateLessonRequest(Prompt):
    prompt_type: PromptType | None = PromptType.CREATE_LESSON
    title: str | None = ''
    course_id: int | None = None
    module_id: int | None = None
    words: list[str] | None = []

class GenerateCourseWordsListRequest(BaseModel):
    prompt_type: PromptType | None = PromptType.GET_WORDS
    course_id: int | None = None
    module_id: int | None = None
    level: int | None = 0



# Responses 
class PromptResponseOption(BaseModel):
    title: str | None = ''
    text: str | None = ''
    action: str | None = ''
    
class PromptResponse(BaseModel):
    prompt_type: PromptType | None = None
    prompt: str | None = ''
    title: str | None = ''
    description: str | None = ''
    options: list[PromptResponseOption] | None = []
    content: dict|None = {}
    response: str | None = ''
    


