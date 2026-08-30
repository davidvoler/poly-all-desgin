from utils.db_content import get_query_results


async def get_corpus_words(lang: str, to_lang: str, words_so_far: list, level: str, model: str, max_words: int) -> list:
    """Get full course words 
    """
    skip  = 0
    min_rank = 350
    max_rank = 800
    if level in("beginner", "a1"):
        skip = 0
        min_rank = 350
        max_rank = 700
    elif level in("intermediate", "a2"):
        skip = 50
        min_rank = 350
        max_rank = 720
    elif level in("upper-intermediate", "b1"):
        skip = 100
        min_rank = 360
        max_rank = 730
    elif level in("advanced", "b2"):
        skip = 150
        min_rank = 370
        max_rank = 740  
    elif level in("proficient", "c1"):
        skip = 250
        min_rank = 380
        max_rank = 750
    elif level in("master", "c2"):
        skip = 350
        min_rank = 390
        max_rank = 780
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
    
    LIMIT %s OFFSET %s;
    """
    res =  await get_query_results(query, (lang,max_rank,min_rank,max_words,skip))
    words = [r.get("word") for r in res if r.get("word") !='']
    if len(words_so_far) > 0:
        words = [w for w in words if w not in words_so_far]
    return words[:max_words]


async def get_corpus_sentences(lang: str, to_lang: str, word: str, level: str, model: str, max_words: int, num_sentences: int) -> list:
    sql = f"""
    select lang.text as sentences, sentences.text as translation,
    sentences.options as distractors,
    lang.word1 as word1, lang.word2 as word2, lang.word3 as word3
    from content_raw.sentence_elements_simple2 lang
    join  content_raw.translation_links  trans
    on trans.id = lang.id and trans.lang = %s and trans.to_lang = %s
    join content_raw.sentences sentences
    on sentences.id = trans.to_id
    where sentences.lang = %s 
    and (lang.word1 = %s or lang.word2 = %s or lang.word3 = %s)
    order by len_c
    limit %s
    """
    # print(sql)
    params = (lang, to_lang, to_lang, word, word, word, num_sentences)
    # print(params)
    return await get_query_results(sql, params)

async def get_corpus_sentences_distractors(lang: str, to_lang: str, word: str, level: str, model: str, max_words: int, num_sentences: int) -> list:
    sql = f"""
        select lang.text as {lang}, sentences.text as {to_lang},
        sentences.options as distractors,
        lang.word1 as word1, lang.word2 as word2, lang.word3 as word3
        from content_raw.sentence_elements_simple2 lang
        join  content_raw.translation_links  trans
        on trans.id = lang.id and trans.lang = %s and trans.to_lang = %s
        join content_raw.sentences sentences
        on sentences.id = trans.to_id
        where sentences.lang = %s 
        and (lang.word1 = %s or lang.word2 = %s or lang.word3 = %s)
        order by len_c
        limit %s
        """
    params = (lang, to_lang, to_lang, word, word, word, num_sentences)
    return await get_query_results(sql, params)