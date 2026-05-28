from fastapi import APIRouter, Depends
from models.course import Lesson, LessonCompleted
from utils.auth_deps import current_user_id
from utils.db import get_query_results, run_query
from routers.course import user_course_status
router = APIRouter()


@router.get("/", response_model=list[Lesson])
async def get_lessons(module_id: int,
                      user_id: int = Depends(current_user_id)):
    # Join each lesson row against the user's own lesson_status
    # aggregate so the client gets max/sum/attempts alongside the
    # static lesson copy. `completed` is derived from max_score —
    # any positive best-attempt counts as done.
    sql = """
    SELECT lesson.lesson_id, lesson.title, lesson.description, lesson.words,
           COALESCE(ls.max_score, 0.0) AS max_score,
           COALESCE(ls.sum_score, 0.0) AS sum_score,
           COALESCE(ls.num_attempts, 0) AS num_attempts,
           CASE WHEN COALESCE(ls.max_score, 0) > 0 THEN 1 ELSE 0 END AS completed
    FROM course_simple.lesson AS lesson
    LEFT JOIN (
        SELECT lesson_id,
               max(score) AS max_score,
               sum(score) AS sum_score,
               count(*) AS num_attempts
        FROM user_data.lesson_status
        WHERE user_id = %s
        GROUP BY lesson_id
    ) AS ls ON lesson.lesson_id = ls.lesson_id
    LEFT JOIN  ( 
    SELECT module_id, lesson_id as current
    FROM user_data.lesson_status
    WHERE user_id = %s
    ORDER by created_at DESC
    LIMIT 1
    ) AS current_lesson ON lesson.module_id = current_lesson.module_id
    WHERE lesson.module_id = %s
    ORDER BY lesson.lesson_id
    """
    params = (user_id, module_id)
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