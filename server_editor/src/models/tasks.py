from pydantic import BaseModel


class TaskResults(BaseModel):
    method_name: str
    course_id: str
    success: bool
    error: str | None = None