from pydantic import BaseModel
from models.exercise import Exercise
class Lesson(BaseModel):
    course_id: int|None = None
    module_id: int|None = None
    lesson_id: int|None = None
    title: str|None = None
    description: str|None = None
    words: list[str]|None = None
    sentences: list[str]|None = None
    deleted: bool|None = False
    weight: int|None = 0
    # For a video part: where the part starts and ends in the module's video, in seconds.
    video_start: float|None = None
    video_end: float|None = None

class LessonFull(Lesson):
    lesson: Lesson|None = None
    exercises: list[Exercise]|None = None