from fastapi import HTTPException, Depends, APIRouter
from models.course import Course
from utils.db import get_query_results
from utils.permission import get_school_user
from utils.course_utils import (
    create_course, get_course, get_courses, 
    update_course, delete_course
)

router = APIRouter()


@router.get("/courses",response_model=list[Course])
async def list_courses(lang: str | None = None, to_lang: str | None = None, school_user=Depends(get_school_user)):
    return await get_courses()

@router.get("/course",response_model=Course)
async def _get_course(course_id: int, school_user=Depends(get_school_user)):
    return await get_course(course_id)

@router.post("/course")
async def _create_course(course: Course, school_user=Depends(get_school_user)):
    course.user_id = school_user.user_id
    course.school = school_user.school
    return await create_course(course)

@router.put("/course")
async def _update_course(course: Course, school_user=Depends(get_school_user)) -> Course:
    return await update_course(course)

@router.delete("/course")
async def _delete_course(course_id: int, school_user=Depends(get_school_user)) -> dict:
    """Deletes a course"""
    await delete_course(course_id)
    return {"status": "success"}