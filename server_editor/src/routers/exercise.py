from fastapi import HTTPException, Depends, APIRouter
from models.exercise import Exercise
router = APIRouter()

@router.get("/exercises")
async def list_exercises():
    return {"message": "List of exercises"}

@router.get("/exercise")
async def get_exercise(exercise_id: int):
    return {"message": "Exercise details"}

@router.post("/exercise")
async def create_exercise(exercise: Exercise):
    return {"message": "Exercise created"}

@router.put("/exercise")
async def update_exercise(exercise: Exercise) -> Exercise:
    """Updates an exercise"""
    return exercise

@router.delete("/exercise")
async def delete_exercise(exercise: Exercise):
    """Deletes an exercise"""
    return {"message": "Exercise deleted"}  