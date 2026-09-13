from fastapi import HTTPException, Depends, APIRouter
from models.course import Course
router = APIRouter()


@router.get("/courses")
async def list_courses(lang: str, to_lang: str):
    return {"message": "List of courses"}

@router.get("/course")
async def get_course(course_id: int):
    return {"message": "Course details"}

@router.post("/course")
async def create_course(course: Course):
    return {"message": "Course created"}

@router.put("/course")
async def update_course( course: Course) -> Course :
    """Updates a course"""
    return course

@router.delete("/course")
async def delete_course(course: Course):
    """Deletes a course"""
    return {"message": "Course deleted"}