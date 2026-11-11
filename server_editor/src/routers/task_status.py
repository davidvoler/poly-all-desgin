from fastapi import APIRouter
from taskiq import TaskiqResult
from models.tasks import  TaskResults, TasksResultsRequest
from task_runner import broker

router = APIRouter()


async def check_task_status(task: TasksResultsRequest) -> TaskResults:
    is_ready: bool = await broker.result_backend.is_result_ready(task.task_id)
    if is_ready:
        result: TaskiqResult = await broker.result_backend.get_result(task.task_id)
        return TaskResults(
            task_id=task.task_id,
            poll_count=task.poll_count,
            execution_time=result.execution_time,
            ready=True,
            success=not result.is_err,
            errors=str(result.error) if result.is_err else None,
            prompt_response=result.return_value,
        )
    else:
        return TaskResults(task_id=task.task_id, 
                           poll_count=task.poll_count,
                           ready=False)
    

@router.post("/tasks_results")
async def get_task_status(req: list[TasksResultsRequest]) -> list[TaskResults]:
    task_statuses: list[TaskResults] = []
    for task in req:
        result = await check_task_status(task)
        task_statuses.append(result)
    return task_statuses