from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from models.sentence import Sentence
from models.word import Word, WordTranslation
from utils.course_utils import get_course
from utils.exercise_utils import strip_diacritics
from utils.permission import SchoolUser, get_school_user, require_access
from utils.words_utils import add_words, course_words, module_sentences, update_word

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


class WordsAdd(BaseModel):
    course_id: int
    module_id: int
    words: list[WordTranslation]


class WordsAdded(BaseModel):
    words: list[Word]  # the module's words after the add
    skipped: list[str]  # words the course already had


@router.post("/words", response_model=WordsAdded)
async def _add_words(add: WordsAdd, user: SchoolUser = Depends(get_school_user)) -> WordsAdded:
    """Adds words an author typed to a module."""
    await require_access(user, course_id=add.course_id, module_id=add.module_id)
    # Saved without diacritics, like the words the AI suggests.
    words: list[WordTranslation] = []
    seen: set[str] = set()
    for w in add.words:
        text = (strip_diacritics(w.word) or "").strip()
        if text and text not in seen:
            seen.add(text)
            words.append(WordTranslation(word=text, translation=(strip_diacritics(w.translation) or "").strip()))
    if not words:
        raise HTTPException(status_code=400, detail="No words to add.")
    course = await get_course(add.course_id)
    skipped = await add_words(course.lang, course.to_lang, add.course_id, add.module_id, words)
    return WordsAdded(words=await course_words(add.course_id, add.module_id), skipped=skipped)


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
