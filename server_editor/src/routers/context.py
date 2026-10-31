from fastapi import APIRouter, Depends, HTTPException
from models.context import PromptsContext
from utils.context_utils import get_or_create_context, save_context

router = APIRouter()

@router.post("/get_or_create", response_model=PromptsContext)
async def _get_or_create_context(context:PromptsContext)->PromptsContext:
   return await get_or_create_context(course_id=context.course_id, module_id=context.module_id, lesson_id=context.lesson_id)

@router.post("/save", response_model=PromptsContext)
async def _save_context(context:PromptsContext)->PromptsContext:
   return await save_context(context)