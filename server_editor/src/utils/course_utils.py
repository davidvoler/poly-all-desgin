from utils.db import get_query_results, run_query
from models.course import Course
import json


async def get_courses() -> list[Course]:
    query = """
    SELECT * FROM course.course
    WHERE deleted IS NOT TRUE
    ORDER BY course_id
    """
    result = await get_query_results(query, {})
    if result:
        return [Course(**row) for row in result]
    return []

async def get_course(course_id: int) -> Course:
    query = """
    SELECT * FROM course.course
    WHERE course_id = %(course_id)s
    """
    params = {"course_id": course_id}
    result = await get_query_results(query, params)
    if result:
        return Course(**result[0])
    return Course()

async def update_course(course: Course) -> Course:
    query = """
    UPDATE course.course
    SET lang = %(lang)s,
        to_lang = %(to_lang)s,
        level = %(level)s,
        user_id = %(user_id)s,
        school = %(school)s,
        title = %(title)s,
        description = %(description)s,
        course_options = %(course_options)s,
        status = %(status)s
    WHERE course_id = %(course_id)s
    RETURNING *
    """
    params = {
        "lang": course.lang,
        "to_lang": course.to_lang,
        "level": course.level,
        "user_id": course.user_id,
        "school": course.school,
        "title": course.title,
        "description": course.description or '',
        "course_options": json.dumps(course.course_options or {}),
        "status": course.status,
        "course_id": course.course_id
    }
    result = await get_query_results(query, params)
    if result:
        return Course(**result[0])
    return Course()

async def create_course(course: Course) -> Course:
    """Creates a new course in the database"""
    query = """
    INSERT INTO course.course (lang, to_lang, level, user_id, school, title, description, course_options, status)
    VALUES (%(lang)s, %(to_lang)s, %(level)s, %(user_id)s, %(school)s, %(title)s, %(description)s, %(course_options)s, %(status)s)
    RETURNING *
    """
    params = {
        "lang": course.lang,
        "to_lang": course.to_lang,
        "level": course.level,
        "user_id": course.user_id,
        "school": course.school,
        "title": course.title,
        "description": course.description or '',
        "course_options": json.dumps(course.course_options or {}),
        "status": course.status
    }
    result = await  get_query_results(query, params)
    if result:
        return Course(**result[0])
    return Course()

async def delete_course(course_id: int) -> None:
    query = """
    UPDATE course.course
    SET deleted = true
    WHERE course_id = %(course_id)s
    """
    await run_query(query, {"course_id": course_id})
    