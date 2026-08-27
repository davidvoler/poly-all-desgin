from utils.db_content import get_query_results


async def get_corpus_words(lang: str, to_lang: str, words_so_far: list, level: str, model: str, max_words: int) -> list:
    """Get full course words 
    """
    query = """
    select word from content_raw.words 
    where lang = %s
    and rank < 1000
    and rank > 450
    and 
    (w_count1_3>5 
    or w_count4_5 >4 
    or w_count6_9 >3 
    or w_count10_20 >0)
    order by w_count1_3  desc, w_count4_5 desc, w_count6_9  desc, w_count10_20 desc 
    """
    return await get_query_results(query, (lang, to_lang, level, ','.join(words_so_far), max_words))

async def get_corpus_sentences(lang: str, to_lang: str, word: str, level: str, model: str, max_words: int, num_sentences: int) -> list:
    query = "SELECT sentence, translation FROM corpus WHERE lang = ? AND to_lang = ? AND word = ? LIMIT ?"
    return await get_query_results(query, (lang, to_lang, word, num_sentences))

async def get_corpus_sentences_distractors(lang: str, to_lang: str, word: str, level: str, model: str, max_words: int, num_sentences: int) -> list:
    query = "SELECT sentence, translation, distractors FROM corpus WHERE lang = ? AND to_lang = ? AND word = ? LIMIT ?"
    return await get_query_results(query, (lang, to_lang, word, num_sentences))

