from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from models.sentence import Sentence
from models.word import Word
from utils.words_utils import course_words, module_sentences, update_word

router = APIRouter()

@router.get("/sentences", response_model=list[Sentence])
async def _get_sentences(course_id: int, module_id: int) -> list[Sentence]:
    """The module's sentences, such as those extracted from video parts."""
    return await module_sentences(course_id, module_id)


@router.get("/words", response_model=list[Word])
async def _get_words(course_id: int, module_id: int | None = None) -> list[Word]:
    """The course's words, or the module's when module_id is given."""
    return await course_words(course_id, module_id)


class WordUpdate(BaseModel):
    course_id: int
    module_id: int
    text: str
    translation: str | None = None
    deleted: bool = False


@router.put("/word", response_model=Word | None)
async def _update_word(update: WordUpdate) -> Word | None:
    """Edits a module word's translation, or removes the word when deleted is true."""
    changed = await update_word(update.course_id, update.module_id, update.text,
                                update.translation, update.deleted)
    if not changed:
        raise HTTPException(status_code=404, detail="Word not found in this module.")
    if update.deleted:
        return None
    words = await course_words(update.course_id, update.module_id)
    return next((w for w in words if w.text == update.text), None)
