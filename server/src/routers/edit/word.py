import json

from fastapi import APIRouter, Depends

from models.auth import SchoolUser
from models.edit.ai_course import CourseWord, WordAddRequest, WordRemoveRequest
from utils.ai_course_ownership import assert_course_owned
from utils.auth_deps import current_ai_school_user
from utils.db import get_query_results, run_query
from utils.jsonb import coerce_json_list

router = APIRouter()


async def _course_words(course_id: int) -> list[dict]:
    rows = await get_query_results("SELECT words FROM course_simple.course WHERE course_id = %s", (course_id,))
    return coerce_json_list(rows[0].get("words")) if rows else []


@router.post("/")
async def add_word(request: WordAddRequest, school_user: SchoolUser = Depends(current_ai_school_user)):
    """Add a word to a course's word list manually (the Words tab's "Add
    a word manually" field) — appended to the end of the ordered list.
    Words aren't a database entity, just an ordered jsonb list on the
    course row, so there's no id — the word string is the identity."""
    await assert_course_owned(request.course_id, school_user)
    words = await _course_words(request.course_id)
    if not any(w["word"] == request.word for w in words):
        words.append({"word": request.word, "gloss": request.gloss or "", "example_sentence": "", "example_gloss": ""})
        await run_query(
            "UPDATE course_simple.course SET words = %s WHERE course_id = %s",
            (json.dumps(words), request.course_id),
        )
    return CourseWord(word=request.word, gloss=request.gloss or "", used=False)


@router.post("/delete")
async def delete_word(request: WordRemoveRequest, school_user: SchoolUser = Depends(current_ai_school_user)):
    """Remove a word from the course word list. Doesn't retroactively
    touch any lesson.words array it was already selected into."""
    await assert_course_owned(request.course_id, school_user)
    words = [w for w in await _course_words(request.course_id) if w["word"] != request.word]
    await run_query(
        "UPDATE course_simple.course SET words = %s WHERE course_id = %s",
        (json.dumps(words), request.course_id),
    )
    return {"success": True}
