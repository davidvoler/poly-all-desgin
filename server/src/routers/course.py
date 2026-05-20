from fastapi import APIRouter, Depends
from models.course import Course
from utils.db import get_query_results
router = APIRouter()

async def get_user_courses(user_id: int):
    sql = """

    select course_id, module_id, lesson_id, count(*) as count from user_data.results 
    where user_id = %s
    group by 1, 2, 3
    """
    params = (user_id,)
    res = await get_query_results(sql, params)
    course_ids =  [r.get('course_id') for r in res] if res else []
    return course_ids


@router.get("/", response_model=list[Course])
async def get_courses(lang: str , to_lang: str, school: str| None = None):
    school_where = "school = %s" if school else ""
    sql = f"""
    SELECT *  
    FROM course_simple.course
    WHERE lang = %s AND to_lang = %s {school_where}
    """
    params = (lang, to_lang)
    if school:
        params = (lang, to_lang, school)
    res = await get_query_results(sql, params)
    results = []
    for r in res:
        course = Course(**r)
        results.append(course)
    return results