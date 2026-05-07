from fastapi import APIRouter, Depends
from models.course import Course

router = APIRouter()


@router.get("/courses", response_model=list[Course])
async def get_courses(language: str | None = None, user_language: str | None = None):
    # Placeholder for fetching courses from the database
    return [
        Course(
            id=1,
            name="Python for Beginners",
            description="Learn Python from scratch.",
            language="English",
            user_language="English",
            module_count=5,
            lesson_count=20,
            tags=["programming", "python", "beginner"]
        ),
        Course(
            id=2,
            name="Advanced JavaScript",
            description="Master JavaScript and its frameworks.",
            language="English",
            user_language="English",
            module_count=8,
            lesson_count=30,
            tags=["programming", "javascript", "advanced"]
        )
    ]