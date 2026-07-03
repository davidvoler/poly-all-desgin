from pydantic import BaseModel

class Module(BaseModel):
    module_id: int
    title: str | None = ''
    description: str | None = ''
    words: list[str] | None = []
    completed: int | None = 0
    max_score: float | None = 0.0
    sum_score: float | None = 0.0
    num_attempts: int | None = 0
    current: int | None = 0
