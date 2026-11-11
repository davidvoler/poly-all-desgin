from fastapi import HTTPException, Depends, APIRouter
from models.lesson import Lesson
from utils.permission import SchoolUser, get_school_user, require_access
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
async def list_lessons(module_id: int, user: SchoolUser = Depends(get_school_user)):
    await require_access(user, module_id=module_id)
    return await get_module_lessons(module_id)

@router.get("/lesson")
async def get_lesson_endpoint(lesson_id: int, user: SchoolUser = Depends(get_school_user)):
    await require_access(user, lesson_id=lesson_id)
    return await get_lesson(lesson_id)

@router.post("/lesson")
async def create_lesson_endpoint(lesson: Lesson, user: SchoolUser = Depends(get_school_user)):
    await require_access(user, course_id=lesson.course_id, module_id=lesson.module_id)
    return await create_lesson(lesson)

@router.put("/lesson")
async def update_lesson_endpoint(lesson: Lesson, user: SchoolUser = Depends(get_school_user)) -> Lesson:
    """Updates a lesson"""
    await require_access(user, lesson_id=lesson.lesson_id, course_id=lesson.course_id,
                         module_id=lesson.module_id)
    return await update_lesson(lesson)

@router.delete("/lesson")
async def delete_lesson_endpoint(lesson: Lesson, user: SchoolUser = Depends(get_school_user)):
    """Deletes a lesson"""
    await require_access(user, lesson_id=lesson.lesson_id, course_id=lesson.course_id,
                         module_id=lesson.module_id)
    return await delete_lesson(lesson)

@router.get("/lesson/full")
async def get_full_lesson_endpoint(lesson_id: int, user: SchoolUser = Depends(get_school_user)):
    await require_access(user, lesson_id=lesson_id)
    return await get_lesson_full(lesson_id)
