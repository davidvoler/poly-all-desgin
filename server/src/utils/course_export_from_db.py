import json
import yaml
from utils.db import get_query_results
import asyncio



async def _export_exercise_data(exercise: dict, file):
    exercise_yaml = yaml.dump(exercise, default_flow_style=False, sort_keys=False, allow_unicode=True)
    file.write("type: exercise\n")
    file.write(exercise_yaml)
    file.write("---\n")

async def _export_lesson_data(lesson: dict, file):
    lesson_yaml = yaml.dump(lesson, default_flow_style=False, sort_keys=False, allow_unicode=True)
    file.write("type: lesson\n")
    file.write(lesson_yaml)
    file.write("---\n")
    sql = "SELECT * FROM course_simple.exercise WHERE lesson_id = %s"
    exercises = await get_query_results(sql, (lesson.get('lesson_id'),))
    for exercise in exercises:
        await _export_exercise_data(exercise, file)


async def _export_module_data(module: dict, file):
    module_yaml = yaml.dump(module, default_flow_style=False, sort_keys=False, allow_unicode=True) 
    file.write("type: module\n")
    file.write(module_yaml)
    file.write("---\n")
    sql = "SELECT * FROM course_simple.lesson WHERE module_id = %s"
    lessons = await get_query_results(sql, (module.get('module_id'),))
    for lesson in lessons:
        await _export_lesson_data(lesson, file)
async def _export_course_data(course: dict, file):
    course_yaml = yaml.dump(course, default_flow_style=False, sort_keys=False, allow_unicode=True)
    file.write("type: course\n")
    file.write(course_yaml)
    file.write("---\n")
    sql = "SELECT * FROM course_simple.module WHERE course_id = %s"
    modules = await get_query_results(sql, (course.get('course_id'),))
    print(f"Found {len(modules)} modules for course ID {course.get('course_id')}")
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
    
