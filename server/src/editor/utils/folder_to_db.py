from utils.db import get_query_results, run_query
from editor.utils.parse_course import parse_course
import yaml
import os
import asyncio
import json

async def create_course(course_name: str, lang: str, to_lang: str):
    sql = """
    INSERT INTO course_simple.course (title, lang, to_lang) 
    VALUES (%s, %s, %s)
    RETURNING course_id
    """
    params = (course_name, lang, to_lang)
    res = await get_query_results(sql, params)
    if len(res) > 0:
        return res[0].get('course_id')
    return None




    

async def load_exercise(course_id: int, module_id: int, lesson_id: int, exercise: dict):
    text = exercise.get('text')
    options = exercise.get('options', [])
    word1 = exercise.get('word1')
    word2 = exercise.get('word2')
    word3 = exercise.get('word3')
    text_alt1 = exercise.get('text_alt1')
    text_alt2 = exercise.get('text_alt2')
    text_alt3 = exercise.get('text_alt3')
    exercise_type = exercise.get('type')
    sql = """
    INSERT INTO course_simple.exercise (course_id, module_id, lesson_id, sentence, word1, word2, word3, sentence_alt1, sentence_alt2, sentence_alt3, exercise_type) 
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) 
    RETURNING exercise_id
    """
    params = (course_id, module_id, lesson_id, text, word1, word2, word3, text_alt1, text_alt2, text_alt3, exercise_type)
    res = await get_query_results(sql, params)
    if len(res) > 0:
        return res[0].get('exercise_id')
    return None


async def load_lesson(course_id: int, module_id: int, lesson: dict):
    lesson_title  = lesson.get('title')
    lesson_weight = lesson.get('weight', 0)
    words = lesson.get('words', [])
    sql = """
    INSERT INTO course_simple.lesson (course_id, module_id, title,  words) 
    VALUES (%s, %s, %s, %s) 
    RETURNING lesson_id
    """
    params = (course_id, module_id, lesson_title, words)
    res = await get_query_results(sql, params)
    if len(res) > 0:
        lesson_id = res[0].get('lesson_id')
        exercises = lesson.get('exercises', [])
        for ex in exercises:
            await load_exercise(course_id, module_id, lesson_id, ex)
        return lesson_id
    return None

async def load_module(course_id: int, module: dict, module_no: int):
    title = module.get('title', f"Module {module_no}") 
    sql = """
    INSERT INTO course_simple.module (course_id, weight, title) 
    VALUES (%s, %s, %s) 
    RETURNING module_id
    """
    params = (course_id,  module_no, title)
    res = await get_query_results(sql, params)
    if len(res) > 0:
        module_id = res[0].get('module_id')
        lessons = module.get('lessons', [])
        for l in lessons:
            await load_lesson(course_id, module_id, l)


async def load_course(course_data: dict):
    course_title = course_data.get('title')
    lang = course_data.get('lang')
    to_lang = course_data.get('to_lang')
    course_id = await create_course(course_title, lang, to_lang)
    modules = course_data.get('modules', [])
    i = 1
    for m in modules:
        await load_module(course_id, m, i)
        i += 1
