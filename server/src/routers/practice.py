from fastapi import APIRouter, Depends
from utils.db import get_query_results
from models.course import Exercise, Word

import random

router = APIRouter()


async def  get_sentences_for_practice(user_id: int, lang: str):
    sql = """
    select sentence_id, sum(score) as sum_score from user_data.results 
    where user_id = %s and lang = %s
    group by 1
    having sum(score) < 3
    """
    params = (str(user_id), lang)
    res = await get_query_results(sql, params)
    sentences =  [r.get('sentence_id') for r in res] if res else []
    random.shuffle(sentences)
    return sentences[:10]
    
async def  get_words_for_practice(user_id: int, lang: str):
    sql = """
    select word1, sum(score) from user_data.results 
    where user_id = %s and lang = %s
    group by 1
    having sum(score) < 3
    """
    
    params = (str(user_id), lang)
    res = await get_query_results(sql, params)
    words =  [r.get('word1') for r in res] if res else []
    random.shuffle(words)
    return words[:10]


async def  get_user_words(user_id: int, lang: str):
    sql = """
    select word1 as word, sum(score) as score, max(created_at) as last_practiced
    from user_data.results 
    where user_id = %s and lang = %s
    group by 1
    order by last_practiced desc
    """
    
    params = (str(user_id), lang)
    res = await get_query_results(sql, params)
    words = [Word(**r) for r in res ] if res else []
    return words



async def  get_exercises_for_practice(user_id: int, lang: str):
    sql = """
    select exercise_id, sum(score) as sum_score from user_data.results 
    where user_id = %s and lang = %s
    group by 1
    having sum(score) < 3
    """
    params = (str(user_id), lang)
    res = await get_query_results(sql, params)
    exercises =  [r.get('exercise_id') for r in res] if res else []
    random.shuffle(exercises)
    return exercises[:10]

async def get_exercises_by_words(lang:str,words: list[str]):
    placehoslder = ', '.join(['%s'] * len(words))
    sql = f"""
    SELECT *  
    FROM course_simple.exercise
    WHERE( 
    word1 IN ({placehoslder}) or word2 IN ({placehoslder}) )
    """
    params = (*words, *words)
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
    WHERE sentence_id IN ({placehoslder})
    """
    res = await get_query_results(sql, sentences)
    results = []
    for r in res:
        exercise = Exercise(**r)
        results.append(exercise)
    random.shuffle(results)
    return results[:10]

async def get_exercises_by_exercises(lang:str,exercises: list[int]):
    placehoslder = ', '.join(['%s'] * len(exercises))
    sql = f"""
    SELECT *  
    FROM course_simple.exercise
    WHERE exercise_id IN ({placehoslder})
    """
    res = await get_query_results(sql, exercises)
    results = []
    for r in res:
        exercise = Exercise(**r)
        results.append(exercise)
    random.shuffle(results)
    return results[:10]


@router.get("/by_words", response_model=list[Exercise])
async def exercise_by_words(user_id: int, lang: str):
    words = await get_words_for_practice(user_id, lang)
    exercises = await get_exercises_by_words(lang, words)
    return exercises
    
@router.get("/words", response_model=list[Word])
async def exercise_by_words(user_id: int, lang: str):
    return await get_user_words(user_id, lang)


@router.get("/by_sentences", response_model=list[Exercise])
async def exercise_by_sentences(user_id: int, lang: str):
    sentences = await get_sentences_for_practice(user_id, lang)
    exercises = await get_exercises_by_sentences(lang, sentences)
    return exercises



@router.get("/by_exercises", response_model=list[Exercise])
async def exercise_by_exercises(user_id: int, lang: str):
    exercises = await get_exercises_for_practice(user_id, lang)
    exercises = await get_exercises_by_exercises(lang, exercises)
    return exercises

