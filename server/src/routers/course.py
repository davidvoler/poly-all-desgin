from fastapi import APIRouter, Depends
from models.course import Course
from utils.db import get_query_results
router = APIRouter()


@router.get("/", response_model=list[Course])
async def get_courses(lang: str , to_lang: str ):
    sql = """
    SELECT *  
    FROM course_simple.course
    WHERE lang = %s AND to_lang = %s
    """
    params = (lang, to_lang)
    res = await get_query_results(sql, params)
    results = []
    for r in res:
        course = Course(**r)
        results.append(course)
    return results