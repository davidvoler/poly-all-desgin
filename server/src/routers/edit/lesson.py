import json

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from utils.auth_deps import current_ai_school_user, current_school_user, current_school_user_full
from utils.ai_course_ownership import assert_lesson_owned
from utils.db import get_query_results, run_query
from utils.jsonb import coerce_json_list
from models.auth import SchoolUser
from models.edit.lesson import (
    LessonEdit,
    LessonWordsRequest,
    LessonSentence,
    SentencesConfirmRequest,
    SentenceUpdateRequest,
    SentenceDeleteRequest,
)

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


# --- Create-with-AI copilot additions (see TASKS.md "Planning the api") --
# All POST, ids in the body — no path parameters. Gated on the
# create_with_ai permission, not just "signed in", since these are part
# of the AI copilot flow specifically.

@router.post("/words")
async def set_lesson_words(
    request: LessonWordsRequest,
    school_user: SchoolUser = Depends(current_ai_school_user),
):
    """Confirm which words (from the course word bank) are selected for a
    lesson — replaces the lesson's whole `words` list."""
    await assert_lesson_owned(request.lesson_id, school_user)
    await run_query(
        "UPDATE course_simple.lesson SET words = %s WHERE lesson_id = %s",
        (request.words, request.lesson_id),
    )
    return {"lesson_id": request.lesson_id, "words": request.words}


async def _lesson_sentences(lesson_id: int) -> list[dict]:
    """course_simple.lesson.sentences — an ordered jsonb list, not a link
    table. Each entry's `sentence_id` is a content hash (see
    utils.ai_course_content.sentence_id_for); nothing enforces it as a
    foreign key, it's just how the client addresses one entry in the
    list, same shape as course_simple.sentence rows."""
    rows = await get_query_results("SELECT sentences FROM course_simple.lesson WHERE lesson_id = %s", (lesson_id,))
    return coerce_json_list(rows[0].get("sentences")) if rows else []


async def _save_lesson_sentences(lesson_id: int, sentences: list[dict]) -> None:
    await run_query(
        "UPDATE course_simple.lesson SET sentences = %s WHERE lesson_id = %s",
        (json.dumps(sentences), lesson_id),
    )


@router.post("/sentences/confirm")
async def confirm_sentences(
    request: SentencesConfirmRequest,
    school_user: SchoolUser = Depends(current_ai_school_user),
):
    """Choose which generated draft sentences to keep for a lesson — the
    rest stay on the lesson but won't be turned into exercises."""
    await assert_lesson_owned(request.lesson_id, school_user)
    sentences = await _lesson_sentences(request.lesson_id)
    chosen_ids = set(request.sentence_ids)
    for s in sentences:
        s["chosen"] = s["sentence_id"] in chosen_ids
    await _save_lesson_sentences(request.lesson_id, sentences)
    return [LessonSentence(lesson_id=request.lesson_id, **s) for s in sentences]


@router.post("/sentences/update")
async def update_sentence(
    request: SentenceUpdateRequest,
    school_user: SchoolUser = Depends(current_ai_school_user),
):
    """The exercise creator may want to change a sentence's text directly
    — this only touches the lesson's own draft copy, not any exercise
    already built from it (no link to follow either way)."""
    await assert_lesson_owned(request.lesson_id, school_user)
    sentences = await _lesson_sentences(request.lesson_id)
    match = next((s for s in sentences if s["sentence_id"] == request.sentence_id), None)
    if match is None:
        raise HTTPException(status_code=404, detail="Sentence not found")
    match["text"] = request.text
    await _save_lesson_sentences(request.lesson_id, sentences)
    return LessonSentence(lesson_id=request.lesson_id, **match)


@router.post("/sentences/delete")
async def delete_sentence(
    request: SentenceDeleteRequest,
    school_user: SchoolUser = Depends(current_ai_school_user),
):
    await assert_lesson_owned(request.lesson_id, school_user)
    sentences = await _lesson_sentences(request.lesson_id)
    remaining = [s for s in sentences if s["sentence_id"] != request.sentence_id]
    if len(remaining) == len(sentences):
        raise HTTPException(status_code=404, detail="Sentence not found")
    await _save_lesson_sentences(request.lesson_id, remaining)
    return {"success": True}

