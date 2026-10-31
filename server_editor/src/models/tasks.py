from typing import Any
from pydantic import BaseModel
from models.prompts import PromptResponse
import time

class TaskResults(BaseModel):
    task_id: str = ''
    poll_count: int = 0
    execution_time: float | None = None
    ready: bool = False
    success: bool = False
    errors: str | None = None
    prompt_response: PromptResponse | None = None

class TasksResultsRequest(BaseModel):
    task_id:str
    poll_count: int = 0
    start_time: float | None = None
