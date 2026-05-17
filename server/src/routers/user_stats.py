from fastapi import APIRouter, Depends
from models.user_data import UserStats
from utils.db import get_query_results
router = APIRouter()


async def  get_sentences(user_id: int, lang):
    sql = """
    select count(*) as sentences_count from (
    select sentence_id, sum(mark) as sum_mark from user_data.results 
    where user_id = %s and lang = %s
    group by 1
    having sum(mark) >= 1
    ) 
    """
    params = (str(user_id), lang)
    res = await get_query_results(sql, params)
    return res[0]['sentences_count'] if res else 0
    
async def  get_words(user_id: int, lang):
    sql = """
    select count(*) as words_count from (
    select word1, sum(mark) as sum_mark from user_data.results 
    where user_id = %s and lang = %s
    group by 1
    having sum(mark) >= 1
    ) 
    """
    params = (str(user_id), lang)
    res = await get_query_results(sql, params)
    return res[0]['words_count'] if res else 0


async def  get_lessons(user_id: int, lang):
    sql = """
    select count(*) as lessons_count from (
    select lesson_id, sum(mark) as sum_mark from user_data.results 
    where user_id = %s and lang = %s
    group by 1
    having sum(mark) >= 1
    ) 
    """
    params = (str(user_id), lang)
    res = await get_query_results(sql, params)
    return res[0]['lessons_count'] if res else 0


async def  get_exercises(user_id: int, lang):
    sql = """
    select count(*) as exercises_count from (
    select exercise_id, sum(mark) as sum_mark from user_data.results
    where user_id = %s and lang = %s
    group by 1
    having sum(mark) >= 1
    )
    """
    params = (str(user_id), lang)
    res = await get_query_results(sql, params)
    return res[0]['exercises_count'] if res else 0


@router.get("/", response_model=UserStats)
async def get_user_stats(user_id: int, lang: str):
    sentences_count = await get_sentences(user_id, lang)
    words_count = await get_words(user_id, lang)
    lessons_count = await get_lessons(user_id, lang)
    exercises_count = await get_exercises(user_id, lang)
    return UserStats(
        user_id=user_id,
        lang=lang,
        lessons=lessons_count,
        words=words_count,
        sentences=sentences_count,
        exercises=exercises_count
    )
   
