from pydantic import BaseModel
from datetime import datetime as DateTime




class Achievement(BaseModel):
    achievement_id: int
    user_id: int
    course_id: int = 0
    lang: str
    title: str | None = ''
    description: str | None = ''
    date_earned: DateTime | None = None
    is_new: bool = False


