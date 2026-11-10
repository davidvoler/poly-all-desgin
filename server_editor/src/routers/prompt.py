from fastapi import APIRouter, Depends, HTTPException
from models.prompts import PromptOption, PromptRequest, PromptResponse, PromptOption
from models.context import PromptsContext
from models.tasks import TasksResultsRequest
from tasks.prompt_tasks import handle_prompt_task
from utils.prompt_utils import get_last_responses
from utils.context_options import context_options
from utils.context_utils import get_or_create_context
from utils.permission import SchoolUser, get_school_user, require_access
from utils.ai_models import AiProvider, ai_providers

router = APIRouter()

@router.post("/prompt", response_model=TasksResultsRequest)
async def _handle_prompt(request: PromptRequest, school_user: SchoolUser = Depends(get_school_user))->TasksResultsRequest:
   await require_access(school_user, course_id=request.course_id, module_id=request.module_id,
                        lesson_id=request.lesson_id)
   print(f"Handling prompt request: {request}")
   return await handle_prompt_task(request, school_user)


@router.get("/history", response_model=list[PromptResponse])
async def _handle_prompt_history(course_id:int, module_id:int = 0, limit:int = 20,
                                 user: SchoolUser = Depends(get_school_user))->list[PromptResponse]:
    await require_access(user, course_id=course_id, module_id=module_id)
    return await get_last_responses(course_id, module_id, limit)


@router.get("/default_options", response_model=list[PromptOption])
async def _default_options(course_id:int, user: SchoolUser = Depends(get_school_user))->list[PromptOption]:
    """The next steps for the course's current module and lesson."""
    await require_access(user, course_id=course_id)
    return await context_options(course_id)


@router.get("/ai_models", response_model=list[AiProvider])
async def _ai_models(school_user=Depends(get_school_user))->list[AiProvider]:
    """The AI providers and models the chat can use, and which have a key."""
    return await ai_providers(school_user.school, school_user.user_id)


@router.post("/context", response_model=PromptsContext)
async def _get_or_create_context(context:PromptsContext, user: SchoolUser = Depends(get_school_user))->PromptsContext:
   await require_access(user, course_id=context.course_id, module_id=context.module_id, lesson_id=context.lesson_id)
   return await get_or_create_context(course_id=context.course_id, module_id=context.module_id, lesson_id=context.lesson_id)