from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from models.sentence import Sentence
from models.word import Word
from utils.permission import SchoolUser, get_school_user, require_access
from utils.words_utils import course_words, module_sentences, update_word

router = APIRouter()

@router.get("/sentences", response_model=list[Sentence])
async def _get_sentences(course_id: int, module_id: int,
                         user: SchoolUser = Depends(get_school_user)) -> list[Sentence]:
    """The module's sentences, such as those extracted from video parts."""
    await require_access(user, course_id=course_id, module_id=module_id)
    return await module_sentences(course_id, module_id)


@router.get("/words", response_model=list[Word])
async def _get_words(course_id: int, module_id: int | None = None,
                     user: SchoolUser = Depends(get_school_user)) -> list[Word]:
    """The course's words, or the module's when module_id is given."""
    await require_access(user, course_id=course_id, module_id=module_id)
    return await course_words(course_id, module_id)


class WordUpdate(BaseModel):
    course_id: int
    module_id: int
    text: str
    translation: str | None = None
    deleted: bool = False


@router.put("/word", response_model=Word | None)
async def _update_word(update: WordUpdate, user: SchoolUser = Depends(get_school_user)) -> Word | None:
    """Edits a module word's translation, or removes the word when deleted is true."""
    await require_access(user, course_id=update.course_id, module_id=update.module_id)
    changed = await update_word(update.course_id, update.module_id, update.text,
                                update.translation, update.deleted)
    if not changed:
        raise HTTPException(status_code=404, detail="Word not found in this module.")
    if update.deleted:
        return None
    words = await course_words(update.course_id, update.module_id)
    return next((w for w in words if w.text == update.text), None)
