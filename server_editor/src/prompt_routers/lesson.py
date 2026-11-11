from models.context import PromptsContext
from models.lesson import Lesson
from models.prompts import PromptRequest, PromptType, PromptResponse, PromptRouterType, PromptActionType
from utils.context_utils import get_or_create_context, save_context
from utils.lesson_utils import create_lesson, get_module_lessons
from utils.prompt_utils import save_prompt_response


async def create_next_lesson(course_id: int, module_id: int) -> Lesson:
    """Adds "Lesson N" after the module's lessons and makes it the current context."""
    count = len(await get_module_lessons(module_id))
    lesson = await create_lesson(Lesson(
        course_id=course_id, module_id=module_id, title=f"Lesson {count + 1}", weight=count,
    ))
    await save_context(PromptsContext(course_id=course_id, module_id=module_id, lesson_id=lesson.lesson_id))
    return lesson


async def handle_prompt_lesson_request(prompt_request: PromptRequest) -> PromptResponse:
    context = await get_or_create_context(prompt_request.course_id)
    lesson = await create_next_lesson(context.course_id, context.module_id)
    response = PromptResponse(
        request_user_message=prompt_request.user_message,
        course_id=lesson.course_id, module_id=lesson.module_id, lesson_id=lesson.lesson_id,
        ui_chat_response={"message": f"Created {lesson.title}; new exercises go there."},
        prompt_router_type=PromptRouterType.LESSON,
        prompt_type=PromptType.LESSON_CREATE,
        prompt_action_type=PromptActionType.SIMPLE,
    )
    await save_prompt_response(response)
    return response
