from email import utils

from fastapi import APIRouter, Depends
from models.user_data import Results
from utils.db import run_query
router = APIRouter()


def calculate_mark(correct_ratio: float, incorrect_count: float) -> float:
    """mark = correct_ratio minus a 0.25 penalty per wrong pick,
    clamped to [0, 1]."""
    mark = correct_ratio - 0.25 * incorrect_count
    return max(0.0, min(1.0, mark))


@router.post("/")
async def save_results(results: Results):
    mark = calculate_mark(
        results.correct_ratio or 0.0,
        results.incorrect_count or 0.0,
    )
    sql = """
    INSERT INTO user_data.results (
        user_id, course_id, module_id, lesson_id, exercise_id,
        word1, word2, word3, sentence_id,
        attempts,  mark, lang
    ) VALUES (%s, %s, %s, %s,  %s, %s, %s, %s, %s, %s, %s, %s)
    """
    params = (
        results.user_id,
        results.course_id,
        results.module_id,
        results.lesson_id,
        results.exercise_id,
        results.word1,
        results.word2,
        results.word3,
        results.sentence_id,
        results.attempts,
        mark,
        results.lang,
     )
    print(params)
    print(results)
    await run_query(sql, params)
    return {"message": "Results saved successfully", "mark": mark}
