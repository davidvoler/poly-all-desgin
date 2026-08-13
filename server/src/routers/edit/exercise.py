import json

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from utils.auth_deps import current_ai_school_user, current_school_user, current_school_user_full
from utils.ai_course_ownership import assert_lesson_owned
from utils.db import get_query_results, run_query
from models.auth import SchoolUser
from models.edit.ai_course import ExerciseOut, exercise_from_row
from models.edit.exercise import ExerciseEdit, ExerciseUpdateRequest, ExerciseDeleteRequest

router = APIRouter()

@router.post("/exercise")
async def edit_exercise(
    exercise: ExerciseEdit,
    school_user: SchoolUser = Depends(current_school_user_full)
):
    # Check if the user has permission to edit the exercise
    sql = f""" 
       INSERT INTO course_simple.exercise 
       (course_id, module_id, lesson_id, exercise_type, sentence, options, word1, word2, word3, sentence_alt1, sentence_alt2, sentence_alt3, ruby_text, annotations, weight)
         VALUES(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
         returning exercise_id
    """
    params = (
        exercise.course_id,
        exercise.module_id,
        exercise.lesson_id,
        exercise.exercise_type,
        exercise.sentence,
        exercise.options,
        exercise.word1,
        exercise.word2,
        exercise.word3,
        exercise.sentence_alt1,
        exercise.sentence_alt2,
        exercise.sentence_alt3,
        exercise.ruby_text,
        exercise.annotations,
        exercise.weight
    )
    try:
        data = await get_query_results(sql, params)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    try:
        exercise_id = data[0]['exercise_id']
        exercise.exercise_id = exercise_id
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to retrieve exercise_id from the database response.")

    return exercise


@router.get("/exercises/{course_id}/{module_id}/{lesson_id}")
async def get_exercises(
    course_id: int,
    module_id: int,
    lesson_id: int,
    school_user: SchoolUser = Depends(current_school_user_full)
):
    sql = """
        SELECT * FROM course_simple.exercise
        WHERE course_id = %s AND module_id = %s AND lesson_id = %s
    """
    params = (course_id, module_id, lesson_id)
    try:
        data = await get_query_results(sql, params)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return data

@router.put("/exercise")
async def update_exercise(
    exercise: ExerciseEdit,
    school_user: SchoolUser = Depends(current_school_user_full)):
    sql = """
        UPDATE course_simple.exercise
        SET exercise_type = %s, sentence = %s, options = %s, word1 = %s, word2 = %s, word3 = %s,
            sentence_alt1 = %s, sentence_alt2 = %s, sentence_alt3 = %s, ruby_text = %s, annotations = %s, weight = %s
        WHERE course_id = %s AND module_id = %s AND lesson_id = %s AND exercise_id = %s
    """
    params = (
        exercise.exercise_type,
        exercise.sentence,
        exercise.options,
        exercise.word1,
        exercise.word2,
        exercise.word3,
        exercise.sentence_alt1,
        exercise.sentence_alt2,
        exercise.sentence_alt3,
        exercise.ruby_text,
        exercise.annotations,
        exercise.weight,
        exercise.course_id,
        exercise.module_id,
        exercise.lesson_id,
        exercise.exercise_id
    )
    try:
        await get_query_results(sql, params)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return {"message": "Exercise updated successfully."}


@router.delete("/exercise/{course_id}/{module_id}/{lesson_id}/{exercise_id}")
async def delete_exercise(
    course_id: int,
    module_id: int,
    lesson_id: int,
    exercise_id: int,
    school_user: SchoolUser = Depends(current_school_user_full)
):
    sql = """
        DELETE FROM course_simple.exercise
        WHERE course_id = %s AND module_id = %s AND lesson_id = %s AND exercise_id = %s
    """
    params = (course_id, module_id, lesson_id, exercise_id)
    try:
        await get_query_results(sql, params)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return {"message": "Exercise deleted successfully."}


# --- Create-with-AI copilot additions (see TASKS.md "Planning the api") --
# All POST, ids in the body — no path parameters. Gated on the
# create_with_ai permission. Focused on just the prompt/options/answer
# fields the copilot's exercise editor touches, rather than the full
# ExerciseEdit shape (ruby_text/annotations/word1-3/sentence_alt1-3).
# Responses use the same ExerciseOut shape (prompt/options/answer) as
# GET .../full, so the Flutter client parses one consistent shape.

async def _assert_exercise_owned(exercise_id: int, school_user: SchoolUser) -> ExerciseOut:
    rows = await get_query_results(
        "SELECT * FROM course_simple.exercise WHERE exercise_id = %s", (exercise_id,)
    )
    if not rows:
        raise HTTPException(status_code=404, detail="Exercise not found")
    await assert_lesson_owned(rows[0]["lesson_id"], school_user)
    return exercise_from_row(rows[0])


@router.post("/exercise/update", response_model=ExerciseOut)
async def update_exercise_post(
    request: ExerciseUpdateRequest,
    school_user: SchoolUser = Depends(current_ai_school_user),
):
    existing = await _assert_exercise_owned(request.exercise_id, school_user)
    sentence = request.prompt if request.prompt is not None else existing.prompt
    options = request.options if request.options is not None else existing.options
    answer = request.answer if request.answer is not None else existing.answer
    await run_query(
        "UPDATE course_simple.exercise SET sentence = %s, options = %s, answer = %s WHERE exercise_id = %s",
        (sentence, json.dumps(options), answer, request.exercise_id),
    )
    rows = await get_query_results(
        "SELECT * FROM course_simple.exercise WHERE exercise_id = %s", (request.exercise_id,)
    )
    return exercise_from_row(rows[0])


@router.post("/exercise/delete")
async def delete_exercise_post(
    request: ExerciseDeleteRequest,
    school_user: SchoolUser = Depends(current_ai_school_user),
):
    await _assert_exercise_owned(request.exercise_id, school_user)
    await run_query("DELETE FROM course_simple.exercise WHERE exercise_id = %s", (request.exercise_id,))
    return {"success": True}
