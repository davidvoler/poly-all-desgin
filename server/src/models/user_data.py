from pydantic import BaseModel

class Results(BaseModel):
    user_id: int 
    lang: str
    lesson_id: int | None = 0
    module_id: int| None = 0
    course_id: int | None = 0
    exercise_id: int| None = 0
    sentence_id: int | None = 0
    word1: str| None = ''
    word2: str| None = ''
    word3: str| None = ''
    answer_delay_ms: str| None = 0
    attempts: int| None = 0
    correct: bool| None = False
    correct_ratio: float| None = 0.0
    incorrect_count: float| None = 0.0
    






class UserData(BaseModel):
    user_id: int
    language: str
    to_lang: str
    