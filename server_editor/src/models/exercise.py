from pydantic import BaseModel

class Exercise(BaseModel):
    id: int
    name: str
    description: str
    course_id: int