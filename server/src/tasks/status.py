from fastapi import APIRouter

from tasks.broker import result_backend
from models.edit.generate_poc_new import TaskStart

router = APIRouter()


@router.get("/{task_id}", response_model=TaskStart)
async def get_task_status(task_id: str) -> TaskStart:
    """Poll a background job kicked by one of the generate_poc_new
    endpoints. The job writes its output straight to the DB (course.words,
    lesson.sentences, course_simple.exercise), so the client doesn't read
    the task's return value — it just waits for `completed` / `error` and
    then re-fetches the course."""
    is_ready = await result_backend.is_result_ready(task_id)
    if not is_ready:
        return TaskStart(task_id=task_id, status="PENDING", completed=False)

    task_result = await result_backend.get_result(task_id, with_logs=False)
    if task_result.is_err:
        return TaskStart(
            task_id=task_id,
            status="FAILED",
            error=str(task_result.error),
            completed=True,
        )
    return TaskStart(task_id=task_id, status="SUCCESS", completed=True)
