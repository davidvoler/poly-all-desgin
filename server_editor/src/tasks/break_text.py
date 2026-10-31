from taskiq import Context, TaskiqDepends
from task_runner import broker
from models.tasks import TaskResults
from prompts.text_elements import break_text
from models.exercise import Exercise
from models.generate import BreakTextRequest


async def break_text_task(break_text_request: BreakTextRequest):
    



