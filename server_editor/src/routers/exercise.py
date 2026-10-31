from fastapi import HTTPException, Depends, APIRouter
from models.exercise import Exercise
from utils.exercise_utils import (
    create_exercise,
    get_exercise,
    update_exercise,
    delete_exercise,
    get_lesson_exercises
)

router = APIRouter()

@router.get("/exercises")
async def list_exercises(lesson_id: int):
    return await get_lesson_exercises(lesson_id)

@router.get("/exercise")
async def get_exercise_endpoint(exercise_id: int):
    return await get_exercise(exercise_id)

@router.post("/exercise")
async def create_exercise_endpoint(exercise: Exercise):
    return await create_exercise(exercise)

@router.put("/exercise")
async def update_exercise_endpoint(exercise: Exercise) -> Exercise:
    """Updates an exercise"""
    return await update_exercise(exercise)

@router.delete("/exercise")
async def delete_exercise_endpoint(exercise_id: int):
    """Deletes an exercise and updates which words are used"""
    await delete_exercise(exercise_id)
    return {"status": "success"}