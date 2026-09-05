from fastapi import APIRouter
from tasks.broker import result_backend, my_long_running_task
router = APIRouter()


@router.get("/tasks/{task_id}")
async def get_task_status(task_id: str):
    # 1. Check if the task has finished processing
    is_ready = await result_backend.is_result_ready(task_id)
    if not is_ready:
        return {
            "task_id": task_id,
            "status": "PENDING",
            "result": None,
        }

    # 2. Fetch the task outcome once execution completes
    task_result = await result_backend.get_result(task_id)
    
    # 3. Handle errors thrown inside the worker
    if task_result.is_err:
        return {
            "task_id": task_id,
            "status": "FAILED",
            "error": str(task_result.error),
        }

    return {
        "task_id": task_id,
        "status": "SUCCESS",
        "result": task_result.return_value,
        "execution_time_seconds": task_result.execution_time,
    }
