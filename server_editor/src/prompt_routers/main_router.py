from models.prompts import (
    PromptRequest,
    PromptRouterType,
    PromptResponse
) 

from prompt_routers.course import handle_prompt_course_request
from prompt_routers.module import handle_prompt_module_request, suggest_options
from prompt_routers.lesson import handle_prompt_lesson_request
from prompt_routers.exercise import handle_prompt_exercise_request
from prompt_routers.vocabulary import handle_prompt_vocabulary_request
from prompt_routers.video import handle_prompt_video_request
from utils.video_utils import find_video_url
from utils.words_utils import course_words


def _unused_words_count( words: list) -> int:
    # Implement the logic to count unused words for the prompt request
    return len([w for w in words if not w.used])

async def _identify_prompt_router_type(prompt_request: PromptRequest) -> PromptRouterType:
    if find_video_url(prompt_request.user_message):
        # A pasted video link starts a video module.
        return PromptRouterType.VIDEO
    if prompt_request.last_router_type and prompt_request.last_router_type != PromptRouterType.UNKNOWN:
        return prompt_request.last_router_type
    if prompt_request.course_id is None or prompt_request.course_id<=0:
        # We do not have a course yet
        return PromptRouterType.COURSE
    if prompt_request.module_id is None or prompt_request.module_id<=0:
        # We do not have a module yet
        return PromptRouterType.MODULE
    if not prompt_request.words or len(prompt_request.words) == 0:
        words = await course_words(prompt_request.course_id, prompt_request.module_id)
        prompt_request.words = words
    if _unused_words_count(prompt_request.words) <= 2:
        return PromptRouterType.VOCABULARY
    if len(prompt_request.words) >= 1:
        return PromptRouterType.EXERCISE
    return PromptRouterType.UNKNOWN

async def _process_prompt_request(prompt_request: PromptRequest, prompt_router_type: PromptRouterType) -> PromptResponse:
    # Implement the logic to process the prompt request based on the identified prompt type
    match(prompt_router_type):
        case PromptRouterType.COURSE:
            # Handle create course logic
            return await handle_prompt_course_request(prompt_request)
        case PromptRouterType.MODULE:
            # Handle create module logic
            return await handle_prompt_module_request(prompt_request)
        case PromptRouterType.LESSON:
            # Handle create lesson logic
            return await handle_prompt_lesson_request(prompt_request)
        case PromptRouterType.VOCABULARY:
            # Handle vocabulary logic
            return await handle_prompt_vocabulary_request(prompt_request)
        case PromptRouterType.EXERCISE:
            # Handle exercise logic
            return await handle_prompt_exercise_request(prompt_request)
        case PromptRouterType.VIDEO:
            return await handle_prompt_video_request(prompt_request)
        case _:
            return None


async def _offer_options(prompt_request: PromptRequest) -> PromptResponse:
    """When no router handles the request, offer the next steps for the current context."""
    return await suggest_options(prompt_request)

async def handle_prompt_request(prompt_request: PromptRequest) -> PromptResponse:
    if not prompt_request.router_type or prompt_request.router_type == PromptRouterType.UNKNOWN:
        prompt_router_type = await _identify_prompt_router_type(prompt_request)
    else:
        prompt_router_type = prompt_request.router_type
    if prompt_router_type:
        response = await _process_prompt_request(prompt_request, prompt_router_type)
        if response:
            return response
    return await _offer_options(prompt_request)






