import os
from utils.db import get_query_results
import asyncio
BASE_DIR = '../data/content/'


def get_export_exercise(exercise:dict):
    ex_type = exercise.get('exercise_type')
    sentence = exercise.get('sentence', '')
    options = exercise.get('options', [])
    ex_text=  f"---{ex_type}\n{sentence}\n"
    for o in options:
        if o.get('correct'):
            ex_text += f"[+] {o.get('text')}\n"
        else:
            ex_text += f"[-] {o.get('text')}\n"
    return ex_text


async def export_lesson(course_id:int, lesson:dict, module_path:str):
    lesson_file_name = lesson.get('title').lower().replace(" ", "_") + ".txt"
    lesson_path = os.path.join(module_path, lesson_file_name)
    sql = """
    SELECT * from course_simple.exercise
    where lesson_id = %s
    order by exercise_id
    """
    params = (lesson.get('lesson_id'),)
    res =  await get_query_results(sql, params)
    lesson_text = ""
    for r in res:
        ex = get_export_exercise(r)
        if ex is not None:
            lesson_text += ex
    with open(lesson_path, 'w') as f:
        f.write(lesson_text)

async def export_module(course_id:int, course_folder_name:str, module:dict):
    module_folder = module.get('title').lower().replace(" ", "_")
    module_path = os.path.join(BASE_DIR, course_folder_name, module_folder)
    os.makedirs(module_path, exist_ok=True)
    sql = """
    SELECT * from course_simple.lesson
    where module_id = %s
    """
    params = (module.get('module_id'),)
    res =  await get_query_results(sql, params)
    for r in res: 
        await export_lesson(course_id, r, module_path)

async def export_simple_format(course_id:int):
    sql = """
    SELECT * from course_simple.course
    where course_id = %s
    """
    res = await  get_query_results(sql, (course_id,))
    course = res[0]
    course_title = course.get('title')
    lang = course.get('lang')
    to_lang = course.get('to_lang')
    course_folder_name = course_title.lower().replace(" ", "_")
    os.makedirs(os.path.join(BASE_DIR, course_folder_name), exist_ok=True)
    sql = """
    SELECT * from course_simple.module
    where course_id = %s
    order by weight
    """
    res = await get_query_results(sql, (course_id,))
    for r in res:
        await export_module(course_id, course_folder_name, r)



if __name__ == '__main__':
    asyncio.run(export_simple_format(3))