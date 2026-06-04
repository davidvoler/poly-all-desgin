from fastapi import APIRouter, Depends
from models.course import Exercise
from utils.db import get_query_results
import random

router = APIRouter()


@router.get("/", response_model=list[Exercise])
async def get_exercises(lesson_id: int) -> list[Exercise]:
    sql = """
    SELECT *  
    FROM course_simple.exercise
    WHERE lesson_id = %s
    """
    print(f"Getting exercises for lesson_id: {lesson_id}")
    params = (lesson_id,)
    res = await get_query_results(sql, params)
    results = []
    for r in res:
        exercise = Exercise(**r)
        results.append(exercise)
    # random.shuffle(results)
    return results[:10]