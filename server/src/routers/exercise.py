from fastapi import APIRouter, Depends, Query
from models.course import Exercise
from utils.db import get_query_results
import random

router = APIRouter()


@router.get("/", response_model=list[Exercise])
async def get_exercises(lesson_id: int, limit: int = Query(10, ge=1, le=500)) -> list[Exercise]:
    """The lesson's exercises in the editor's order. Video lessons ask for all of
    them, since they quiz the words and the sentences separately."""
    sql = """
    SELECT *
    FROM course_simple.exercise
    WHERE lesson_id = %s
    ORDER BY weight NULLS LAST, exercise_id
    LIMIT %s
    """
    res = await get_query_results(sql, (lesson_id, limit))
    return [Exercise(**r) for r in res]
