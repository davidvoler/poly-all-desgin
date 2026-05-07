from fastapi import APIRouter, Depends
from models.lesson import Lesson, UserLessonProgress

router = APIRouter()


@router.get("/", response_model=Lesson)
async def get_lesson(lesson_id: int):
    # Placeholder for fetching courses from the database
    return Lesson(
        id=1,
        name="Introduction to Python",
        description="Learn the basics of Python programming.",
        language="English",
        user_language="English",                
        module_count=3,
        lesson_count=10,
        tags=["programming", "python", "beginner"],
        user_lesson_progress=UserLessonProgress(
            user_id=1,
            lesson_id=1,
            progress=0.5,
            current_module=2,
            current_lesson=5
        )
    )
