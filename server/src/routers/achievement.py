from fastapi import APIRouter
from models.achievement import Achievement, AchievementType
from server.src.models import achievement
from utils.db import get_query_results, run_query
from datetime import datetime, timedelta
router = APIRouter()


WORDS_LEARNED_ACHIEVEMENT = 10
LESSONS_COMPLETED_ACHIEVEMENT = 10


async def check_new_achievement(user_id:int, lang:str,  course_id:int=None, since_date:datetime=None):
    """check for new achievement for user, course and language since given date. If course_id is None, check for all courses. If since_date is None, check for all time.
    """
    check_new_achievement = []
    # count lessons 
    sql = f"""SELECT COUNT(*) as count_lessons 
            FROM user_data.lesson_status 
            WHERE user_id = {user_id} AND lang = '{lang}'"""
    if since_date:
        sql += f" AND date_completed > '{since_date.isoformat()}'"
    results = await get_query_results(sql)
    for r in results:
        count_lessons = r.get('count_lessons', 0)
        if count_lessons >= LESSONS_COMPLETED_ACHIEVEMENT:
            check_new_achievement.append(Achievement(
                achievement_id=0,
                user_id=user_id,
                course_id=course_id or 0,
                lang=lang,
                achievement_type=AchievementType.LESSONS_COMPLETED,
                count_elements=count_lessons,
                created_at=datetime.now(),
                is_new=True
            ))
    # count words 
    date_where = ''
    if since_date:
        date_where = f" AND created_at > '{since_date.isoformat()}'"    
    sql = f"""
        select count(*) FROM (
        SELECT word1 as word , sum(score) as sum_score 
        FROM user_data.results 
        WHERE user_id = {user_id} AND lang = '{lang}' 
        {date_where}
        GROUP BY word1
        HAVING sum_score > 0.5)
        """

    results = await get_query_results(sql)
    for r in results:
        count_words = r.get('count', 0)
        if count_words >= WORDS_LEARNED_ACHIEVEMENT:
            check_new_achievement.append(Achievement(
                achievement_id=0,
                user_id=user_id,
                course_id=course_id or 0,
                lang=lang,
                achievement_type=AchievementType.WORDS_LEARNED,
                count_elements=count_words,
                description=f"Learned {count_words} words",
                created_at=datetime.now(),
                is_new=True
            ))

    # update new achievements in database
    for a in check_new_achievement:
        await run_query(f"""INSERT INTO achievements (user_id, course_id, lang, achievement_type, count_elements, created_at) 
                            VALUES (%s, %s, %s, %s, %s, %s)""",
                            (a.user_id, a.course_id, a.lang, a.achievement_type.value, a.count_elements, a.created_at))       
    return check_new_achievement





async def user_achievements(user_id, course_id: int, lang: str):
    # get user last achievement
    query = f"""SELECT achievement_id, user_id, course_id, lang, achievement_type, count_elements, created_at
                FROM achievements
                WHERE user_id = {user_id} AND course_id = {course_id} AND lang = '{lang}'
                ORDER BY created_at DESC
                LIMIT 5"""
    results = await get_query_results(query)
    achievements = [achievement.Achievement(**a) for a in results]
    since_date = None
    if len(achievements) > 0:
        since_date = achievements[0].created_at
    new_achievements  = await check_new_achievement(user_id, lang, course_id, since_date)  
    return new_achievements + achievements
 



@router.get("/completed", response_model=list[Achievement])
async def get_achievement(user_id, course_id: int, lang: str):
    return await user_achievements(user_id, course_id, lang)