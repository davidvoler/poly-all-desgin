from pydantic import BaseModel, Field


class Option(BaseModel):
    text: str
    correct: bool = Field(default=False, exclude_if=lambda value: value is False)

#Full database exercise model
class Exercise(BaseModel):
    exercise_id: int | None = None
    course_id: int | None = None
    module_id: int | None = None
    lesson_id: int | None = None
    exercise_type: str | None = None
    word: str | None = None  # the word the exercise practises
    question: str | None = None
    options: list[Option] | None = None
    explanation: str | None = None
    sentence_alt1: str | None = None
    sentence_alt2: str | None = None
    sentence_alt3: str | None = None
    ruby_text: list | None| dict = []
    annotations: list | None = None
    answer: str | None = None
    weight: int | None = 0
