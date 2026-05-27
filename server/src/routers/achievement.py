from fastapi import APIRouter, Depends
from models.achievement import Achievement, AchievementType
from models import achievement
from utils.auth_deps import current_user_id
from utils.db import get_query_results, run_query
from datetime import datetime, timedelta
router = APIRouter()


WORDS_LEARNED_ACHIEVEMENT = 10
LESSONS_COMPLETED_ACHIEVEMENT = 10


async def check_new_achievement(user_id:int, lang:str,  course_id:int=None):
    """check for new achievement for user, course and language since given date. If course_id is None, check for all courses. If since_date is None, check for all time.
    """
    words_since_date = None
    lessons_since_date = None
    sql = f"""SELECT achievement_type, max(created_at) FROM achievements 
            WHERE user_id = %s AND lang = %s
            group by achievement_type
            limit 2"""
    results = await get_query_results(sql, (user_id, lang))
    for r in results:
        if r.get('achievement_type') == AchievementType.WORDS_LEARNED.value:
            words_since_date = r.get('max')
        elif r.get('achievement_type') == AchievementType.LESSONS_COMPLETED.value:
            lessons_since_date = r.get('max')

    new_achievement = []
    # count lessons 
    sql = f"""SELECT COUNT(*) as count_lessons 
            FROM user_data.lesson_status 
            WHERE user_id = %s AND lang = %s"""
    if lessons_since_date:
        sql += f" AND date_completed > '{lessons_since_date.isoformat()}'"
    results = await get_query_results(sql, (user_id, lang))
    for r in results:
        count_lessons = r.get('count_lessons', 0)
        if count_lessons >= LESSONS_COMPLETED_ACHIEVEMENT:
            new_achievement.append(Achievement(
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
    if words_since_date:
        date_where = f" AND created_at > '{words_since_date.isoformat()}'"    
    sql = f"""
        select count(*) FROM (
        SELECT word1 as word , sum(score) as sum_score 
        FROM user_data.results 
        WHERE user_id = %s AND lang = %s
        {date_where}
        GROUP BY word1
        HAVING sum(score) > 0.5)
        """
    results = await get_query_results(sql, (user_id, lang))
    for r in results:
        count_words = r.get('count', 0)
        if count_words >= WORDS_LEARNED_ACHIEVEMENT:
            new_achievement.append(Achievement(
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
    for a in new_achievement:
        await run_query(f"""INSERT INTO user_data.achievements (user_id, course_id, lang, achievement_type, count_elements, created_at) 
                            VALUES (%s, %s, %s, %s, %s, %s)""",
                            (a.user_id, a.course_id, a.lang, a.achievement_type.value, a.count_elements, a.created_at))       
    return new_achievement





async def user_achievements(user_id, lang: str, course_id: int):
    # get user last achievement
    query = f"""SELECT achievement_id, user_id, course_id, lang, achievement_type, count_elements, created_at
                FROM user_data.achievements
                WHERE user_id = %s AND course_id = %s AND lang = %s
                ORDER BY created_at DESC
                LIMIT 5"""
    results = await get_query_results(query, (user_id, course_id, lang))
    achievements = [achievement.Achievement(**a) for a in results]
    return achievements
 



@router.get("/get_achievements", response_model=list[Achievement])
async def get_achievements(course_id: int, lang: str,
                           user_id: int = Depends(current_user_id)):
    return await user_achievements(user_id, lang, course_id)


@router.post("/check_new_achievements", response_model=list[Achievement])
async def new_achievements(course_id: int, lang: str,
                           user_id: int = Depends(current_user_id)):
    return await check_new_achievement(user_id, lang, course_id)