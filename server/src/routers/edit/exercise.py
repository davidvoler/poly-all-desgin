from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from utils.auth_deps import current_school_user, current_school_user_full
from utils.db import get_query_results
from models.auth import SchoolUser
from models.edit.exercise import ExerciseEdit

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

