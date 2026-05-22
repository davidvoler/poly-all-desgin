from fastapi import APIRouter, Depends
from models.course import Lesson, LessonCompleted
from utils.db import get_query_results, run_query
from routers.course import user_course_status
router = APIRouter()


@router.get("/", response_model=list[Lesson])
async def get_lessons(module_id: int):
    sql = """
    SELECT *  
    FROM course_simple.lesson
    WHERE module_id = %s
    """
    params = (module_id,)
    res = await get_query_results(sql, params)
    results = []
    for r in res:
        lesson = Lesson(**r)
        results.append(lesson)
    return results



@router.post("/completed")
async def lesson_completed(lesson_completed: LessonCompleted):
    """Handle lesson completion."""
    """TODO:
    - [v] set lesson as completed correct >= X 
    - [w] set course progress % (or calculated by lesson)
    - [] set current lesson to next lesson - if it is not done already
    - [] check for achievements 
    """

    sql = """
    INSERT INTO user_data.lesson_completed (
        user_id, course_id, module_id, lesson_id, lang, score, skipped_count, correct_count, incorrect_count, course_lessons_count
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    params = (
        lesson_completed.user_id,
        lesson_completed.course_id,
        lesson_completed.module_id,
        lesson_completed.lesson_id,
        lesson_completed.lang,
        lesson_completed.score,
        lesson_completed.skipped_count,
        lesson_completed.correct_count,
        lesson_completed.wrong_count,
        lesson_completed.course_lessons_count
    )
    await run_query(sql, params)

    print(lesson_completed)
    return {"message": "Lesson completion recorded successfully"}