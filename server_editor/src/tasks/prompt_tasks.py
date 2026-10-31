from taskiq import Context, TaskiqDepends
from prompt_routers.main_router import handle_prompt_request, PromptRequest
from task_runner import broker
from models.tasks import TasksResultsRequest
import time

@broker.task
async def _handle_prompt_task(
    req: PromptRequest, 
    context: Context = TaskiqDepends()):
    return await handle_prompt_request(req)

async def handle_prompt_task(req: PromptRequest)->TasksResultsRequest:
    task = await _handle_prompt_task.kiq(req)
    return TasksResultsRequest(
        task_id=task.task_id,
        start_time=time.time()
    )