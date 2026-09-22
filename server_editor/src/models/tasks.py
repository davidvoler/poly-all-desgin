from typing import Any

from pydantic import BaseModel


class TaskResults(BaseModel):
    course_id: str
    module_id: str
    success: bool
    errors: str | None = None
    success_count: int | None = None
    results: Any  = []


class TaskStatus(BaseModel):
    task_id: str
    task_type: str
    status: str
    results: list[Any]|None = []