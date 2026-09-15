from pydantic import BaseModel


class TaskResults(BaseModel):
    method_name: str
    course_id: str
    success: bool
    errors: str | None = None
    success_count: int | None = None
    results: list[any]  = []


class TaskStatus(BaseModel):
    task_id: str
    task_type: str
    status: str
    results: list[any]|None = []