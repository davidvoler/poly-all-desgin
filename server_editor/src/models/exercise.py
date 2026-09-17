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
