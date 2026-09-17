import json
import json
from unittest.mock import Base
from pydantic import BaseModel



#Full database exercise model
class Exercise(BaseModel):
    exercise_id: int | None = None
    course_id: int | None = None
    module_id: int | None = None
    lesson_id: int | None = None
    exercise_type: str | None = None
    question: str | None = None
    options: dict | None = None
    explanation: str | None = None
    sentence_alt1: str | None = None
    sentence_alt2: str | None = None
    sentence_alt3: str | None = None
    ruby_text: list | None = None
    annotations: list | None = None
    answer: str | None = None
    weight: int | None = 0


class SingleChoice(BaseModel):
    sentence: str | None = None
    incorrect_options: list[str] | None = None
    translation: str | None = None
class SentenceTranslation(BaseModel):
    sentence: str | None = None
    translation: str | None = None

class SingleChoicePrompt(BaseModel):
    prompt: str = "Please create NUM_SENTENCES single-choice questions for the word: WORD"
    response_format: list[SingleChoice] = []