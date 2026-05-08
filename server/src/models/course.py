from pydantic import BaseModel

class UserCourseProgress(BaseModel):
    user_id: int
    course_id: int
    progress: float = 0.0
    current_module: int = 1
    current_lesson: int = 1

class Course(BaseModel):
    id: int 
    name: str
    description: str = ''
    language: str 
    user_language: str
    module_count: int = 1
    lesson_count: int = 1
    tags : list[str] = []
    user_course_progress: UserCourseProgress | None = None
