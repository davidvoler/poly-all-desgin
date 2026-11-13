from taskiq import Context, TaskiqDepends
from prompt_routers.main_router import handle_prompt_request, PromptRequest
from prompts.course_instructions import use_course
from prompts.providers import use_api_keys
from task_runner import broker
from models.tasks import TasksResultsRequest
from utils.api_keys import resolve_keys
from utils.course_utils import get_course
from utils.permission import SchoolUser
import time

@broker.task
async def _handle_prompt_task(
    req: PromptRequest,
    school: str | None = None,
    user_id: int | None = None,
    context: Context = TaskiqDepends()):
    # The keys are decrypted here, in the worker, and live only for this task.
    # The course's guidance joins the shared instructions of every AI prompt of the task.
    guidance = (await get_course(req.course_id)).guidance if req.course_id else None
    with use_api_keys(await resolve_keys(school, user_id)), use_course(guidance):
        return await handle_prompt_request(req)

async def handle_prompt_task(req: PromptRequest, school_user: SchoolUser)->TasksResultsRequest:
    task = await _handle_prompt_task.kiq(req, school_user.school, school_user.user_id)
    return TasksResultsRequest(
        task_id=task.task_id,
        start_time=time.time()
    )
