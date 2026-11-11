from models.context import PromptsContext
from prompt_routers.lesson import create_next_lesson
from utils.context_options import context_options
from utils.context_utils import get_or_create_context, save_context
from utils.module_utils import create_module, get_course_modules
from utils.words_utils import move_unused_words
from models.module import Module
from models.lesson import Lesson
from models.prompts import (
    PromptRequest,
    PromptResponse,
    PromptType,
    PromptRouterType,
    PromptActionType,
    PromptOption,
)   
from prompt_routers.vocabulary import handle_prompt_vocabulary_request
from utils.lesson_utils import create_lesson

from utils.prompt_utils import save_prompt_request, save_prompt_response
async def _identify_prompt_type(prompt_request: PromptRequest) -> PromptType:
    # Implement the logic to identify the prompt type based on the user message and context
    return prompt_request.prompt_type

async def _create_next_module(prompt_request: PromptRequest) -> PromptResponse:
    """Adds "Module N" with a first lesson, moves the current module's unused words
    into it and makes it the current context."""
    context = await get_or_create_context(prompt_request.course_id)
    count = len(await get_course_modules(context.course_id))
    module = await create_module(Module(
        course_id=context.course_id, title=f"Module {count + 1}", weight=count,
    ))
    moved = await move_unused_words(context.module_id, module.module_id)
    lesson = await create_next_lesson(context.course_id, module.module_id)
    response = PromptResponse(
        request_user_message=prompt_request.user_message,
        course_id=module.course_id, module_id=module.module_id, lesson_id=lesson.lesson_id,
        ui_chat_response={"message": f"Created {module.title} with {lesson.title} and moved {moved} unused words to it."},
        prompt_router_type=PromptRouterType.MODULE,
        prompt_type=PromptType.MODULE_CREATE,
        prompt_action_type=PromptActionType.SIMPLE,
    )
    await save_prompt_response(response)
    return response


async def suggest_options(prompt_request: PromptRequest) -> PromptResponse:
    return PromptResponse(
        request_user_message=prompt_request.user_message,
        course_id=prompt_request.course_id,
        module_id=prompt_request.module_id,
        lesson_id=prompt_request.lesson_id,
        option=await context_options(prompt_request.course_id),
        ui_chat_response={"message": "What would you like to do next?"},
        prompt_router_type=PromptRouterType.MODULE,
        prompt_action_type=PromptActionType.OPTIONS,
    )

async def _create_module(prompt_request: PromptRequest) -> Module:
    count = len(await get_course_modules(prompt_request.course_id))
    return await create_module(Module(
        course_id=prompt_request.course_id, title=f"Module {count + 1}", weight=count,
    ))



async def _process_prompt_request(prompt_request: PromptRequest, prompt_type: PromptType) -> PromptResponse:
    # Implement the logic to process the prompt request based on the identified prompt type
    match(prompt_type):
        case PromptType.MODULE_CREATE:
            return await _create_next_module(prompt_request)
        case PromptType.MODULE_CREATE_SUGGEST_WORDS:
            # Handle module create suggest words logic
            m = await _create_module(prompt_request)
            prompt_request.module_id = m.module_id
            prompt_request.router_type = PromptRouterType.VOCABULARY
            prompt_request.prompt_type = PromptType.VOCABULARY_SUGGEST_WORDS
            return await handle_prompt_vocabulary_request(prompt_request)
        case PromptType.MODULE_ATTRIBUTE:
            # Handle module attributes logic
            pass
        case _:
            # Handle unknown prompt type
            pass
    return await suggest_options(prompt_request)



async def handle_prompt_module_request(prompt_request: PromptRequest) -> PromptResponse:
    prompt_type = await _identify_prompt_type(prompt_request)
    # Implement the logic to handle the prompt request based on the identified prompt type
    if not prompt_type:
        return await suggest_options(prompt_request)
    else:
        return await _process_prompt_request(prompt_request, prompt_type)








