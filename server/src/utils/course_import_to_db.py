from utils.db import get_query_results, get_query_results
from utils.course_import import course_from_file 
import json

async def _insert_exercise(exercise: dict, course_id: int, module_id: int, lesson_id: int):
    sql = """
        INSERT INTO course_simple.exercise 
        (course_id, 
        module_id, 
        lesson_id,
        sentence, 
        exercise_type, 
        options, 
        audio, 
        word1, 
        word2, 
        word3,
        sentence_alt1, 
        sentence_alt2, 
        sentence_alt3, 
        ruby_text, 
        annotations,
        weight)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) 
        RETURNING exercise_id
    """
    values = (course_id, 
              module_id, 
              lesson_id, 
              exercise.get('exercise_type'), 
              exercise.get('sentence'), 
              json.dumps(exercise.get('options', [])), 
              exercise.get('audio'), 
              exercise.get('word1'), 
              exercise.get('word2'), 
              exercise.get('word3'), 
              exercise.get('sentence_alt1', ''), 
              exercise.get('sentence_alt2', ''), 
              exercise.get('sentence_alt3', ''), 
              json.dumps(exercise.get('ruby_text', [])), 
              json.dumps(exercise.get('annotations', [])), 
              exercise.get('weight', 11))
    result = await get_query_results(sql, values)
    return result[0]['exercise_id'] if result else None

async def _insert_lesson(lesson: dict, course_id:int, module_id: int):
    sql = """
        INSERT INTO course_simple.lesson (course_id, module_id, title, description, weight)
        VALUES (%s, %s, %s, %s, %s) 
        RETURNING lesson_id
    """
    values = (course_id, module_id, lesson.get('title'), lesson.get('description'), lesson.get('weight'))
    result = await get_query_results(sql, values)
    if not result or len(result) == 0:
        return False
    lesson_id = result[0]['lesson_id']
    for exercise in lesson.get('exercises', []):
        await _insert_exercise(exercise,course_id, module_id, lesson_id)


async def _insert_module(module: dict, course_id: int):
    sql = """
        INSERT INTO course_simple.module (course_id, title, description, weight)
        VALUES (%s, %s, %s, %s) 
        RETURNING module_id
    """
    values = (course_id, module.get('title'), module.get('description'), module.get('weight'))
    result = await get_query_results(sql, values)
    if not result or len(result) == 0:
        return False
    module_id = result[0]['module_id']
    for lesson in module.get('lessons', []):
        await _insert_lesson(lesson, course_id, module_id)
        


async def _insert_course(course: dict, users_id: int, school_id: int):
    sql = """
        INSERT INTO course_simple.course (title, description, lang, to_lang, user_id, school_id,
        level, metadata 
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s) 
        RETURNING course_id
    """
    values = (course.get('title'), 
              course.get('description'), 
              course.get('lang'), 
              course.get('to_lang'), 
              users_id, school_id, 
              course.get('level'), 
              json.dumps(course.get('metadata', {})))
    result = await get_query_results(sql, values)
    if not result or len(result) == 0:
        return False
    course_id =  result[0]['course_id']
    for m in course.get('modules', []):
        module_id = await _insert_module(m, course_id)



async def course_to_db(file_path:str, users_id: int, school_id: int):
    course = course_from_file(file_path)
    await _insert_course(course, users_id, school_id)
    