from pydantic import BaseModel
from datetime import datetime as DateTime
from enum import Enum

class AchievementType(str, Enum):
    LESSONS_COMPLETED = "lessons_completed"
    WORDS_LEARNED = "words_learned"



class Achievement(BaseModel):
    achievement_id: int
    user_id: int
    course_id: int = 0
    lang: str
    achievement_type: AchievementType
    count_elements: int
    created_at: DateTime | None = None
    is_new: bool = False


