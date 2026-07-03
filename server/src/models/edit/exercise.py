from pydantic import BaseModel

class ExerciseRequest(BaseModel):
    course_id: int| None = 0
    module_id: int| None = 0
    lesson_id: int| None = 0

class Exercise(BaseModel):
    exercise_id: int
    exercise_type: str | None = ''
    sentence: str | None = ''
    options: list[str] | None = []
    audio: str | None = ''
    word1: str | None = ''
    word2: str | None = ''
    word3: str | None = ''
    sentence_alt1: str | None = ''
    sentence_alt2: str | None = ''
    sentence_alt3: str | None = ''
    ruby_text: list[str] | None = []
    annotations: list[str] | None = []
    weight: int | None = 11
