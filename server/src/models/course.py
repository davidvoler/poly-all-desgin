from pydantic import BaseModel

class UserCourseProgress(BaseModel):
    user_id: int
    course_id: int
    progress: float = 0.0
    current_module: int = 1
    current_lesson: int = 1

class Lesson(BaseModel):
    id: int 
    name: str
    description: str = ''
    words: list[str] = []
    completed: int = 0

class Module(BaseModel):
    id: int 
    name: str
    description: str = ''
    words: list[str] = []
    lessons : list['Lesson'] = []
    completed: int = 0

class Course(BaseModel):
    id: int 
    title: str
    description: str = ''
    lang: str
    to_lang: str 
    tags : list[str] = []
    user_course_progress: UserCourseProgress | None = None


class Exercise(BaseModel):
    id: int
    sentence: str
    exercise_type: str
    options: list[str] = []
    audio: str = ''
    word1: str = ''
    word2: str = ''
    word3: str = ''
    sentence_id: int | None = None
    to_sentence_id: int | None = None