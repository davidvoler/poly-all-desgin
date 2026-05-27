from fastapi import APIRouter, Depends
from models.course import Course
from utils.auth_deps import current_user_id
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
async def get_courses(lang: str, to_lang: str, school: str | None = None,
                      user_id: int = Depends(current_user_id)):
    school_where = "AND school = %s" if school else ""
    # `ul` rolls up the user's per-course lesson counts (drives both
    # the lessons-done badge and the computed progress fraction).
    # `u_last` picks the user's most-recent lesson_status row so the
    # client can mark exactly one course as "current" (the one the
    # JOIN matches) along with its module/lesson cursor. The user_id
    # filter on u_last is load-bearing — without it the subquery
    # leaks the globally-most-recent row from any user.
    sql = f"""
    SELECT c.course_id, c.title, c.description, c.lang, c.to_lang, c.lesson_count,
    COALESCE(ul.user_lessons_done, 0) AS user_lessons_done,
    COALESCE(ul.avg_score, 0.0) AS avg_score,
    CASE WHEN c.lesson_count > 0
         THEN (COALESCE(ul.user_lessons_done, 0) * 100 / c.lesson_count)
         ELSE 0 END AS progress,
    u_last.module_id AS current_module,
    u_last.lesson_id AS current_lesson
    FROM course_simple.course c
    LEFT JOIN (
        SELECT course_id, count(*) AS user_lessons_done, avg(score) AS avg_score
        FROM user_data.lesson_status
        WHERE user_id = %s
        GROUP BY 1
    ) AS ul ON c.course_id = ul.course_id
    LEFT JOIN (
        SELECT course_id, module_id, lesson_id
        FROM user_data.lesson_status
        WHERE user_id = %s
        ORDER BY created_at DESC
        LIMIT 1
    ) AS u_last ON c.course_id = u_last.course_id
    WHERE c.lang = %s AND c.to_lang = %s
    {school_where}
    """
    params = (user_id, user_id, lang, to_lang)
    if school:
        params = (user_id, user_id, lang, to_lang, school)
    res = await get_query_results(sql, params)
    results = []
    for r in res:
        course = Course(**r)
        results.append(course)
    print(results)
    return results