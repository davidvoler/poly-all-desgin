from pydantic import BaseModel
from models.course import Course

class Preferences(BaseModel):
    user_id: int
    current_course: Course | None = None
    # think of more preferences here 
    #stats
    lessons: int = 0
    words: int = 0
    sentences: int = 0


