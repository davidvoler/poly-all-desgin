from operator import ge

from fastapi import HTTPException, Depends, APIRouter
from models.lesson import Lesson
from utils.lesson_utils import (
    create_lesson, 
    get_lesson, 
    get_module_lessons, 
    update_lesson, 
    delete_lesson,
    get_lesson_full
)

router = APIRouter()    

@router.get("/lessons")
async def list_lessons(module_id: int):
    return await get_module_lessons(module_id)
    
@router.get("/lesson")
async def get_lesson_endpoint(lesson_id: int):
    return await get_lesson(lesson_id)

@router.post("/lesson")
async def create_lesson_endpoint(lesson: Lesson):
    return await create_lesson(lesson)

@router.put("/lesson")
async def update_lesson_endpoint(lesson: Lesson) -> Lesson:
    """Updates a lesson"""
    return await update_lesson(lesson)

@router.delete("/lesson")
async def delete_lesson_endpoint(lesson: Lesson):
    """Deletes a lesson"""
    return await delete_lesson(lesson)

@router.get("/lesson/full")
async def get_full_lesson_endpoint(lesson_id: int):
    return await get_lesson_full(lesson_id)