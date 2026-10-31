from utils.db import get_query_results, run_query
from models.sentence import Sentence
from models.word import (Word, WordTranslationList, WordTranslation)


async def course_words(course_id:int, module_id:int|None = None) -> list[Word]: 
    # One row per word; a word repeated in the table counts as used when any copy is,
    # and keeps the translation it was first saved with.
    query = """
    SELECT word AS text, bool_or(COALESCE(used, false)) AS used,
        COALESCE((array_agg(translation ORDER BY word_id))[1], '') AS translation
    FROM course.words
    WHERE course_id = %(course_id)s AND deleted IS NOT TRUE
    """
    params = {"course_id": course_id}
    if module_id is not None:
        query += " AND module_id = %(module_id)s"
        params["module_id"] = module_id
    query += " GROUP BY word ORDER BY min(weight), min(word_id)"
    results = await get_query_results(query, params)
    return [Word(**row) for row in results]

async def save_words(lang:str, to_lang:str, course_id:int, module_id:int|None = 0, words: list[WordTranslation] = []):
    
    # Removed words count as known, so they are not suggested again.
    rows = await get_query_results("SELECT DISTINCT word FROM course.words WHERE course_id = %s", (course_id,))
    known_words = {row["word"] for row in rows}
    # insert only new words 
    query = """
    INSERT INTO course.words (course_id, module_id,lang, to_lang, word, translation)
    VALUES (%s,%s,%s,%s,%s,%s)
    """
    for word_translation in words:
        if word_translation.word in known_words:
            continue
        known_words.add(word_translation.word)
        params = (course_id, module_id,
                  lang, to_lang,
                  word_translation.word,
                  word_translation.translation)
        await run_query(query, params)



async def move_unused_words(from_module_id: int, to_module_id: int) -> int:
    """Moves the words no exercise uses yet to another module; returns how many words moved."""
    query = """
    UPDATE course.words SET module_id = %s
    WHERE module_id = %s AND deleted IS NOT TRUE
      AND word NOT IN (SELECT word FROM course.words WHERE module_id = %s AND used)
    RETURNING word
    """
    rows = await get_query_results(query, (to_module_id, from_module_id, from_module_id))
    return len({row["word"] for row in rows})


async def update_word(course_id: int, module_id: int, text: str, translation: str | None = None,
                      deleted: bool = False) -> int:
    """Changes a module word's translation, or removes it; returns how many rows changed."""
    query = """
    UPDATE course.words SET translation = COALESCE(%s, translation), deleted = %s
    WHERE course_id = %s AND module_id = %s AND word = %s AND deleted IS NOT TRUE
    RETURNING word_id
    """
    rows = await get_query_results(query, (translation, deleted, course_id, module_id, text))
    return len(rows)


async def module_sentences(course_id: int, module_id: int) -> list[Sentence]:
    """The module's sentences in part order; used when an exercise in the module asks the sentence."""
    query = """
    SELECT s.sentence_id, s.lesson_id, s.sentence, COALESCE(s.translation, '') AS translation,
        EXISTS (SELECT 1 FROM course.exercise e
                WHERE e.module_id = s.module_id AND e.question = s.sentence) AS used
    FROM course.sentences s
    LEFT JOIN course.lesson l ON l.lesson_id = s.lesson_id
    WHERE s.course_id = %s AND s.module_id = %s
    ORDER BY l.weight NULLS LAST, s.lesson_id, s.sentence_id
    """
    rows = await get_query_results(query, (course_id, module_id))
    return [Sentence(**row) for row in rows]
