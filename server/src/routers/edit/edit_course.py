import json
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from utils.auth_deps import current_school_user, current_school_user_full
from utils.db import get_query_results
from models.auth import SchoolUser
from models.edit.course import Course, CourseImport
TEMP_FOLDER = "../content/temp"

router = APIRouter()

def _row_to_course(row: dict) -> Course:
    return Course(**{**row, "published": row.get("status") == "published"})

@router.get("/courses", response_model=list[Course])
async def get_courses(school_user: SchoolUser  = Depends(current_school_user_full)):
    # depending on user permissions we may be able to see more courses.
    # user_id is a varchar column (legacy) — cast the param so it can be
    # compared against an int SchoolUser.user_id.
    sql = """SELECT *
    FROM course_simple.course
    WHERE user_id = %s::text and school_id = %s
    ORDER BY updated_at desc"""
    results = await get_query_results(sql, (school_user.user_id, school_user.school_id))
    return [_row_to_course(course) for course in results] if results else []

@router.get("/course/{course_id}", response_model=Course)
async def get_course(course_id:int, school_user: SchoolUser  = Depends(current_school_user)):
    #select course with the a list of modules
    sql = "SELECT * FROM course_simple.course WHERE course_id = %s and user_id = %s::text and school_id = %s"
    results = await get_query_results(sql, (course_id, school_user.user_id, school_user.school_id))
    return _row_to_course(results[0]) if results else None

@router.post("/course", response_model=Course)
async def create_course(course: Course, school_user: SchoolUser  = Depends(current_school_user)):
    #insert a new course
    sql = """UPDATE course_simple.course
    SET title = %s, description = %s, lang = %s, to_lang = %s, metadata = %s, status = %s
    WHERE course_id = %s
    AND user_id = %s::text AND school_id = %s
    """
    values = (course.title, course.description, course.lang,
              course.to_lang, json.dumps(course.metadata),
              "published" if course.published else "draft",
              course.course_id, school_user.user_id, school_user.school_id)
    try:
        results = await get_query_results(sql, values)
    except Exception as e:
        print(f"Error creating course: {e}")
        return None
    return course

@router.delete("/course/{course_id}")
async def delete_course(course_id:int, school_user: SchoolUser  = Depends(current_school_user)):
    #delete a course
    sql = """DELETE FROM course_simple.course
    WHERE course_id = %s and user_id = %s::text and school_id = %s"""
    try:
        results = await get_query_results(sql, (course_id, school_user.user_id, school_user.school_id))
    except Exception as e:
        print(f"Error deleting course: {e}")
        return {"success": False, "message": str(e)}
    return {"success": True, "message": f"Course {course_id} deleted successfully"}
