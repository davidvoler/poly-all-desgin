from utils.db_content import get_query_results

async def get_corpus_words(lang: str, to_lang: str, words_so_far: list, level: str, model: str, max_words: int) -> list:
    query = "SELECT word FROM corpus WHERE lang = ? AND to_lang = ? AND level = ? AND word NOT IN (?) LIMIT ?"
    return await get_query_results(query, (lang, to_lang, level, ','.join(words_so_far), max_words))

async def get_corpus_sentences(lang: str, to_lang: str, word: str, level: str, model: str, max_words: int, num_sentences: int) -> list:
    query = "SELECT sentence, translation FROM corpus WHERE lang = ? AND to_lang = ? AND word = ? LIMIT ?"
    return await get_query_results(query, (lang, to_lang, word, num_sentences))

async def get_corpus_sentences_distractors(lang: str, to_lang: str, word: str, level: str, model: str, max_words: int, num_sentences: int) -> list:
    query = "SELECT sentence, translation, distractors FROM corpus WHERE lang = ? AND to_lang = ? AND word = ? LIMIT ?"
    return await get_query_results(query, (lang, to_lang, word, num_sentences))

