from fastapi import HTTPException, Depends, APIRouter
from models.lesson import Lesson
router = APIRouter()    

@router.get("/lessons")
async def list_lessons(course_id: int):
    return {"message": f"List of lessons for course {course_id}"}

@router.get("/lesson")
async def get_lesson(lesson_id: int):
    return {"message": f"Details of lesson {lesson_id}"}

@router.post("/lesson")
async def create_lesson(lesson: Lesson):
    return {"message": "Lesson created"}

@router.put("/lesson")
async def update_lesson(lesson: Lesson) -> Lesson:
    """Updates a lesson"""
    return lesson

@router.delete("/lesson")
async def delete_lesson(lesson: Lesson):
    """Deletes a lesson"""
    return {"message": "Lesson deleted"}
