from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from utils.auth_deps import current_school_user, current_school_user_full
from utils.db import get_query_results
from models.auth import SchoolUser
from models.edit.course import Course, CourseImport
TEMP_FOLDER = "../content/temp"

router = APIRouter()

@router.get("/courses", response_model=list[Course])
async def get_courses(school_user: SchoolUser  = Depends(current_school_user_full)):
    # depending on user permissions we may be able to see more courses
    sql = """SELECT * 
    FROM course_simple.course 
    WHERE user_id = %s and school_id = %s
    ORDER BY last_updated desc"""
    results = await get_query_results(sql, (school_user.user_id, school_user.school_id))
    return [Course(**course) for course in results] if results else []

@router.get("/course/{course_id}", response_model=Course)
async def get_course(course_id:int, school_user: SchoolUser  = Depends(current_school_user)):
    #select course with the a list of modules
    sql = "SELECT * FROM course_simple.course WHERE course_id = %s and user_id = %s and school_id = %s"
    results = await get_query_results(sql, (course_id, school_user.user_id, school_user.school_id))
    return Course(**results[0]) if results else None

@router.post("/course", response_model=Course)
async def create_course(course: Course, school_user: SchoolUser  = Depends(current_school_user)):
    #insert a new course
    sql = """UPDATE course_simple.course 
    SET title = %s, description = %s, lang = %s, to_lang = %s, tags = %s, metadata = %s, user_id = %s, school_id = %s
    WHERE course_id = %s
    AND user_id = %s AND school_id = %s
    """
    values = (course.title, course.description, course.lang, 
              course.to_lang, course.tags, course.metadata, 
              school_user.user_id, school_user.school_id, course.course_id, school_user.user_id, school_user.school_id)
    try:
        results = await get_query_results(sql, values)
    except Exception as e:
        print(f"Error creating course: {e}")
        return None
    return course
    
