from fastapi import APIRouter, Depends
from models.user_data import Results
from utils.auth_deps import current_user_id
from utils.db import run_query
router = APIRouter()


def calculate_score(correct_ratio: float, incorrect_count: float, attempts: int) -> float:
    """Calculate a score for an exercise attempt based on the correct ratio, incorrect count, and number of attempts."""
    print(correct_ratio, incorrect_count, attempts)
    if correct_ratio == 1 and incorrect_count == 0:
        if attempts == 1:
            return 1.0
        else:
            return 0.9
    else:
        if correct_ratio == 0:
            return -1.0
        return max(-1.0, (correct_ratio + 0.2 * incorrect_count)*-1)


@router.post("/")
async def save_results(results: Results,
                       user_id: int = Depends(current_user_id)):
    results.user_id = user_id
    score = calculate_score(
        results.correct_ratio or 0.0,
        results.incorrect_count or 0.0,
        results.attempts or 0,
    )
    try:
        answer_delay_ms = int(results.answer_delay_ms or 0)
    except (TypeError, ValueError):
        answer_delay_ms = 0
    sql = """
    INSERT INTO user_data.results (
        user_id, course_id, module_id, lesson_id, exercise_id,
        word1, word2, word3, sentence_id,
        answer_delay_ms, attempts,  score, lang
    ) VALUES (%s, %s, %s, %s,  %s, %s, %s, %s, %s, %s, %s, %s, %s)
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
        answer_delay_ms,
        results.attempts,
        score,
        results.lang,
     )
    await run_query(sql, params)
    return {"message": "Results saved successfully", "score": score}
