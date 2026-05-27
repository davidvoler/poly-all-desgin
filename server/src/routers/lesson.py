from fastapi import APIRouter, Depends
from models.course import Lesson, LessonCompleted
from utils.auth_deps import current_user_id
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
async def lesson_completed(lesson_completed: LessonCompleted,
                           user_id: int = Depends(current_user_id)):
    """Handle lesson completion."""
    lesson_completed.user_id = user_id
    print(lesson_completed)
    sql = """
    INSERT INTO user_data.lesson_status (
        user_id, course_id, module_id, lesson_id, lang, score, skipped_count, correct_count, wrong_count
    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
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
    )
    await run_query(sql, params)

    print(lesson_completed)
    return {"message": "Lesson completion recorded successfully"}