from fastapi import APIRouter, Depends
from server.src.routers.exercise import get_exercises
from utils.db import get_query_results
from models.course import Exercise
import random

router = APIRouter()


async def  get_sentences_for_practice(user_id: int, lang: str):
    sql = """
    select sentence_id, sum(mark) as sum_mark from user_data.results 
    where user_id = %s and lang = %s
    group by 1
    having sum(mark) <= 3
    """
    params = (str(user_id), lang)
    res = await get_query_results(sql, params)
    sentences =  [r.get('sentence_id') for r in res] if res else []
    random.shuffle(sentences)
    return sentences[:10]
    
async def  get_words_for_practice(user_id: int, lang: str):
    sql = """
    select word1, sum(mark), max(create_at) from user_data.results 
    where user_id = %s and lang = %s
    group by 1
    having sum(mark) <= 3 
    """
    params = (str(user_id), lang)
    res = await get_query_results(sql, params)
    words =  [r.get('word1') for r in res] if res else []
    random.shuffle(words)
    return words[:10]


async def get_exercises_by_words(lang:str,words: list[str]):
    placehoslder = ', '.join(['%s'] * len(words))
    sql = f"""
    SELECT *  
    FROM course_simple.exercise
    WHERE lang = %s and ( 
    word1 IN ({placehoslder}) or word2 IN ({placehoslder}) 
    """
    params = (lang, *words, *words)
    res = await get_query_results(sql, params)
    results = []
    for r in res:
        exercise = Exercise(**r)
        results.append(exercise)
    random.shuffle(results)
    return results[:10]



async def get_exercises_by_sentences(lang:str,sentences: list[int]):
    placehoslder = ', '.join(['%s'] * len(sentences))
    sql = f"""
    SELECT *  
    FROM course_simple.exercise
    WHERE lang = %s 
    and sentence_id IN ({placehoslder})
    """
    params = (lang, *sentences)
    res = await get_query_results(sql, params)
    results = []
    for r in res:
        exercise = Exercise(**r)
        results.append(exercise)
    random.shuffle(results)
    return results[:10]

@router.get("/by_words", response_model=list[Exercise])
async def exercise_by_words(user_id: int, lang: str):
    words = await get_words_for_practice(user_id, lang)
    exercises = await get_exercises(lang, words)
    return exercises
    

@router.get("/by_sentences", response_model=list[Exercise])
async def exercise_by_sentences(user_id: int, lang: str):
    sentences = await get_sentences_for_practice(user_id, lang)
    exercises = await get_exercises_by_sentences(lang, sentences)
    return exercises



