import json
import yaml
from utils.db import get_query_results
import asyncio

EXERCISE_FIELDS_TO_REMOVE = ['course_id', 'exercise_id', 'lesson_id','module_id', 'created_at', 'updated_at']
MODULE_FIELDS_TO_REMOVE = ['module_id', 'course_id', 'created_at', 'updated_at']
LESSON_FIELDS_TO_REMOVE = ['lesson_id', 'module_id','course_id', 'created_at', 'updated_at']
COURSE_FIELDS_TO_REMOVE = ['course_id', 'created_at', 'updated_at']

def _remove_fields_and_nulls(data: dict, fields: list):
    for field in fields:
        if field in data:
            del data[field]
    for key in list(data.keys()):
        if data[key] is None:
            del data[key]
    

async def _export_exercise_data(exercise: dict, file):
    _remove_fields_and_nulls(exercise, EXERCISE_FIELDS_TO_REMOVE)
    exercise_yaml = yaml.dump(exercise, default_flow_style=False, sort_keys=False, allow_unicode=True)
    file.write("type: exercise\n")
    file.write(exercise_yaml)
    file.write("---\n")

async def _export_lesson_data(lesson: dict, file):
    lesson_id = lesson.get('lesson_id')
    _remove_fields_and_nulls(lesson, LESSON_FIELDS_TO_REMOVE)
    lesson_yaml = yaml.dump(lesson, default_flow_style=False, sort_keys=False, allow_unicode=True)
    file.write("type: lesson\n")
    file.write(lesson_yaml)
    file.write("---\n")
    sql = "SELECT * FROM course_simple.exercise WHERE lesson_id = %s order by weight"
    exercises = await get_query_results(sql, (lesson_id,))
    print(f"Found {len(exercises)} exercises for lesson ID {lesson_id}")
    for exercise in exercises:
        await _export_exercise_data(exercise, file)


async def _export_module_data(module: dict, file):
    module_id = module.get('module_id')
    _remove_fields_and_nulls(module, MODULE_FIELDS_TO_REMOVE)
    module_yaml = yaml.dump(module, default_flow_style=False, sort_keys=False, allow_unicode=True) 
    file.write("type: module\n")
    file.write(module_yaml)
    file.write("---\n")
    sql = "SELECT * FROM course_simple.lesson WHERE module_id = %s order by weight"
    lessons = await get_query_results(sql, (module_id,))
    print(f"Found {len(lessons)} lessons for module ID {module_id}")
    for lesson in lessons:
        await _export_lesson_data(lesson, file)
async def _export_course_data(course: dict, file):
    course_id = course.get('course_id')
    _remove_fields_and_nulls(course, COURSE_FIELDS_TO_REMOVE)
    course_yaml = yaml.dump(course, default_flow_style=False, sort_keys=False, allow_unicode=True)
    file.write("type: course\n")
    file.write(course_yaml)
    file.write("---\n")
    sql = "SELECT * FROM course_simple.module WHERE course_id = %s order by weight"
    modules = await get_query_results(sql, (course_id,))
    print(f"Found {len(modules)} modules for course ID {course_id}")
    for module in modules:
        print(f"Exporting module: {module}")
        await _export_module_data(module, file)
    

async def export_course_from_db(course_id: int, target_file: str):
    # Fetch course data from the database
    sql = "SELECT * FROM course_simple.course WHERE course_id = %s"
    course_data = await get_query_results(sql, (course_id,))
    
    if not course_data:
        print(f"No course found with ID {course_id}")
        return
    course = course_data[0]  # Assuming the first result is the desired course
    with open(target_file, 'w') as file:
        await _export_course_data(course, file)
    
