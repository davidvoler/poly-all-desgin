from fastapi import APIRouter, Depends
from models.course import Exercise
from utils.db import get_query_results
router = APIRouter()


@router.get("/", response_model=list[Exercise])
async def get_exercises(lesson_id: int):
    sql = """
    SELECT *  
    FROM course_simple.exercise
    WHERE lesson_id = %s
    """
    params = (lesson_id,)
    res = await get_query_results(sql, params)
    results = []
    for r in res:
        exercise = Exercise(**r)
        results.append(exercise)
    return results