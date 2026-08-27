from utils.db_content import get_query_results


async def get_corpus_words(lang: str, to_lang: str, words_so_far: list, level: str, model: str, max_words: int) -> list:
    """Get full course words 
    """
    skip  = 10
    min_rank = 450
    max_rank = 800
    if level in("beginner", "a1"):
        min_rank = 450
        max_rank = 1000
    elif level in("intermediate", "a2"):
        min_rank = 500
        max_rank = 900
    elif level in("upper-intermediate", "b1"):
        min_rank = 530
        max_rank = 920
    elif level in("advanced", "b2"):
        min_rank = 560
        max_rank = 930  
    query = """
    select word from content_raw.words 
    where lang = %s
    and rank < %s
    and rank > %s
    and 
    (w_count1_3>5 
    or w_count4_5 >4 
    or w_count6_9 >3 
    or w_count10_20 >0)
    order by w_count1_3  desc, w_count4_5 desc, w_count6_9  desc, w_count10_20 desc 
    """
    res =  await get_query_results(query, (lang,max_rank,min_rank))
    words = list(set([r.get("word") for r in res if r.get("word") !='']))
    if len(words_so_far) > 0:
        words = [w for w in words if w not in words_so_far]
    return words[:max_words]


async def get_corpus_sentences(lang: str, to_lang: str, word: str, level: str, model: str, max_words: int, num_sentences: int) -> list:
    query = "SELECT sentence, translation FROM corpus WHERE lang = ? AND to_lang = ? AND word = ? LIMIT ?"
    return await get_query_results(query, (lang, to_lang, word, num_sentences))

async def get_corpus_sentences_distractors(lang: str, to_lang: str, word: str, level: str, model: str, max_words: int, num_sentences: int) -> list:
    query = "SELECT sentence, translation, distractors FROM corpus WHERE lang = ? AND to_lang = ? AND word = ? LIMIT ?"
    return await get_query_results(query, (lang, to_lang, word, num_sentences))

