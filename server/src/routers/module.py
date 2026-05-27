from fastapi import APIRouter, Depends
from models.course import Module
from utils.auth_deps import current_user_id
from utils.db import get_query_results
router = APIRouter()


@router.get("/", response_model=list[Module])
async def get_modules(course_id: int, user_id: int = Depends(current_user_id)):
    sql = """
    SELECT module.*,ls.max_score, ls.sum_score, ls.num_attempts
    FROM course_simple.module AS module
    LEFT JOIN (
        SELECT module_id,
               max(score) AS max_score,
               sum(score) AS sum_score,
               count(*) AS num_attempts
        FROM user_data.lesson_status
        WHERE user_id = %s
        GROUP BY module_id
    ) AS ls ON module.module_id = ls.module_id
    WHERE module.course_id = %s
    order by weight

    """
    params = (user_id, course_id)
    res = await get_query_results(sql, params)
    results = []
    for r in res:
        module = Module(**r)
        results.append(module)
    return results