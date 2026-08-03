from pydantic import BaseModel
from enum import Enum

class PromptType(str, Enum):
    CREATE_LESSON = "create_lesson"
    GET_WORDS = "get_words"
    CREATE_MODULE = "create_module"


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

