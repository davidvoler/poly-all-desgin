from fastapi import APIRouter, Depends
from models.course import Course
from utils.db import get_query_results
router = APIRouter()


async def user_course_status(user_id: int, course_id: int, course_lessons_count: int):
    sql = """
    select lesson_id, max(score) as max_score, sum(score) as total_score,count(*) as num_attempts from user_data.lesson_completed
    where user_id = %s and course_id = %s
    group by 1
    """
    params = (user_id, course_id)
    res = await get_query_results(sql, params)
    lesson_status = {r.get('lesson_id'): r.get('max_score') for r in res} if res else {}
    return lesson_status




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
async def get_courses(lang: str , to_lang: str, school: str| None = None, user_id: int = 1):
    school_where = "school = %s" if school else ""
    sql = f"""
    SELECT c.course_id, c.title, c.description, c.lang, c.to_lang, c.lesson_count,
    ul.user_lessons_done, ul.avg_score
    FROM course_simple.course c 
    left join (
    SELECT course_id, count(*) as user_lessons_done, avg(score) as avg_score
    FROM user_data.lesson_status
    where user_id = %s
    group by 1) AS ul on c.course_id = ul.course_id
    WHERE c.lang = %s AND c.to_lang = %s 
    {school_where}
    """
    params = (user_id, lang, to_lang)
    if school:
        params = (user_id, lang, to_lang, school)
    res = await get_query_results(sql, params)
    results = []
    for r in res:
        course = Course(**r)
        results.append(course)
    
    return results