from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from utils.auth_deps import current_school_user, current_school_user_full
from utils.db import get_query_results
from models.auth import SchoolUser
from models.edit.lesson import LessonEdit

router = APIRouter()

@router.post("/")
async def create_lesson(
    lesson: LessonEdit,
    school_user: SchoolUser = Depends(current_school_user_full)
):
    sql = f""" 
       INSERT INTO course_simple.lesson 
       (course_id, module_id, title, description, words)
         VALUES(%s, %s, %s, %s, %s)
         returning lesson_id
    """
    params = (
        lesson.course_id,
        lesson.module_id,
        lesson.title,
        lesson.description,
        lesson.words
    )
    try:
        data = await get_query_results(sql, params)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    try:
        lesson_id = data[0]['lesson_id']
        lesson.lesson_id = lesson_id
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to retrieve lesson_id from the database response.")

    return lesson

@router.get("/{course_id}/{module_id}")
async def get_lessons(
    course_id: int,
    module_id: int,
    school_user: SchoolUser = Depends(current_school_user_full)
):
    sql = """
        SELECT * FROM course_simple.lesson
        WHERE course_id = %s AND module_id = %s
    """
    params = (course_id, module_id)
    try:
        lessons = await get_query_results(sql, params)
        return lessons
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/{lesson_id}")
async def update_lesson(
    lesson_id: int,
    lesson: LessonEdit,
    school_user: SchoolUser = Depends(current_school_user_full)
):
    sql = """
        UPDATE course_simple.lesson
        SET title = %s, description = %s, words = %s
        WHERE lesson_id = %s
    """
    params = (
        lesson.title,
        lesson.description,
        lesson.words,
        lesson_id
    )
    try:
        await get_query_results(sql, params)
        return {"message": "Lesson updated successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 

@router.delete("/{lesson_id}")
async def delete_lesson(
    lesson_id: int,
    school_user: SchoolUser = Depends(current_school_user_full)
):
    sql = """
        DELETE FROM course_simple.lesson
        WHERE lesson_id = %s
    """
    params = (lesson_id,)
    try:
        await get_query_results(sql, params)
        return {"message": "Lesson deleted successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

