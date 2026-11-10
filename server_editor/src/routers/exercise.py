from fastapi import HTTPException, Depends, APIRouter
from models.exercise import Exercise
from utils.permission import SchoolUser, get_school_user, require_access
from utils.exercise_utils import (
    create_exercise,
    get_exercise,
    update_exercise,
    delete_exercise,
    get_lesson_exercises
)

router = APIRouter()

def _ids(exercise: Exercise) -> dict:
    return {"exercise_id": exercise.exercise_id, "course_id": exercise.course_id,
            "module_id": exercise.module_id, "lesson_id": exercise.lesson_id}

@router.get("/exercises")
async def list_exercises(lesson_id: int, user: SchoolUser = Depends(get_school_user)):
    await require_access(user, lesson_id=lesson_id)
    return await get_lesson_exercises(lesson_id)

@router.get("/exercise")
async def get_exercise_endpoint(exercise_id: int, user: SchoolUser = Depends(get_school_user)):
    await require_access(user, exercise_id=exercise_id)
    return await get_exercise(exercise_id)

@router.post("/exercise")
async def create_exercise_endpoint(exercise: Exercise, user: SchoolUser = Depends(get_school_user)):
    await require_access(user, **{**_ids(exercise), "exercise_id": None})
    return await create_exercise(exercise)

@router.put("/exercise")
async def update_exercise_endpoint(exercise: Exercise, user: SchoolUser = Depends(get_school_user)) -> Exercise:
    """Updates an exercise"""
    await require_access(user, **_ids(exercise))
    return await update_exercise(exercise)

@router.delete("/exercise")
async def delete_exercise_endpoint(exercise_id: int, user: SchoolUser = Depends(get_school_user)):
    """Deletes an exercise and updates which words are used"""
    await require_access(user, exercise_id=exercise_id)
    await delete_exercise(exercise_id)
    return {"status": "success"}
