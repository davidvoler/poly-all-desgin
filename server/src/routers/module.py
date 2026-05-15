from fastapi import APIRouter, Depends
from models.course import Module
from utils.db import get_query_results
router = APIRouter()


@router.get("/", response_model=list[Module])
async def get_modules(course_id: int):
    sql = """
    SELECT *  
    FROM course_simple.module
    WHERE course_id = %s
    order by module_id
    """
    params = (course_id,)
    res = await get_query_results(sql, params)
    results = []
    for r in res:
        module = Module(**r)
        results.append(module)
    return results