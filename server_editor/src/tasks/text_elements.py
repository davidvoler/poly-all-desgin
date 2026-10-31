from taskiq import Context, TaskiqDepends
from task_runner import broker
from models.generate import BreakTextRequest
from models.tasks import TaskResult
from prompts.text_break import TextParts, get_text_parts

async def save_parts(parts: TextParts, break_request: BreakTextRequest):
    # Implement the logic to save the parts
    pass

async def get_text_elements(break_request: BreakTextRequest)->TextParts:
    parts = await get_text_parts(break_request.lang, 
                                 break_request.to_lang,
                                 break_request.level,
                                 break_request.text,
                                 break_request.provider,
                                 break_request.model)
    #save parts
    await save_parts(parts, break_request)
    return parts

async def get_text_elements_tasks(break_request: BreakTextRequest, context: Context = TaskiqDepends()):
    parts = await get_text_elements(break_request)
    return TaskResult(course_id=break_request.course_id,
                      module_id=break_request.module_id,
                      results=parts,
                      success=True)