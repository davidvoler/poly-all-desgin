from pydantic import BaseModel

class UserCourseProgress(BaseModel):
    user_id: int
    course_id: int
    progress: float = 0.0
    current_module: int = 1
    current_lesson: int = 1

class Lesson(BaseModel):
    lesson_id: int 
    title: str| None = ''
    description: str | None = ''
    words: list[str] | None = []
    completed: int | None = 0

class Module(BaseModel):
    module_id: int 
    title: str| None = ''
    description: str | None = ''
    words: list[str] | None = []
    completed: int | None = 0

class Course(BaseModel):
    course_id: int 
    title: str| None = ''
    description: str | None = ''
    lang: str
    to_lang: str 
    tags : list[str] | None = []
    user_course_progress: UserCourseProgress | None = None


class Exercise(BaseModel):
    exercise_id: int
    sentence: str | None = ''
    exercise_type: str | None = ''
    options: list | None = []
    audio: str | None = ''
    word1: str | None = ''
    word2: str | None = ''
    word3: str | None = ''
    sentence_id: int |  None = None
    to_sentence_id: int | None = None