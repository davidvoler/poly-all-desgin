from pydantic import BaseModel

class UserLessonProgress(BaseModel):
    user_id: int
    lesson_id: int
    progress: float = 0.0
    current_module: int = 1
    current_lesson: int = 1

class Lesson(BaseModel):
    id: int 
    name: str
    description: str = ''
    language: str 
    user_language: str
    module_count: int = 1
    lesson_count: int = 1
    tags : list[str] = []
    user_lesson_progress: UserLessonProgress | None = None

