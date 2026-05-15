from fastapi import APIRouter, Depends
from models.course import Lesson
from utils.db import get_query_results
router = APIRouter()


@router.get("/", response_model=list[Lesson])
async def get_lessons(module_id: int):
    sql = """
    SELECT *  
    FROM course_simple.lesson
    WHERE module_id = %s
    """
    params = (module_id,)
    res = await get_query_results(sql, params)
    results = []
    for r in res:
        lesson = Lesson(**r)
        results.append(lesson)
    return results