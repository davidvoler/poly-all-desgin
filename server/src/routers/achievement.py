from xmlrpc.client import DateTime

from fastapi import APIRouter, Depends
from models.achievement import Achievement
from server.src.models import achievement
from utils.db import get_query_results, run_query
from datetime import datetime, timedelta
router = APIRouter()


WORDS_LEARNED_ACHIEVEMENT = 10
LESSONS_COMPLETED_ACHIEVEMENT = 10


async def check_new_achievement(user_id:int, lang:str,  course_id:int=None, since_date:datetime=None):
    """check for new achievement for user, course and language since given date. If course_id is None, check for all courses. If since_date is None, check for all time.
    """
    # count lessons 
    sql = f"""SELECT COUNT(*) as count FROM lessons_completed WHERE user_id = {user_id} AND lang = '{lang}'"""
    
    # count words 
    sql = f"""SELECT COUNT(*) as count FROM words_learned WHERE user_id = {user_id} AND lang = '{lang}'"""







async def user_achievements(user_id, course_id: int, lang: str):
    # get user last achievement
    query = f"""SELECT achievement_id, user_id, course_id, lang, title, description, date_earned
                FROM achievements
                WHERE user_id = {user_id} AND course_id = {course_id} AND lang = '{lang}'
                ORDER BY date_earned DESC
                LIMIT 5"""
    results = await get_query_results(query)
    achievements = [achievement.Achievement(**a) for a in results]
    since_date = None
    if len(achievements) > 0:
        since_date = achievements[0].date_earned
    new_achievements  = await check_new_achievement(user_id, lang, course_id, since_date)  
    return new_achievements + achievements
 



@router.get("/completed", response_model=list[Achievement])
async def get_achievement(user_id, course_id: int, lang: str):
    return await user_achievements(user_id, course_id, lang)